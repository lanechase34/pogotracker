component extends="coldbox.system.testing.BaseTestCase" {

    property name="accountService"  inject="services.account";
    property name="auth"            inject="authenticationService@cbauth";
    property name="globalFunctions" inject="tests.resources.globalFunctions";
    property name="requestStorage"  inject="RequestStorage@cbstorages";
    property name="sessionService"  inject="services.session";
    property name="testData"        inject="tests.resources.testData";
    property name="trainerService"  inject="services.trainer";
    property name="userService"     inject="services.user";

    // Every mock trainer's real password - for checks that skip impersonation
    variables.MOCK_PASSWORD = "MockTrainer_Password1";

    /**
     * The password every mock trainer is registered with
     */
    public string function getMockPassword() {
        return variables.MOCK_PASSWORD;
    }

    /**
     * Makes mock user for testing
     *
     * @securityLevel trainer's security level (10 regular, 50 admin, 60 developer)
     * @autoLogin     log in through the login form after creating
     * @verified      verified trainers have permissions, unverified have none
     */
    public struct function make(
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
        testData.updateRow(
            "trainer",
            trainer.id,
            {verified: arguments.verified, securitylevel: arguments.securityLevel}
        );
        refresh(trainer.id);
        trainer = trainerService.getFromId(trainer.id);

        // A page a previous test was stopped at would otherwise be where this login lands
        session.delete("linkedEvent");

        if(arguments.autoLogin) {
            login(trainer = trainer, relocate_uri = arguments.verified ? "/" : "/verify");
        }
        else {
            expect(auth.isLoggedIn()).toBeFalse();
        }

        setup();
        session.mocktrainerid = trainer.id;
        return trainerService.getFromId(session.mocktrainerid);
    }

    /**
     * Makes a mock user and acts as them, without going through the login form
     *
     * @securityLevel trainer's security level (10 regular, 50 admin, 60 developer)
     * @verified      verified trainers have permissions, unverified have none
     */
    public struct function makeSignedIn(numeric securityLevel = 10, boolean verified = true) {
        var trainer = make(
            securityLevel = arguments.securityLevel,
            autoLogin     = false,
            verified      = arguments.verified
        );
        actAs(trainer);
        return trainer;
    }

    /**
     * Deletes the mock user created
     * Deletes any associated data
     */
    public void function deleteTrainer(numeric trainerid = session.mocktrainerid) {
        var owned = {trainerid: arguments.trainerid};

        // Attempt to delete the mock user from
        // May fail due to asynchronous db inserts/updates, if fails, just continue
        try {
            testData.deleteRows("request_log", owned);
            testData.deleteRows("audit", owned);
            testData.deleteRows("blog", owned);
            testData.deleteRows("bug", owned);
            testData.deleteRows("comment", owned);

            queryExecute(
                "DELETE FROM custompokedex WHERE customid IN (SELECT id FROM custom WHERE trainerid = :trainerid)",
                {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
            );
            testData.deleteRows("custom", owned);

            testData.deleteRows("friend", owned);
            testData.deleteRows("friend", {friendid: arguments.trainerid});
            testData.deleteRows("persist", owned);
            testData.deleteRows("pokedex", owned);
            testData.deleteRows("stat", owned);
            testData.deleteRows("trainermedal", owned);

            testData.deleteRows("trainer", {id: arguments.trainerid});
        }
        catch(any e) {
        }

        refresh(arguments.trainerid);

        // Always clear session though
        sessionService.destroy(false);
        expect(auth.isLoggedIn()).toBeFalse();
    }

    /**
     * Log in the mock trainer through the login form
     *
     * @relocate_uri where doLogin should send them
     */
    public void function login(required struct trainer, string relocate_uri = "/") {
        globalFunctions.storeRecaptcha("doLogin");

        // Mock submitting login form - impersonation accepts any password in test, cbcsrf skips in test mode
        setup();
        var event = post(route = "/login/doLogin", params = {email: arguments.trainer.email, password: createUUID()});

        var response = event.getResponse();
        if(isStruct(response) && (response?.keyExists("statuscode") ?: false)) {
            expect(response.statuscode).toBe(200);
        }
        else {
            expect(response.getStatusCode()).toBe(200);
        }
        expect(event.getValue("relocate_URI")).toBe(arguments.relocate_uri);

        // Verify cbauth has the trainer
        expect(auth.isLoggedIn()).toBeTrue();
        expect(auth.getUserId()).toBe(arguments.trainer.id);
        expect(auth.getUser().getSecurityLevel()).toBe(arguments.trainer.securitylevel);
    }

    /**
     * Act as this trainer without going through the login form - leave the trainer out (or pass null) to act as a guest
     * For tests that only need a logged in context
     */
    public void function actAs(struct trainer) {
        if(isNull(arguments.trainer)) {
            actAsGuest();
            return;
        }
        auth.login(userService.retrieveUserById(arguments.trainer.id));
    }

    /**
     * Act as a guest - logged out, but keeps the session (and session.mocktrainerid) around
     */
    public void function actAsGuest() {
        auth.logout();
    }

    /**
     * Forget the trainer loaded for this request and its cached copy, so the next request reloads it
     * Use after changing a trainer directly in the database
     * (the test runner is one http request, so cbauth's per request user would otherwise stick)
     */
    public void function refresh(numeric trainerid = session?.mocktrainerid ?: -1) {
        requestStorage.delete("cbauth__user");
        trainerService.clearCache(arguments.trainerid);
    }

    /**
     * The trainer's row as it is saved in the database right now
     *
     * @trainerid trainer pk
     */
    public struct function getSaved(required numeric trainerid) {
        return testData.getRowById("trainer", arguments.trainerid);
    }

    /**
     * Change columns on the trainer's row directly, then refresh so the next load sees them
     *
     * @trainerid trainer pk
     * @data      column -> value
     */
    public void function updateSaved(required numeric trainerid, required struct data) {
        testData.updateRow("trainer", arguments.trainerid, arguments.data);
        refresh(arguments.trainerid);
    }

    /**
     * Store a bcrypt hash of this password on the trainer, returns the hash
     */
    public string function setBcryptPassword(required struct trainer, required string password) {
        var bcryptHash = getInstance("@BCrypt").hashPassword(password = arguments.password);

        updateSaved(arguments.trainer.id, {password: bcryptHash, salt: ""});

        return bcryptHash;
    }

    /**
     * Store a pre-bcrypt (salted + peppered SHA) hash of this password on the trainer, returns the hash
     */
    public string function setLegacyPassword(required struct trainer, required string password) {
        var env        = new coldbox.system.core.delegates.Env();
        var salt       = createUUID();
        var legacyHash = hash(
            arguments.password & salt & env.getEnv("PEPPER"),
            env.getEnv("ALGORITHM"),
            "UTF-8",
            env.getEnv("ITERATIONS")
        );

        updateSaved(arguments.trainer.id, {password: legacyHash, salt: salt});

        return legacyHash;
    }

    /**
     * Start from a fresh guest session: no trainer, a blank reCAPTCHA result (so checks never throw) and a new session id
     */
    public void function resetSession() {
        sessionService.destroy(false);
        globalFunctions.storeRecaptcha(action = "", valid = false);
        session.sessionid = createUUID();
        setup();
    }

    /**
     * Log out the mock trainer
     */
    public void function logout() {
        var mockTrainerid = session.mocktrainerid;
        var event         = post(route = "/logout");
        expect(event.getResponse().getStatusCode()).toBe(200);
        expect(event.getValue("relocate_URI")).toBe("/"); // home page

        expect(auth.isLoggedIn()).toBeFalse();

        session.mocktrainerid = mockTrainerid;
    }

    public string function makeFriendcode() {
        return "#left(randRange(1, 999999999999) & "00000000000", 12)#";
    }

}
