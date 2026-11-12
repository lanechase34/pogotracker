component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer   = getInstance("tests.resources.mocktrainer");
        validation    = getInstance("ValidationManager@cbvalidation");
        friendService = getInstance("services.friend");
        customService = getInstance("services.custom");

        trainerA = mockTrainer.make(autoLogin = false);
        trainerB = mockTrainer.make(autoLogin = false);
        admin    = mockTrainer.make(securityLevel = 50, autoLogin = false);
    }

    function afterAll() {
        mockTrainer.delete(admin.getId());
        mockTrainer.delete(trainerB.getId());
        mockTrainer.delete(trainerA.getId());
        super.afterAll();
    }

    private void function actAs(any trainer) {
        if(isNull(arguments.trainer)) {
            mockTrainer.actAsGuest();
        }
        else {
            mockTrainer.actAs(arguments.trainer);
        }
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
        actAs(arguments?.asTrainer);
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
                    trainerid: trainerA.getId(),
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
                        trainer = trainerA,
                        name    = "Validator test",
                        public  = false
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
        });

        describe("Friend requests and friendCheck", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Only the recipient may decide a friend request", () => {
                friendService.sendFriendRequest(trainerA.getId(), trainerB.getId());
                var friendRequest = entityLoad(
                    "friend",
                    {trainer: trainerA, friend: trainerB},
                    true
                );
                var target = {friendrequestid: friendRequest.getId(), accept: true};

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

            it("Only friends may view each other's profile", () => {
                var target = {trainerid: trainerB.getId()};
                expect(
                    passes(
                        target,
                        "trainer.viewProfile",
                        "trainerid",
                        admin
                    )
                ).toBeFalse("not friends");

                // B sending back the request from the test above accepts it
                friendService.sendFriendRequest(trainerB.getId(), trainerA.getId());

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
        });
    }

}
