component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
        appCache       = getCache("appCache");
        templateCache  = getCache("template");

        // Event caching is off in development, the viewlet cache needs it on
        originalEventCaching = getController().getSetting("eventCaching");
        getController().setSetting("eventCaching", true);

        ses = "1"; // Bulbasaur

        mockTrainer = getInstance("tests.resources.mockTrainer");
        admin       = mockTrainer.make(securityLevel = 50, autoLogin = false);
    }

    function afterAll() {
        mockTrainer.deleteTrainer(admin.id);
        getController().setSetting("eventCaching", originalEventCaching);
        pokemonService.clearAllDetailCaches();
        super.afterAll();
    }

    /**
     * Cached detailContent viewlet keys for the ses + audience
     */
    private array function getViewletKeys(required string audience) {
        return templateCache.getKeys().filter((key) => key.findNoCase("pokemon.detailcontent-#ses#|#audience#-"));
    }

    private any function getDetailPage() {
        setup();
        return get(route = "/pokemon/#ses#");
    }

    /**
     * Just the <main> element - the viewlet renders there. Stats like "128 HP" also appear in the
     * <head> meta description, so body assertions must not search the whole page
     */
    private string function getMainContent(required string html) {
        var start = arguments.html.findNoCase("<main");
        var end   = arguments.html.findNoCase("</main>", start);
        expect(start).toBeGT(0, "page has no <main> element");
        expect(end).toBeGT(0, "page has no closing </main>");
        return arguments.html.mid(start, end - start);
    }

    function run() {
        describe("Pokemon detail page viewlet cache", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAsGuest();
                pokemonService.clearAllDetailCaches();
            });

            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Caches the rendered detail body on first view", () => {
                expect(getViewletKeys("public")).toBeEmpty();

                var event = getDetailPage();
                expect(event.getStatusCode()).toBe(200);
                expect(getMainContent(event.getRenderedContent())).toInclude("128 HP");
                expect(getViewletKeys("public")).toHaveLength(1);
            });

            it("Keeps the cached body until its timeout, not the 30 minute idle default", () => {
                getDetailPage();
                var metadata = templateCache.getCachedObjectMetadata(getViewletKeys("public")[1]);
                expect(metadata.lastAccessTimeout).toBe(metadata.timeout);
            });

            it("Serves the cached body without running the viewlet", () => {
                getDetailPage();
                var keys = getViewletKeys("public");
                expect(keys).toHaveLength(1);

                // Swap the cached html, if the viewlet ran again the real stats would render instead
                templateCache.set(keys[1], "<p>cached-detail-sentinel</p>");

                var html = getDetailPage().getRenderedContent();
                expect(getMainContent(html)).toInclude("cached-detail-sentinel");
                expect(getMainContent(html)).notToInclude("128 HP");
                // Layout still renders around the cached body
                expect(html).toInclude("Bulbasaur");
            });

            it("Caches a separate admin copy containing the update form", () => {
                expect(getDetailPage().getRenderedContent()).notToInclude("pokemonDetailForm");

                mockTrainer.actAs(admin);
                var html = getDetailPage().getRenderedContent();
                expect(html).toInclude("pokemonDetailForm");
                expect(getViewletKeys("admin")).toHaveLength(1);

                // Public copy was not overwritten by the admin render
                mockTrainer.actAsGuest();
                expect(getDetailPage().getRenderedContent()).notToInclude("pokemonDetailForm");
            });

            it("clearAllDetailCaches removes the cached info and rendered pages", () => {
                getDetailPage();
                mockTrainer.actAs(admin);
                getDetailPage();
                expect(getViewletKeys("public")).toHaveLength(1);
                expect(getViewletKeys("admin")).toHaveLength(1);
                expect(appCache.get("pokemon.getDetail|pokemonses=#ses#")).notToBeNull();

                pokemonService.clearAllDetailCaches();

                expect(getViewletKeys("public")).toBeEmpty();
                expect(getViewletKeys("admin")).toBeEmpty();
                expect(appCache.get("pokemon.getDetail|pokemonses=#ses#")).toBeNull();
            });

            it("Returns 404 for an unknown pokemon", () => {
                var event = get(route = "/pokemon/not-a-real-pokemon");
                expect(event.getStatusCode()).toBe(404);
            });
        });

        describe("Pokemon detail data", () => {
            beforeEach(() => {
                setup();
                pokemonService.clearAllDetailCaches();
            });

            it("Cached detail info holds no objects", () => {
                var info = pokemonService.getDetailInfo(ses = ses);
                expect(info).notToBeEmpty();
                info.each((key, value) => {
                    expect(isObject(value)).toBeFalse("detail info key [#key#] is an object");
                });
            });

            it("getDetail returns the moves, evolution chain and costumes when the detail info is cached", () => {
                // Populate the cache, then read the detail again on top of it
                pokemonService.getDetail(ses = ses);

                var detail = pokemonService.getDetail(ses = ses);
                expect(detail.moves.fast).notToBeEmpty();
                detail.moves.fast.each((move) => {
                    expect(move.name).notToBeEmpty();
                });
                expect(detail.moves.charge).notToBeEmpty();
                expect(detail.evolutionChain).notToBeEmpty();
                expect(detail.costumes).notToBeEmpty();
            });

            it("Detail page renders after previous events are loaded first", () => {
                // Loading more events first caches the detail info before the page itself renders
                var eventsResponse = get(route = "/pokemon/getPreviousEvents", params = {ses: ses, offset: 5});
                expect(eventsResponse.getStatusCode()).toBe(200);

                var expectedMove = pokemonService.getMovesByKind(pokemonService.getFromSes(ses = ses), "normal").fast[1].name;

                var event = getDetailPage();
                expect(event.getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toInclude(expectedMove);
                expect(getMainContent(event.getRenderedContent())).toInclude("128 HP");
            });
        });
    }

}
