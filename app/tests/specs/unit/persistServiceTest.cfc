component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer = getInstance("tests.resources.mocktrainer");
        // Set up trainer to be shared throughout test suite
        trainer     = mockTrainer.make(autoLogin = false);

        loopCount       = 100;
        range           = 5;
        persistDuration = application.cbController.getSetting("persistDuration");
        persistUse      = application.cbController.getSetting("persistUse");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete(trainer.getId());
    }

    function run() {
        describe("Persist service", () => {
            beforeEach(() => {
                setup();
                persistService = getInstance("services.persist");
            });

            it("Can create a persist cookie", () => {
                expect(countPersist(trainerid = trainer.getId())).toBe(0);

                beforeCount = countPersist();

                // Create the persist cookie
                persistService.addCookie(trainer);

                // Trainer should now have one persist cookie record
                expect(countPersist(trainerid = trainer.getId())).toBe(1);
                expect(countPersist()).toBe(beforeCount + 1);
                expect(persistService.checkCookie()).toBeTrue();
            });

            it("Can rotate a persist cookie", () => {
                expect(persistService.checkCookie()).toBeTrue();
                persist = entityLoad("persist", {trainer: trainer}, true);
                expect(persist).notToBeNull();

                before = persistService.getCookie();
                persistService.rotateCookie(persist);

                expect(before).notToBeWithCase(persistService.getCookie());

                entityReload(persist);
                expect(dateDiff("s", persist.getUpdated(), now())).toBeLTE(10);
            });

            it("Can delete a persist cookie", () => {
                expect(persistService.checkCookie()).toBeTrue();
                expect(countPersist(trainerid = trainer.getId())).toBe(1);
                persistService.deleteCookie();
                expect(persistService.checkCookie()).toBeFalse();

                // Revoked server side too, so a copied cookie can't be replayed
                expect(countPersist(trainerid = trainer.getId())).toBe(0);
            });

            it("Can revoke all persist cookies for a trainer", () => {
                persistService.addCookie(trainer);
                persistService.addCookie(trainer);
                expect(countPersist(trainerid = trainer.getId())).toBe(2);

                persistService.revokeAll(trainer.getId());
                expect(countPersist(trainerid = trainer.getId())).toBe(0);

                persistService.deleteCookie();
            });

            it("Accepts the cookie it rotated from only during the grace window", () => {
                persistService.addCookie(trainer);
                var oldCookie = persistService.getCookie();
                persistService.rotateCookie(entityLoad("persist", {trainer: trainer}, true));
                var newCookie = persistService.getCookie();
                ormClearSession(); // rotation updates the row directly - re-read it

                // A request the browser sent before it saw the rotated cookie
                expect(persistService.login(oldCookie).success).toBeTrue();

                queryExecute(
                    "update persist set lastrotated = :rotated where trainerid = :trainerid",
                    {
                        rotated  : {value: dateAdd("n", -5, now()), cfsqltype: "timestamp"},
                        trainerid: {value: trainer.getId(), cfsqltype: "integer"}
                    }
                );
                ormClearSession();

                // Reusing the old cookie after the grace window revokes the login for both cookies
                expect(persistService.login(oldCookie).success).toBeFalse();
                expect(countPersist(trainerid = trainer.getId())).toBe(0);
                expect(persistService.login(newCookie).success).toBeFalse();

                persistService.deleteCookie();
            });

            it("Logging out with the cookie a row was rotated from still revokes the row", () => {
                persistService.addCookie(trainer);
                var oldCookie = persistService.getCookie();
                persistService.rotateCookie(entityLoad("persist", {trainer: trainer}, true));
                ormClearSession();
                expect(countPersist(trainerid = trainer.getId())).toBe(1);

                // The rotating response never reached the browser - it still sends the old cookie
                request.persistCookieValue = oldCookie;
                persistService.deleteCookie();

                expect(countPersist(trainerid = trainer.getId())).toBe(0);
            });

            it("Lets only one of two racing requests rotate the cookie", () => {
                persistService.addCookie(trainer);

                // Both requests loaded the row before either rotated it
                var persist = entityLoad("persist", {trainer: trainer}, true);
                expect(persistService.rotateCookie(persist)).toBeTrue();
                var winner = persistService.getCookie();

                expect(persistService.rotateCookie(persist)).toBeFalse();
                expect(persistService.getCookie()).toBeWithCase(winner);

                ormClearSession();
                expect(persistService.login(winner).success).toBeTrue();

                persistService.deleteCookie();
            });

            describe("Persist cookie task tests", () => {
                it("Can delete cookies that have expired", () => {
                    keep   = countPersist();
                    delete = 0;
                    for(var i = 1; i <= loopCount; i++) {
                        // Create cookies that have a create date between -persistDuration +/- 10 days ago
                        currRand = randRange(-1 * range, range);
                        currDate = dateAdd("d", (-1 * persistDuration) + currRand, now());
                        // Cookies that have a negative or 0 days added will be older than the threshold
                        if(currRand > 0) keep += 1;
                        else delete += 1;

                        var persist = entityNew(
                            "persist",
                            {
                                created    : currDate,
                                trainer    : trainer,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : now(),
                                lastrotated: now()
                            }
                        );
                        entitySave(persist);
                    }
                    ormFlush();

                    expect(countPersist()).toBe(keep + delete);
                    persistService.cleanupCookies();
                    expect(countPersist()).toBe(keep);
                });

                it("Can delete cookies that have not been used in interval", () => {
                    keep   = countPersist();
                    delete = 0
                    for(var i = 1; i <= loopCount; i++) {
                        currRand = randRange(-1 * range, range);
                        currDate = dateAdd("d", (-1 * persistUse) + currRand, now());

                        // Cookies that are older or equal to the persistUse amount will be deleted
                        if(currRand > 0) keep += 1;
                        else delete += 1;

                        var persist = entityNew(
                            "persist",
                            {
                                trainer    : trainer,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : currDate,
                                lastrotated: now()
                            }
                        );
                        entitySave(persist);
                    }
                    ormFlush();

                    expect(countPersist()).toBe(keep + delete);
                    persistService.cleanupCookies();
                    expect(countPersist()).toBe(keep);
                });
            });
        });
    }

    numeric function countPersist(numeric trainerid = -1) {
        var whereClause = "WHERE 1 = 1";
        var params      = {};
        if(arguments.trainerid >= 1) {
            whereClause &= " AND trainerid = :trainerid";
            params.insert("trainerid", {value: arguments.trainerid, cfsqltype: "integer"});
        }

        var count = queryExecute(
            "
            select count(id) as count
            from persist
            #whereClause#
        ",
            params
        );

        return count.count;
    }

}
