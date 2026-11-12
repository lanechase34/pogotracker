component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer    = getInstance("tests.resources.mockTrainer");
        auth           = getInstance("authenticationService@cbauth");
        persistService = getInstance("services.persist");
        trainerService = getInstance("services.trainer");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.delete();
    }

    function run() {
        describe("sessionService", () => {
            describe("rotate()", () => {
                beforeEach(() => {
                    setup();
                    sessionService = createMock(className = "models.services.session");
                    sessionService.$("destroy");
                    sessionService.$("ensureSession");
                    sessionService.$("getCurrentSessionId");
                });

                it("Sets the new id on the session when rotation succeeds", () => {
                    sessionService.$("getRequestedSessionId", "OLD-ID");
                    sessionService.$("changeSessionId", "NEW-ID");

                    sessionService.rotate();

                    expect(session.sessionid).toBe("NEW-ID");
                    expect(sessionService.$count("destroy")).toBe(0);
                    expect(sessionService.$count("getCurrentSessionId")).toBe(0); // catch never entered
                });

                it("Continues safely when a concurrent request already rotated the id", () => {
                    // changeSessionId() throws, but the id has already moved off the inbound id
                    sessionService.$("getRequestedSessionId", "OLD-ID");
                    sessionService
                        .$(method = "changeSessionId")
                        .$throws(type = "java.lang.IllegalStateException", message = "UT010033: No session");
                    sessionService.$("getCurrentSessionId", "NEW-ID");

                    sessionService.rotate();

                    expect(session.sessionid).toBe("NEW-ID");
                    expect(sessionService.$count("destroy")).toBe(0);
                });

                it("Continues safely for a brand-new session the client never presented", () => {
                    // No inbound id -> no fixation risk even though rotation failed
                    sessionService.$("getRequestedSessionId", "");
                    sessionService
                        .$(method = "changeSessionId")
                        .$throws(type = "java.lang.IllegalStateException", message = "UT010033: No session");
                    sessionService.$("getCurrentSessionId", "FRESH-ID");

                    sessionService.rotate();

                    expect(session.sessionid).toBe("FRESH-ID");
                    expect(sessionService.$count("destroy")).toBe(0);
                });

                it("Destroys the session and throws when the inbound id was never rotated (fixation risk)", () => {
                    // changeSessionId() throws AND we are still on the id the client presented
                    sessionService.$("getRequestedSessionId", "FIXED-ID");
                    sessionService
                        .$(method = "changeSessionId")
                        .$throws(type = "java.lang.IllegalStateException", message = "UT010033: No session");
                    sessionService.$("getCurrentSessionId", "FIXED-ID");

                    expect(() => {
                        sessionService.rotate();
                    }).toThrow(type = "SessionRotationFailed");

                    expect(sessionService.$count("destroy")).toBe(1);
                });
            });

            describe("Logging in (cbauth postLogin -> interceptors/security.cfc)", () => {
                beforeEach(() => {
                    setup();
                });

                it("Rotates the session id and stamps the last login", () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();
                    sessionid = session.sessionid;
                    before    = now();

                    // The row is written in a fire and forget future - run it inline so it's there to read
                    var originalAsync = prepareMock(trainerService).$getProperty("async");
                    trainerService.$property(propertyName = "async", mock = syncAsync());
                    try {
                        auth.login(trainerService.getFromId(trainerid));
                    }
                    finally {
                        trainerService.$property(propertyName = "async", mock = originalAsync);
                    }

                    expect(session.sessionid).notToBe(sessionid);
                    expect(auth.getUser().getLastLogin()).toBeGTE(before);
                    ormClearSession();
                    expect(entityLoadByPK("trainer", trainerid).getLastLogin()).notToBeNull();

                    mockTrainer.delete(trainerid);
                });

                it("Backfills missing settings with the defaults", () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();

                    trainer.setSettings({defaultRegion: "Unova"});
                    mockTrainer.refresh(trainerid); // fresh load, not the instance holding the memo
                    expect(trainerService.getFromId(trainerid).getSettings()).notToHaveKey("defaultPage");

                    auth.login(trainerService.getFromId(trainerid));

                    mockTrainer.refresh(trainerid); // read back what was saved
                    var settings = trainerService.getFromId(trainerid).getSettings();
                    expect(settings.defaultRegion).toBe("Unova"); // kept
                    expect(settings).toHaveKey("defaultPage"); // filled in
                    expect(settings).toHaveKey("defaultView");

                    mockTrainer.delete(trainerid);
                });
            });

            describe("destroy()", () => {
                beforeEach(() => {
                    setup();
                    sessionService = getInstance("services.session");
                });

                it("Clears the persist cookie on a full logout", () => {
                    trainer   = mockTrainer.make();
                    trainerid = trainer.getId();
                    persistService.addCookie(trainer);
                    expect(persistService.checkCookie()).toBeTrue();

                    sessionService.destroy(idle = false);

                    expect(auth.isLoggedIn()).toBeFalse();
                    expect(persistService.checkCookie()).toBeFalse();

                    mockTrainer.delete(trainerid);
                });

                it("Preserves the persist cookie on an idle logout", () => {
                    trainer   = mockTrainer.make();
                    trainerid = trainer.getId();
                    persistService.addCookie(trainer);
                    expect(persistService.checkCookie()).toBeTrue();

                    sessionService.destroy(idle = true);

                    expect(auth.isLoggedIn()).toBeFalse();
                    expect(persistService.checkCookie()).toBeTrue();

                    persistService.deleteCookie(); // cleanup the preserved cookie
                    mockTrainer.delete(trainerid);
                });

                it("Does not throw when no trainer is logged in", () => {
                    auth.logout();

                    sessionService.destroy(idle = true);

                    expect(auth.isLoggedIn()).toBeFalse();
                });
            });
        });
    }

}
