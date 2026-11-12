component extends="coldbox.system.testing.BaseTestCase" {

    property name="accountService" inject="services.account";
    property name="auth"           inject="authenticationService@cbauth";
    property name="requestStorage" inject="RequestStorage@cbstorages";
    property name="sessionService" inject="services.session";
    property name="trainerService" inject="services.trainer";
    property name="userService"    inject="services.user";

    // Every mock trainer's real password - for checks that skip impersonation (userService.checkPassword)
    variables.MOCK_PASSWORD = "MockTrainer_Password1";

    /**
     * The password every mock trainer is registered with
     */
    string function getMockPassword() {
        return variables.MOCK_PASSWORD;
    }

    /**
     * Makes mock user for testing
     *
     * @securityLevel trainer's security level (10 regular, 50 admin, 60 developer)
     * @autoLogin     log in through the login form after creating
     * @verified      verified trainers have permissions, unverified have none
     */
    component function make(
        numeric securityLevel = 10,
        boolean autoLogin     = true,
        boolean verified      = true
    ) {
        var username = "TEST_#left(createUUID().replace("-", "", "all"), 10)#";
        var email    = "#username#@gmail.com";

        var trainer = accountService.register(
            username   = username,
            password   = variables.MOCK_PASSWORD,
            email      = email,
            friendcode = makeFriendcode(),
            icon       = "charmander"
        );
        trainer.setVerified(arguments.verified);
        trainer.setSecurityLevel(arguments.securityLevel);
        entitySave(trainer);
        ormFlush();
        trainerService.clearCache(trainer.getId());

        // A page a previous test was stopped at would otherwise be where this login lands
        session.delete("linkedEvent");

        if(arguments.autoLogin) {
            login(trainer = trainer, relocate_uri = arguments.verified ? "/" : "/verify");
        }
        else {
            setup();
            execute(route = "/", renderResults = true);
            expect(auth.isLoggedIn()).toBeFalse();
        }

        setup();
        session.mocktrainerid = trainer.getId();
        return trainerService.getFromId(session.mocktrainerid);
    }

    /**
     * Deletes the mock user created
     * Deletes any associated data
     */
    void function delete(numeric trainerid = session.mocktrainerid) {
        var trainer = entityLoadByPK("trainer", arguments.trainerid);

        // Attempt to delete the mock user from
        // May fail due to asynchronous db inserts/updates, if fails, just continue
        try {
            ormExecuteQuery("delete from requestlog where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from audit where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from blog where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from bug where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from comment where trainer = :trainer", {trainer: trainer});

            ormExecuteQuery(
                "delete from custompokedex where custom in (from custom where trainer = :trainer)",
                {trainer: trainer}
            );
            ormExecuteQuery("delete from custom where trainer = :trainer", {trainer: trainer});

            ormExecuteQuery("delete from friend where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from friend where friend = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from persist where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from pokedex where trainer = :trainer", {trainer: trainer});
            ormExecuteQuery("delete from stat where trainer = :trainer", {trainer: trainer});

            // ormExecuteQuery('delete from team where trainer = :trainer', {trainer: trainer});
            ormExecuteQuery("delete from trainermedal where trainer = :trainer", {trainer: trainer});

            entityDelete(trainer);
            ormFlush();
        }
        catch(any e) {
        }

        ormClearSession();
        trainerService.clearCache(arguments.trainerid);

        // Always clear session though
        sessionService.destroy(false);
        expect(auth.isLoggedIn()).toBeFalse();
    }

    /**
     * Log in the mock trainer through the login form
     *
     * @relocate_uri where doLogin should send them
     */
    void function login(required component trainer, string relocate_uri = "/") {
        // Force valid recaptcha
        session.recaptcha = {
            token    : "a",
            valid    : true,
            timestamp: now(),
            action   : "doLogin"
        };

        // Mock submitting login form - impersonation accepts any password in test, cbcsrf skips in test mode
        setup();
        event = post(route = "/login/doLogin", params = {email: arguments.trainer.getEmail(), password: createUUID()});

        var response = event.getResponse();
        if(isStruct(response) && (response?.keyExists("statuscode") ?: false)) {
            expect(response.statuscode).toBe(200);
        }
        else {
            expect(response.getStatusCode()).toBe(200);
        }
        expect(event.getValue("relocate_uri")).toBe(arguments.relocate_uri);

        // Verify cbauth has the trainer
        expect(auth.isLoggedIn()).toBeTrue();
        expect(auth.getUserId()).toBe(arguments.trainer.getId());
        expect(auth.getUser().getSecurityLevel()).toBe(arguments.trainer.getSecurityLevel());
    }

    /**
     * Act as this trainer without going through the login form
     * For tests that only need a logged in context
     */
    void function actAs(required component trainer) {
        auth.login(trainerService.getFromId(arguments.trainer.getId()));
    }

    /**
     * Act as a guest - logged out, but keeps the session (and session.mocktrainerid) around
     */
    void function actAsGuest() {
        auth.logout();
    }

    /**
     * Forget the trainer loaded for this request and its cached copy, so the next request reloads it
     * Use after changing a trainer directly in the database
     * (the test runner is one http request, so cbauth's per request user would otherwise stick)
     */
    void function refresh(numeric trainerid = session?.mocktrainerid ?: -1) {
        requestStorage.delete("cbauth__user");
        trainerService.clearCache(arguments.trainerid);
        ormClearSession(); // else hibernate hands back the same stale entity within this request
    }

    /**
     * Log out the mock trainer
     */
    void function logout() {
        var temp = session.mocktrainerid;
        event    = post(route = "/logout");
        expect(event.getResponse().getStatusCode()).toBe(200);
        expect(event.getValue("relocate_URI")).toBe("/"); // home page

        expect(auth.isLoggedIn()).toBeFalse();

        session.mocktrainerid = temp;
    }

    string function makeFriendcode() {
        return "#left(randRange(1, 999999999999) & "00000000000", 12)#";
    }

}
