component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        auth           = getInstance("authenticationService@cbauth");
        persistService = getInstance("services.persist");
        accountService = getInstance("services.account");
        trainerService = getInstance("services.trainer");
        cookieName     = getController().getSetting("persistCookieName");
        persistDays    = getController().getSetting("persistDuration");

        // Shared by the life cycle tests
        trainer = mockTrainer.make(autoLogin = false);
    }

    function afterAll() {
        persistService.deleteCookie();
        mockTrainer.delete(trainer.getId());
        super.afterAll();
    }

    /**
     * A logged out visitor holding a valid remember me cookie for the trainer
     */
    private void function guestWithCookie(required component trainer) {
        mockTrainer.actAsGuest();
        persistService.addCookie(trainerService.getFromId(arguments.trainer.getId()));
        expect(persistService.checkCookie()).toBeTrue();
        expect(auth.isLoggedIn()).toBeFalse();
    }

    /**
     * Simulate the browser sending a persist cookie on a fresh request
     * The whole spec runs in one request, so drop the value persistService tracked from earlier specs
     *
     * @value raw cookie value
     */
    private void function incomingCookie(required string value) {
        request.delete("persistCookieValue");
        cookie[cookieName] = arguments.value;
    }

    private numeric function countPersist(required numeric trainerid) {
        return queryExecute(
            "select count(id) as count from persist where trainerid = :trainerid",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
        ).count;
    }

    private numeric function countAudits(required string detail) {
        return ormExecuteQuery(
            "select count(id) from audit where detail like :detail",
            {detail: arguments.detail},
            true
        );
    }

    function run() {
        describe("Remember me life cycle", () => {
            it("Can submit login form with remember me option and get a persist token", () => {
                countBefore = countPersist(trainer.getId());

                session.recaptcha = {
                    token    : "a",
                    valid    : true,
                    timestamp: now(),
                    action   : "doLogin"
                };

                setup();
                event = post(
                    route  = "/login/doLogin",
                    params = {
                        email   : trainer.getEmail(),
                        password: createUUID(),
                        persist : "on"
                    }
                );

                // Successful login redirects home
                expect(event.getValue("relocate_uri")).toBe("/");
                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.getId());

                // Persist cookie record created in DB and cookie set in browser
                expect(persistService.checkCookie()).toBeTrue();
                expect(countPersist(trainer.getId())).toBe(countBefore + 1);
            });

            it("Can have an 'idle' logout and automatically persist log back in", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Idle logout - session is destroyed but cookie is preserved
                event = post(route = "/logout", params = {idle: true});
                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeTrue();

                // Next request logs back in from the cookie
                setup();
                event = get(route = "/", renderResults = true);

                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.getId());
            });

            it("Can persist login when session becomes invalidated (jsessionid deleted)", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Simulate server-side session expiry without a formal logout
                sessionInvalidate();

                setup();
                event = get(route = "/", renderResults = true);

                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.getId());
            });

            it("Clicking logout deletes the persist cookie", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Full logout (not idle) - session AND browser cookie are both destroyed
                event = post(route = "/logout");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
            });

            it("Clicking logout does nothing if no persist cookie", () => {
                expect(persistService.checkCookie()).toBeFalse();

                event = post(route = "/logout");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
            });
        });

        describe("Remember me before the firewall", () => {
            beforeEach(() => {
                setup();
            });

            afterEach(() => {
                persistService.deleteCookie();
                mockTrainer.actAsGuest();
            });

            it("Logs the trainer in before a secured page is checked, so they land on it", () => {
                guestWithCookie(trainer);

                setup();
                var event = execute(route = "/mypokedex");

                expect(event.getValue("relocate_uri", "")).toBe("");
                expect(event.getCurrentEvent()).toBe("pokedex.myPokedex");
                expect(auth.getUserId()).toBe(trainer.getId());
                expect(event.getPrivateValue("oCurrentUser").getId()).toBe(trainer.getId());
            });

            it("Rotates the session id and stamps the last login", () => {
                guestWithCookie(trainer);
                var sessionid = session.sessionid;
                var before    = now();

                // The row is written in a fire and forget future - run it inline so it's there to read
                var originalAsync = prepareMock(trainerService).$getProperty("async");
                trainerService.$property(propertyName = "async", mock = syncAsync());
                try {
                    setup();
                    execute(route = "/");
                }
                finally {
                    trainerService.$property(propertyName = "async", mock = originalAsync);
                }

                expect(session.sessionid).notToBe(sessionid);
                ormClearSession();
                expect(entityLoadByPK("trainer", trainer.getId()).getLastLogin()).toBeGTE(dateAdd("s", -1, before));
            });

            it("Audits the remember me login", () => {
                var before = countAudits("Successful Persist Login%");
                guestWithCookie(trainer);

                setup();
                execute(route = "/");

                expect(countAudits("Successful Persist Login%")).toBe(before + 1);
            });
        });

        describe("Rejected remember me cookies", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAsGuest();
            });

            afterEach(() => {
                persistService.deleteCookie();
                mockTrainer.actAsGuest();
            });

            it("Ignores and deletes an unknown cookie", () => {
                var before = countAudits("Failed Persist Login");
                incomingCookie("not-a-real-cookie-#createUUID()#");

                setup();
                var event = execute(route = "/mypokedex");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
                expect(event.getValue("relocate_uri")).toBe("/login");
                expect(countAudits("Failed Persist Login")).toBe(before + 1);
            });

            it("Ignores an expired cookie and removes its record", () => {
                guestWithCookie(trainer);
                queryExecute(
                    "update persist set created = :created where trainerid = :trainerid",
                    {
                        created  : {value: dateAdd("d", -(persistDays + 1), now()), cfsqltype: "timestamp"},
                        trainerid: {value: trainer.getId(), cfsqltype: "integer"}
                    }
                );
                ormClearSession(); // the persist row was created by orm this request - make it re-read the new date

                setup();
                execute(route = "/");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
                expect(countPersist(trainer.getId())).toBe(0);
            });

            it("Is revoked when the trainer's password changes", () => {
                guestWithCookie(trainer);

                accountService.update(
                    trainerid = trainer.getId(),
                    username  = trainer.getUsername(),
                    password  = "NewPass_#createUUID()#",
                    email     = trainer.getEmail(),
                    icon      = trainer.getIcon()
                );
                expect(countPersist(trainer.getId())).toBe(0);

                setup();
                execute(route = "/");
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Is revoked when the trainer's security level changes", () => {
                guestWithCookie(trainer);

                accountService.update(
                    trainerid     = trainer.getId(),
                    username      = trainer.getUsername(),
                    password      = "",
                    email         = trainer.getEmail(),
                    icon          = trainer.getIcon(),
                    securityLevel = "20"
                );
                expect(countPersist(trainer.getId())).toBe(0);

                setup();
                execute(route = "/");
                expect(auth.isLoggedIn()).toBeFalse();
            });
        });
    }

}
