component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
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
        mockTrainer.deleteTrainer(trainer.id);
        restoreBackgroundLogs();
        super.afterAll();
    }

    /**
     * A logged out visitor holding a valid remember me cookie for the trainer
     */
    private void function guestWithCookie(required struct trainer) {
        mockTrainer.actAsGuest();
        persistService.addCookie(arguments.trainer.id);
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

    private numeric function countAudits(required string detail) {
        return queryExecute(
            "SELECT COUNT(id) AS count FROM audit WHERE detail LIKE :detail",
            {detail: {value: arguments.detail, cfsqltype: "varchar"}}
        ).count;
    }

    function run() {
        describe("Remember me life cycle", () => {
            it("Can submit login form with remember me option and get a persist token", () => {
                var countBefore = testData.countRows("persist", {trainerid: trainer.id});

                globalFunctions.storeRecaptcha("doLogin");

                setup();
                var event = post(
                    route  = "/login/doLogin",
                    params = {
                        email   : trainer.email,
                        password: createUUID(),
                        persist : "on"
                    }
                );

                // Successful login redirects home
                expect(event.getValue("relocate_uri")).toBe("/");
                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.id);

                // Persist cookie record created in DB and cookie set in browser
                expect(persistService.checkCookie()).toBeTrue();
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(countBefore + 1);
            });

            it("Can have an 'idle' logout and automatically persist log back in", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Idle logout - session is destroyed but cookie is preserved
                post(route = "/logout", params = {idle: true});
                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeTrue();

                // Next request logs back in from the cookie
                setup();
                execute(route = "/");

                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.id);
            });

            it("Can persist login when session becomes invalidated (jsessionid deleted)", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Simulate server-side session expiry without a formal logout
                sessionInvalidate();

                setup();
                execute(route = "/");

                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.id);
            });

            it("Clicking logout deletes the persist cookie", () => {
                expect(auth.isLoggedIn()).toBeTrue();
                expect(persistService.checkCookie()).toBeTrue();

                // Full logout (not idle) - session AND browser cookie are both destroyed
                post(route = "/logout");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
            });

            it("Clicking logout does nothing if no persist cookie", () => {
                expect(persistService.checkCookie()).toBeFalse();

                post(route = "/logout");

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
                expect(auth.getUserId()).toBe(trainer.id);
                expect(event.getPrivateValue("oCurrentUser").getId()).toBe(trainer.id);
            });

            it("Rotates the session id and stamps the last login", () => {
                guestWithCookie(trainer);
                var sessionid = session.sessionid;
                var before    = now();

                // The row is written in a fire and forget future - run it inline so it's there to read
                withSyncAsync(trainerService, () => {
                    setup();
                    execute(route = "/");
                });

                expect(session.sessionid).notToBe(sessionid);
                expect(mockTrainer.getSaved(trainer.id).lastlogin).toBeGTE(dateAdd("s", -1, before));
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
                    "UPDATE persist SET created = :created WHERE trainerid = :trainerid",
                    {
                        created  : {value: dateAdd("d", -(persistDays + 1), now()), cfsqltype: "timestamp"},
                        trainerid: {value: trainer.id, cfsqltype: "integer"}
                    }
                );
                mockTrainer.refresh(trainer.id); // drop this request's user and the cached trainer so the next request starts clean

                setup();
                execute(route = "/");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(persistService.checkCookie()).toBeFalse();
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);
            });

            it("Is revoked when the trainer's password changes", () => {
                guestWithCookie(trainer);

                accountService.updateTrainer(
                    trainerid = trainer.id,
                    username  = trainer.username,
                    password  = "NewPass_#createUUID()#",
                    email     = trainer.email,
                    icon      = trainer.icon
                );
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);

                setup();
                execute(route = "/");
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Is revoked when the trainer's security level changes", () => {
                guestWithCookie(trainer);

                accountService.updateTrainer(
                    trainerid     = trainer.id,
                    username      = trainer.username,
                    password      = "",
                    email         = trainer.email,
                    icon          = trainer.icon,
                    securityLevel = "20"
                );
                expect(testData.countRows("persist", {trainerid: trainer.id})).toBe(0);

                setup();
                execute(route = "/");
                expect(auth.isLoggedIn()).toBeFalse();
            });
        });
    }

}
