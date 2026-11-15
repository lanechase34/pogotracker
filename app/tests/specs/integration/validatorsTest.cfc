component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer   = getInstance("tests.resources.mockTrainer");
        validation    = getInstance("ValidationManager@cbvalidation");
        friendService = getInstance("services.friend");
        customService = getInstance("services.custom");

        trainerA = mockTrainer.make(autoLogin = false);
        trainerB = mockTrainer.make(autoLogin = false);
        admin    = mockTrainer.make(securityLevel = 50, autoLogin = false);
    }

    function afterAll() {
        mockTrainer.deleteTrainer(admin.id);
        mockTrainer.deleteTrainer(trainerB.id);
        mockTrainer.deleteTrainer(trainerA.id);
        super.afterAll();
    }

    /**
     * True if the field passes the shared constraint as the given trainer (null = guest)
     */
    private boolean function passes(
        required struct target,
        required string constraints,
        required string field,
        any asTrainer
    ) {
        mockTrainer.actAs(arguments?.asTrainer);
        var result = validation.validate(target = arguments.target, constraints = arguments.constraints);
        return result.getFieldErrors(arguments.field).isEmpty();
    }

    function run() {
        describe("securityCheck - your own data, or you're an admin", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Checks the target trainer against the logged in trainer", () => {
                var target = {
                    trainerid: trainerA.id,
                    xp       : 1,
                    caught   : 1,
                    spun     : 1,
                    walked   : 1
                };

                expect(passes(target, "stats.track", "trainerid", trainerA)).toBeTrue("self");
                expect(passes(target, "stats.track", "trainerid", admin)).toBeTrue("admin");
                expect(passes(target, "stats.track", "trainerid", trainerB)).toBeFalse("other trainer");
                expect(passes(target, "stats.track", "trainerid")).toBeFalse("guest");
            });
        });

        describe("entityExists belongsToUser - records you own", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Only passes for the owner of the custom pokedex", () => {
                var target = {
                    customid: customService.create(
                        trainerid = trainerA.id,
                        name      = "Validator test",
                        isPublic  = false
                    )
                };

                expect(
                    passes(
                        target,
                        "pokedex.deleteCustomPokedex",
                        "customid",
                        trainerA
                    )
                ).toBeTrue("owner");
                expect(
                    passes(
                        target,
                        "pokedex.deleteCustomPokedex",
                        "customid",
                        trainerB
                    )
                ).toBeFalse("other trainer");
                expect(
                    passes(
                        target,
                        "pokedex.deleteCustomPokedex",
                        "customid"
                    )
                ).toBeFalse("guest");
            });

            it("Rejects an id that isn't a whole integer instead of querying with it", () => {
                ["1.5", "1e3", "99999999999", "abc"].each((badid) => {
                    expect(
                        passes(
                            {customid: badid},
                            "pokedex.deleteCustomPokedex",
                            "customid",
                            trainerA
                        )
                    ).toBeFalse(badid);
                });
            });
        });

        describe("Friend requests and friendCheck", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Only the recipient may decide a friend request", () => {
                friendService.sendFriendRequest(trainerA.id, trainerB.id);
                var friendRequest = testData.findRow("friend", {trainerid: trainerA.id, friendid: trainerB.id});
                var target        = {friendrequestid: friendRequest.id, accept: true};

                expect(
                    passes(
                        target,
                        "friend.decideFriendRequest",
                        "friendrequestid",
                        trainerB
                    )
                ).toBeTrue("recipient");
                expect(
                    passes(
                        target,
                        "friend.decideFriendRequest",
                        "friendrequestid",
                        trainerA
                    )
                ).toBeFalse("sender");
                expect(
                    passes(
                        target,
                        "friend.decideFriendRequest",
                        "friendrequestid"
                    )
                ).toBeFalse("guest");
            });

            it("An accepted friendship can't be decided again", () => {
                friendService.sendFriendRequest(trainerA.id, trainerB.id);
                var friendRequest = testData.findRow("friend", {trainerid: trainerA.id, friendid: trainerB.id});
                friendService.acceptFriendRequest(friendRequest.id, trainerB.id);

                expect(
                    passes(
                        {friendrequestid: friendRequest.id, accept: false},
                        "friend.decideFriendRequest",
                        "friendrequestid",
                        trainerB
                    )
                ).toBeFalse("accepted");

                // A deny that reaches the service anyway leaves both directions in place
                friendService.denyFriendRequest(friendRequest.id, trainerB.id);
                expect(
                    testData.countRows(
                        "friend",
                        {
                            trainerid: trainerA.id,
                            friendid : trainerB.id,
                            accepted : true
                        }
                    )
                ).toBe(1);
                expect(
                    testData.countRows(
                        "friend",
                        {
                            trainerid: trainerB.id,
                            friendid : trainerA.id,
                            accepted : true
                        }
                    )
                ).toBe(1);
            });

            it("Only friends may view each other's profile", () => {
                var target = {trainerid: trainerB.id};
                expect(
                    passes(
                        target,
                        "trainer.viewProfile",
                        "trainerid",
                        admin
                    )
                ).toBeFalse("not friends");

                // B sending back the request from the test above accepts it
                friendService.sendFriendRequest(trainerB.id, trainerA.id);

                expect(
                    passes(
                        target,
                        "trainer.viewProfile",
                        "trainerid",
                        trainerA
                    )
                ).toBeTrue("friends");
                expect(passes(target, "trainer.viewProfile", "trainerid")).toBeFalse("guest");
            });

            // A and B are friends from here on
            it("allowSelf lets you view your own stats as well as a friend's", () => {
                expect(
                    passes(
                        {trainerid: trainerA.id},
                        "stats.friendStats",
                        "trainerid",
                        trainerA
                    )
                ).toBeTrue("self");
                expect(
                    passes(
                        {trainerid: trainerB.id},
                        "stats.friendStats",
                        "trainerid",
                        trainerA
                    )
                ).toBeTrue("friend");
                expect(
                    passes(
                        {trainerid: trainerA.id},
                        "stats.friendStats",
                        "trainerid",
                        admin
                    )
                ).toBeFalse("not friends");
                expect(
                    passes(
                        {trainerid: trainerA.id},
                        "stats.friendStats",
                        "trainerid"
                    )
                ).toBeFalse("guest");
            });

            it("isFriend false only allows a friend request to someone you have no request with", () => {
                var friendRequest = (trainer, friend) => {
                    return {trainerid: trainer.id, friendid: friend.id};
                };

                expect(
                    passes(
                        friendRequest(admin, trainerA),
                        "friend.sendFriendRequest",
                        "friendid",
                        admin
                    )
                ).toBeTrue("no request yet");
                expect(
                    passes(
                        friendRequest(trainerA, trainerB),
                        "friend.sendFriendRequest",
                        "friendid",
                        trainerA
                    )
                ).toBeFalse("already friends");
                expect(
                    passes(
                        friendRequest(trainerA, trainerA),
                        "friend.sendFriendRequest",
                        "friendid",
                        trainerA
                    )
                ).toBeFalse("yourself");
            });
        });

        describe("entityExists ownerField and publicColumn - records you own or public ones", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Passes for the owner of a private custom pokedex and anyone for a public one", () => {
                var privateid = customService.create(
                    trainerid = trainerA.id,
                    name      = "Private validator test",
                    isPublic  = false
                );
                var publicid = customService.create(
                    trainerid = trainerA.id,
                    name      = "Public validator test",
                    isPublic  = true
                );
                var target = (trainer, customid) => {
                    return {
                        trainerid: trainer.id,
                        customid : customid,
                        shiny    : false,
                        hundo    : false
                    };
                };

                expect(
                    passes(
                        target(trainerA, privateid),
                        "pokedex.getCustomPokedex",
                        "customid",
                        trainerA
                    )
                ).toBeTrue("owner");
                expect(
                    passes(
                        target(trainerB, privateid),
                        "pokedex.getCustomPokedex",
                        "customid",
                        trainerB
                    )
                ).toBeFalse("private");
                expect(
                    passes(
                        target(trainerB, publicid),
                        "pokedex.getCustomPokedex",
                        "customid",
                        trainerB
                    )
                ).toBeTrue("public");
                // ownerField checks the trainer in the request, so an admin viewing B's pokedexes sees what B can
                expect(
                    passes(
                        target(trainerB, privateid),
                        "pokedex.getCustomPokedex",
                        "customid",
                        admin
                    )
                ).toBeFalse("admin as B");
            });

            it("Trade plans need exactly one of region or a custom pokedex you can see", () => {
                var privateid = customService.create(
                    trainerid = trainerB.id,
                    name      = "Trade validator test",
                    isPublic  = false
                );
                var target = (region, customid) => {
                    return {
                        friend  : trainerB.id,
                        region  : region,
                        customid: customid,
                        shiny   : "off"
                    };
                };

                expect(
                    passes(
                        target("Kanto", -1),
                        "trade.tradePlan",
                        "customid",
                        trainerA
                    )
                ).toBeTrue("region");
                expect(
                    passes(
                        target("", -1),
                        "trade.tradePlan",
                        "customid",
                        trainerA
                    )
                ).toBeFalse("neither");
                expect(
                    passes(
                        target("Kanto", privateid),
                        "trade.tradePlan",
                        "customid",
                        trainerB
                    )
                ).toBeFalse("both");
                expect(
                    passes(
                        target("", privateid),
                        "trade.tradePlan",
                        "customid",
                        trainerB
                    )
                ).toBeTrue("own custom");
                expect(
                    passes(
                        target("", privateid),
                        "trade.tradePlan",
                        "customid",
                        trainerA
                    )
                ).toBeFalse("someone else's private custom");
            });
        });

        describe("trainer.updateProfile", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            /**
             * Profile form for the trainer, unchanged unless overridden
             */
            var profile = (trainer, overrides = {}) => {
                var target = {
                    trainerid      : trainer.id,
                    username       : trainer.username,
                    email          : trainer.email,
                    icon           : trainer.icon,
                    password       : "",
                    currentPassword: "",
                    friendcode     : "",
                    securityLevel  : "",
                    verified       : "",
                    defaultView    : "normal",
                    defaultRegion  : "Kanto",
                    defaultPage    : "/"
                };
                target.append(overrides);
                return target;
            };

            it("uniqueDatabaseField excludeField ignores the trainer being edited", () => {
                expect(
                    passes(
                        profile(trainerA),
                        "trainer.updateProfile",
                        "username",
                        trainerA
                    )
                ).toBeTrue("own username");
                expect(
                    passes(
                        profile(trainerA),
                        "trainer.updateProfile",
                        "email",
                        trainerA
                    )
                ).toBeTrue("own email");
                expect(
                    passes(
                        profile(trainerA, {username: trainerB.username}),
                        "trainer.updateProfile",
                        "username",
                        trainerA
                    )
                ).toBeFalse("taken username");
                expect(
                    passes(
                        profile(trainerA, {email: trainerB.email}),
                        "trainer.updateProfile",
                        "email",
                        trainerA
                    )
                ).toBeFalse("taken email");
                expect(
                    passes(
                        profile(trainerA, {friendcode: trainerB.friendcode}),
                        "trainer.updateProfile",
                        "friendcode",
                        admin
                    )
                ).toBeFalse("taken friendcode");
                expect(
                    passes(
                        profile(trainerA, {friendcode: trainerA.friendcode}),
                        "trainer.updateProfile",
                        "friendcode",
                        admin
                    )
                ).toBeTrue("own friendcode");
            });

            it("securityCheck adminOnly - only admins set the friendcode, security level and verified flag", () => {
                var fields = {
                    friendcode   : mockTrainer.makeFriendcode(),
                    securityLevel: "10",
                    verified     : "on"
                };
                fields.each((field, value) => {
                    var target = profile(trainerA, {"#field#": value});
                    expect(passes(target, "trainer.updateProfile", field, trainerA)).toBeFalse("#field# as a regular user");
                    expect(passes(target, "trainer.updateProfile", field, admin)).toBeTrue("#field# as an admin");
                    expect(
                        passes(
                            profile(trainerA),
                            "trainer.updateProfile",
                            field,
                            trainerA
                        )
                    ).toBeTrue("#field# left blank");
                });
            });

            it("securityCheck messages say who attempted what, for the audit log", () => {
                var messageFor = (target, field, trainer) => {
                    mockTrainer.actAs(trainer);
                    return validation
                        .validate(target = target, constraints = "trainer.updateProfile")
                        .getFieldErrors(field)
                        .filter((error) => error.getValidationType() == "securityCheck")
                        .map((error) => error.getMessage());
                };

                var adminOnly = messageFor(
                    profile(trainerA, {securityLevel: "50"}),
                    "securityLevel",
                    trainerA
                );
                expect(adminOnly).toHaveLength(1);
                expect(adminOnly[1]).toInclude("Trainer #trainerA.id# (level ");
                expect(adminOnly[1]).toInclude("is not an admin: set securityLevel to '50'");

                var otherTrainer = messageFor(profile(trainerB), "trainerid", trainerA);
                expect(otherTrainer).toHaveLength(1);
                expect(otherTrainer[1]).toInclude("is not an admin: acted on trainer #trainerB.id#");
            });

            it("Only takes valid security levels and verified values", () => {
                expect(
                    passes(
                        profile(trainerA, {securityLevel: "999"}),
                        "trainer.updateProfile",
                        "securityLevel",
                        admin
                    )
                ).toBeFalse("unknown level");
                expect(
                    passes(
                        profile(trainerA, {verified: "notvalid"}),
                        "trainer.updateProfile",
                        "verified",
                        admin
                    )
                ).toBeFalse("bad verified");
            });

            it("securityCheck noHigherLevel - no one edits a trainer who outranks them", () => {
                var developer = mockTrainer.make(
                    securityLevel = application.cbController.getSetting("permissions").developer,
                    autoLogin     = false
                );
                try {
                    expect(
                        passes(
                            profile(trainerA),
                            "trainer.updateProfile",
                            "trainerid",
                            admin
                        )
                    ).toBeTrue("admin editing a regular user");
                    expect(
                        passes(
                            profile(trainerA),
                            "trainer.updateProfile",
                            "trainerid",
                            trainerB
                        )
                    ).toBeFalse("regular user editing another");
                    expect(
                        passes(
                            profile(developer),
                            "trainer.updateProfile",
                            "trainerid",
                            admin
                        )
                    ).toBeFalse("admin editing a developer");
                    expect(
                        passes(
                            profile(developer),
                            "trainer.updateProfile",
                            "trainerid",
                            developer
                        )
                    ).toBeTrue("developer editing themselves");
                }
                finally {
                    mockTrainer.deleteTrainer(developer.id);
                }
            });
        });

        describe("stats.track", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Only tracks stats once a day", () => {
                var target = {
                    trainerid: trainerB.id,
                    xp       : 1,
                    caught   : 1,
                    spun     : 1,
                    walked   : 1
                };
                expect(passes(target, "stats.track", "trainerid", trainerB)).toBeTrue("first today");

                getInstance("services.stats").track(
                    trainerid = trainerB.id,
                    xp        = 1,
                    caught    = 1,
                    spun      = 1,
                    walked    = 1
                );
                expect(passes(target, "stats.track", "trainerid", trainerB)).toBeFalse("already tracked today");
            });
        });

        // pagination.orderBy trusts the column index, so the datatable constraints are what keep it in range
        describe("Datatable sort constraints", () => {
            it("Only allows a sort column the pokemon table has", () => {
                expect(
                    passes(
                        {"order[0][column]": 4},
                        "admin.getPokemon",
                        "order[0][column]"
                    )
                ).toBeTrue("last column");
                expect(
                    passes(
                        {"order[0][column]": 5},
                        "admin.getPokemon",
                        "order[0][column]"
                    )
                ).toBeFalse("past the last column");
                expect(
                    passes(
                        {"order[1][column]": 9},
                        "admin.getPokemon",
                        "order[1][column]"
                    )
                ).toBeFalse("second sort past the last column");
                expect(
                    passes(
                        {"order[0][column]": -1},
                        "admin.getPokemon",
                        "order[0][column]"
                    )
                ).toBeFalse("negative");
            });

            it("Only allows asc or desc", () => {
                expect(
                    passes(
                        {"order[0][dir]": "desc"},
                        "admin.getPokemon",
                        "order[0][dir]"
                    )
                ).toBeTrue("desc");
                expect(
                    passes(
                        {"order[0][dir]": "sideways"},
                        "admin.getPokemon",
                        "order[0][dir]"
                    )
                ).toBeFalse("not a direction");
            });
        });
    }

}
