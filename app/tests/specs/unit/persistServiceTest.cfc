component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer = getInstance("tests.resources.mockTrainer");
        // Set up trainer to be shared throughout test suite
        trainer     = mockTrainer.make(autoLogin = false);

        range           = 5;
        persistDuration = application.cbController.getSetting("persistDuration");
        persistUse      = application.cbController.getSetting("persistUse");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);
    }

    function run() {
        describe("Persist service", () => {
            beforeEach(() => {
                setup();
                persistService = getInstance("services.persist");
            });

            it("Can create a persist cookie", () => {
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);

                var beforeCount = testData.countRows("persist");

                // Create the persist cookie
                persistService.addCookie(trainer.id);

                // Trainer should now have one persist cookie record
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(1);
                expect(testData.countRows("persist")).toBe(beforeCount + 1);
                expect(persistService.checkCookie()).toBeTrue();
            });

            it("Can rotate a persist cookie", () => {
                expect(persistService.checkCookie()).toBeTrue();
                var persist = persistFor(trainer);

                var before = persistService.getCookie();
                persistService.rotateCookie(persist);

                expect(before).notToBeWithCase(persistService.getCookie());

                expect(
                    dateDiff(
                        "s",
                        testData.getRowById("persist", persist.id).updated,
                        now()
                    )
                ).toBeLTE(10);
            });

            it("Can delete a persist cookie", () => {
                expect(persistService.checkCookie()).toBeTrue();
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(1);
                persistService.deleteCookie();
                expect(persistService.checkCookie()).toBeFalse();

                // Revoked server side too, so a copied cookie can't be replayed
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);
            });

            it("Can revoke all persist cookies for a trainer", () => {
                persistService.addCookie(trainer.id);
                persistService.addCookie(trainer.id);
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(2);

                persistService.revokeAll(trainer.id);
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);

                persistService.deleteCookie();
            });

            it("Accepts the cookie it rotated from only during the grace window", () => {
                persistService.addCookie(trainer.id);
                var oldCookie = persistService.getCookie();
                persistService.rotateCookie(persistFor(trainer));
                var newCookie = persistService.getCookie();
                mockTrainer.refresh(trainer.id); // rotation updates the row directly - re-read it

                // A request the browser sent before it saw the rotated cookie
                expect(persistService.login(oldCookie).success).toBeTrue();

                queryExecute(
                    "UPDATE persist SET lastrotated = :rotated WHERE trainerid = :trainerid",
                    {
                        rotated  : {value: dateAdd("n", -5, now()), cfsqltype: "timestamp"},
                        trainerid: {value: trainer.id, cfsqltype: "integer"}
                    }
                );
                mockTrainer.refresh(trainer.id);

                // Reusing the old cookie after the grace window revokes the login for both cookies
                expect(persistService.login(oldCookie).success).toBeFalse();
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);
                expect(persistService.login(newCookie).success).toBeFalse();

                persistService.deleteCookie();
            });

            it("Logging out with the cookie a row was rotated from still revokes the row", () => {
                persistService.addCookie(trainer.id);
                var oldCookie = persistService.getCookie();
                persistService.rotateCookie(persistFor(trainer));
                mockTrainer.refresh(trainer.id);
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(1);

                // The rotating response never reached the browser - it still sends the old cookie
                request.persistCookieValue = oldCookie;
                persistService.deleteCookie();

                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);
            });

            it("Lets only one of two racing requests rotate the cookie", () => {
                persistService.addCookie(trainer.id);

                // Both requests loaded the row before either rotated it
                var persist = persistFor(trainer);
                expect(persistService.rotateCookie(persist)).toBeTrue();
                var winner = persistService.getCookie();

                expect(persistService.rotateCookie(persist)).toBeFalse();
                expect(persistService.getCookie()).toBeWithCase(winner);

                mockTrainer.refresh(trainer.id);
                expect(persistService.login(winner).success).toBeTrue();

                persistService.deleteCookie();
            });

            describe("Persist cookie task tests", () => {
                it("Can delete cookies that have expired", () => {
                    var keep  = testData.countRows("persist");
                    var total = keep;
                    // Created dates from cutoff - range to cutoff + range days, one per day
                    // Offsets of 0 or less are at or older than the threshold and get deleted
                    for(var offset = -1 * range; offset <= range; offset++) {
                        if(offset > 0) keep++;
                        total++;

                        testData.insertRow(
                            "persist",
                            {
                                created    : dateAdd("d", (-1 * persistDuration) + offset, now()),
                                trainerid  : trainer.id,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : now(),
                                lastrotated: now()
                            }
                        );
                    }

                    expect(testData.countRows("persist")).toBe(total);
                    persistService.cleanupCookies();
                    expect(testData.countRows("persist")).toBe(keep);
                });

                it("Can delete cookies that have not been used in interval", () => {
                    var keep  = testData.countRows("persist");
                    var total = keep;
                    // Last used from cutoff - range to cutoff + range days, one per day
                    // Offsets of 0 or less are at or older than the persistUse amount and get deleted
                    for(var offset = -1 * range; offset <= range; offset++) {
                        if(offset > 0) keep++;
                        total++;

                        testData.insertRow(
                            "persist",
                            {
                                trainerid  : trainer.id,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : dateAdd("d", (-1 * persistUse) + offset, now()),
                                lastrotated: now()
                            }
                        );
                    }

                    expect(testData.countRows("persist")).toBe(total);
                    persistService.cleanupCookies();
                    expect(testData.countRows("persist")).toBe(keep);
                });
            });
        });
    }

    /**
     * The trainer's persist row as saved now
     * Passing the same row twice acts like two requests that loaded it at the same time
     */
    struct function persistFor(required struct trainer) {
        var row = testData.findRow("persist", {trainerid: arguments.trainer.id});
        expect(row).notToBeEmpty();
        return row;
    }

}
