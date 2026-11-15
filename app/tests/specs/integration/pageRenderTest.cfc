component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        statsService   = getInstance("services.stats");
        medalService   = getInstance("services.medal");
        friendService  = getInstance("services.friend");
        customService  = getInstance("services.custom");
        pokemonService = getInstance("services.pokemon");
        pokedexService = getInstance("services.pokedex");

        // Made first - make() leaves the last trainer made as the session's mock trainer
        requester = mockTrainer.make(autoLogin = false);
        friend    = mockTrainer.make(autoLogin = false);

        // An admin with a tracked stat, a medal at silver, a friend and a friend request waiting,
        // so every page has data to render
        trainer = mockTrainer.make(securityLevel = 50);
        friendService.sendFriendRequest(trainerid = requester.id, friendid = trainer.id);
        friendService.sendFriendRequest(trainerid = trainer.id, friendid = friend.id);
        friendService.sendFriendRequest(trainerid = friend.id, friendid = trainer.id);
        statsService.track(
            trainerid = trainer.id,
            xp        = 123456,
            caught    = 10,
            spun      = 20,
            walked    = 30
        );
        medal = medalService.getAll()[1];
        medalService.trackProgress(
            trainerid = trainer.id,
            medal     = medal,
            current   = medal.silver
        );
        customName = "Render Test Custom #left(createUUID(), 8)#";
        // Unique per run - a leftover from a failed cleanup can't collide on unq_custom_upper_link
        customLink = "https://leekduck.com/events/render-test-#lCase(left(createUUID(), 8))#/";
        customid   = customService.create(
            trainerid = trainer.id,
            name      = customName,
            isPublic  = false,
            begins    = createDate(2025, 3, 4),
            ends      = createDate(2025, 3, 9),
            link      = customLink
        );
        customService.createCustomPokedex(
            custom  = customService.getFromId(customid),
            pokemon = [queryExecute("SELECT MIN(id) AS id FROM pokemon").id]
        );

        // Bulbasaur caught by the trainer but not the friend - the trade plan's one row
        tradePokemon = pokemonService.getFromId(
            queryExecute("SELECT MIN(id) AS id FROM pokemon WHERE number = 1 AND costume = false AND form = false AND mega = false").id
        );
        pokedexService.register(
            trainerid   = trainer.id,
            pokemon     = tradePokemon,
            caught      = true,
            shiny       = false,
            hundo       = false,
            shadow      = false,
            shadowshiny = false
        );

        mockTrainer.refresh(trainer.id);
    }

    function afterAll() {
        mockTrainer.deleteTrainer(trainer.id);
        mockTrainer.deleteTrainer(requester.id);
        mockTrainer.deleteTrainer(friend.id);
        super.afterAll();
    }

    /**
     * Render a page as the logged in trainer and return its html
     */
    private string function renderPage(required string route, struct params = {}) {
        setup();
        mockTrainer.actAs(trainer);
        return get(
            route         = arguments.route,
            params        = arguments.params,
            renderResults = true
        ).getRenderedContent();
    }

    function run() {
        describe("Pages render", () => {
            describe("Stats", () => {
                it("Overview", () => {
                    expect(renderPage("/stats/overview")).toInclude("medalProgressDiv");
                });

                it("Track form, filled from the latest stat", () => {
                    expect(renderPage("/stats/trackForm")).toInclude("data-latest-xp=""123456""");
                });

                it("Pokedex stats", () => {
                    var html = renderPage("/stats/getPokedexStats");
                    expect(html).toInclude("Kanto");
                    expect(html).toInclude("(0 / ");
                });

                it("Medal summary, with the tracked medal's tier", () => {
                    var html = renderPage("/stats/getMedalSummary");
                    expect(html).toInclude(medal.alttext);
                    expect(html).toInclude("silverMedal");
                });

                it("Medal progress, with the tracked value", () => {
                    var html = renderPage("/stats/getMedalProgress");
                    expect(html).toInclude("data-name=""#medal.name#""");
                    expect(html).toInclude("value=""#medal.silver#""");
                });

                it("Top deltas", () => {
                    renderPage("/stats/topDeltas");
                });

                it("Leaderboard", () => {
                    renderPage("/stats/leaderboard");
                });
            });

            describe("Friends", () => {
                it("Friends list, with the accepted friend", () => {
                    var html = renderPage("/friend/getFriendsList");
                    expect(html).toInclude(friend.username);
                    expect(html).toInclude("/profile/#friend.id#");
                    expect(html).toInclude("Accepted");
                });

                it("Friend requests, with the waiting request", () => {
                    var html = renderPage("/friend/getFriendRequests");
                    expect(html).toInclude(requester.username);
                    expect(html).toInclude("data-friendrequestid=");
                });

                it("Friend request toast", () => {
                    expect(renderPage("/friend/getFriendRequestToast")).toInclude(requester.username);
                });

                it("Friend search, finding the friend", () => {
                    var html = renderPage("/friend/searchFriendsList", {page: 1, search: friend.username});
                    expect(html).toInclude(friend.username);
                });

                it("Trainers to add, leaving out the friend", () => {
                    var html = renderPage("/friend/searchFriendsToAdd", {page: 1, search: requester.username});
                    expect(html).toInclude(requester.username);
                    expect(renderPage("/friend/searchFriendsToAdd", {page: 1, search: friend.username})).notToInclude(
                        friend.username
                    );
                });
            });

            describe("Custom pokedex", () => {
                it("List, with the creator and dates", () => {
                    var html = renderPage("/custompokedexlist");
                    expect(html).toInclude(customName);
                    expect(html).toInclude(encodeForHTML(trainer.username));
                    expect(html).toInclude("Mar 4, 2025 - Mar 9, 2025");
                    expect(html).toInclude("data-customid=""#customid#""");
                });

                it("Page, with the event link", () => {
                    var html = renderPage("/mycustompokedex/#customid#");
                    expect(html).toInclude(customName);
                    expect(html).toInclude(customLink);
                });

                it("Edit form, filled with the pokedex", () => {
                    var html = renderPage("/pokedex/editCustomPokedexForm", {customid: customid});
                    expect(html).toInclude("value=""#customid#""");
                    expect(html).toInclude("value=""#customName#""");
                    expect(html).toInclude(" selected");
                });
            });

            describe("Pokedex", () => {
                it("Kanto grid, with the caught pokemon", () => {
                    var html = renderPage(
                        "/pokedex/getPokedex",
                        {
                            trainerid: trainer.id,
                            region   : "Kanto",
                            form     : false,
                            shiny    : false,
                            hundo    : false,
                            shadow   : false,
                            costume  : false
                        }
                    );
                    expect(html).toInclude("data-id=""#tradePokemon.id#""");
                    expect(html).toInclude("data-caught=""true""");
                });

                it("Trade plan, with the pokemon only the trainer has", () => {
                    setup();
                    mockTrainer.actAs(trainer);
                    var response = deserializeJSON(
                        post(route = "/trade/tradePlan", params = {friend: friend.id, region: "Kanto"}).getRenderedContent()
                    );
                    expect(response.success).toBeTrue(response.message ?: "");
                    expect(response.data).toInclude("/sprites/#tradePokemon.sprite#");
                });
            });

            describe("Trainer", () => {
                it("Own profile, with the friend code, icon and level", () => {
                    var saved = getInstance("services.trainer").getFromId(trainer.id);
                    var html  = renderPage("/profile");
                    expect(html).toInclude(encodeForHTML(saved.username));
                    expect(html).toInclude(saved.formattedfriendcode);
                    expect(html).toInclude(saved.iconpath);
                    // The sidebar shows the logged in trainer
                    expect(html).toInclude("id=""sidebarUsername""");
                });

                it("A friend's profile", () => {
                    expect(renderPage("/profile/#friend.id#")).toInclude(encodeForHTML(friend.username));
                });
            });

            describe("Pokemon", () => {
                it("Detail page, with moves, evolutions and whole number move stats", () => {
                    var html = renderPage("/pokemon/#tradePokemon.ses#");
                    expect(html).toInclude(tradePokemon.name);
                    // Bulbasaur evolves into Ivysaur
                    expect(html).toInclude("Ivysaur");
                    var move = getInstance("services.pokemon").getMovesByKind(tradePokemon, "normal").fast[1];
                    expect(html).toInclude(move.name);
                    expect(reFind("[>\s]\d+\.00\s*<", html)).toBe(0, "a move stat rendered with trailing .00");
                });
            });

            describe("Admin", () => {
                it("Move data", () => {
                    var html = renderPage("/admin/showMoveData");
                    expect(html).toInclude(getInstance("services.move").getAllFastMoves()[1].name);
                    expect(reFind(">\s*\d+\.00\s*<", html)).toBe(0, "a move stat rendered with trailing .00");
                });

                it("Medal data", () => {
                    var html = renderPage("/admin/showMedalData");
                    expect(html).toInclude(medal.name);
                    expect(html).toInclude(medal.alttext);
                });
            });
        });
    }

}
