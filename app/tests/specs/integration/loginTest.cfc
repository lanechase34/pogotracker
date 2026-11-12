component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer = getInstance("tests.resources.mocktrainer");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.delete();
    }

    function run() {
        describe("Login handler tests", () => {
            beforeEach(() => {
                setup();

                auth           = getInstance("authenticationService@cbauth");
                sessionService = getInstance("services.session");
            });

            it("Authenticate with a valid email/password and receive a session", () => {
                email    = "test_0@gmail.com";
                password = createUUID();

                var trainer = auth.authenticate(email, password);
                expect(trainer.getEmail()).toBe(email);
                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(trainer.getId());

                sessionService.destroy(false);
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Rejects an unknown email", () => {
                expect(() => auth.authenticate("nobody_#createUUID()#@example.com", createUUID())).toThrow(
                    "InvalidCredentials"
                );
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Rotates the session id on login and keeps the trainer logged in", () => {
                trainer   = mockTrainer.make(autoLogin = false);
                sessionid = session.sessionid;

                mockTrainer.login(trainer);

                expect(auth.getUserId()).toBe(trainer.getId());
                expect(sessionid).notToBe(session.sessionid); // sessionid should rotate
                mockTrainer.delete();
            });

            it("Sends a guest back to the page they asked for after logging in", () => {
                trainer = mockTrainer.make(autoLogin = false);

                setup();
                event = execute(route = "/mypokedex");
                expect(event.getValue("relocate_uri")).toBe("/login");
                expect(session.linkedEvent).toBe("/mypokedex");

                mockTrainer.login(trainer = trainer, relocate_uri = "/mypokedex");
                expect(session).notToHaveKey("linkedEvent"); // single use
                mockTrainer.delete();
            });

            describe("Registration -> Login lifecycle", () => {
                it("Can get the login form", () => {
                    event = get(route = "/login");
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude("data-handler=login");
                    expect(event.getRenderedContent()).toInclude("data-action=loginform");
                });

                it("Rejects registering with an icon that is not a base icon", () => {
                    session.recaptcha = {
                        token    : "a",
                        valid    : true,
                        timestamp: now(),
                        action   : "register"
                    };

                    // mewtwo's file exists, so only the base icon check stops it
                    var lockedUsername = left(replace("locked_#createUUID()#", "-", "", "all"), 30);
                    event              = post(
                        route  = "/login/register",
                        params = {
                            username  : lockedUsername,
                            password  : createUUID(),
                            email     : "#lockedUsername#@gmail.com",
                            friendcode: mockTrainer.makeFriendcode(),
                            icon      : "mewtwo"
                        }
                    );

                    expect(event.getValue("relocate_EVENT", "")).toBe("register");
                    expect(auth.isLoggedIn()).toBeFalse();
                    expect(entityLoad("trainer", {username: lockedUsername})).toBeEmpty();
                });

                it("Can register a new user", () => {
                    before = globalFunctions.countTestEmails();

                    // Force valid recaptcha
                    session.recaptcha = {
                        token    : "a",
                        valid    : true,
                        timestamp: now(),
                        action   : "register"
                    };

                    // Mock user
                    username     = left(replace("register_#createUUID()#", "-", "", "all"), 30);
                    testingEmail = "#username#@gmail.com"; // used in subsequent tests

                    event = post(
                        route  = "/login/register",
                        params = {
                            username  : username,
                            password  : createUUID(),
                            email     : testingEmail,
                            friendcode: mockTrainer.makeFriendcode(),
                            icon      : "mudkip"
                        }
                    );

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    // Redirect directly to verify form
                    expect(event.getValue("relocate_URI")).toBe("/verify");

                    expect(auth.isLoggedIn()).toBeTrue();
                    expect(auth.getUser().getSecurityLevel()).toBe(5); // unverified trainer
                    expect(auth.getUser().getVerified()).toBeFalse();
                    expect(auth.getUser().hasPermission("user")).toBeFalse();

                    // verification email sends on successful register
                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                });

                it("Can verify a new user", () => {
                    // Send verification code
                    event = get(route = "/verify", renderResults = true);
                    expect(event.getResponse().getStatusCode()).toBe(200);

                    // Read most recent email to get the code
                    email = globalFunctions.readEmail();
                    code  = email.select("##verificationCode").text();

                    // Mock submitting verification code
                    event = post(route = "/login/verify", params = {code: code});

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue("relocate_URI")).toBe("/"); // home page

                    // Verification takes effect on the next request - no re-login needed
                    mockTrainer.refresh(auth.getUserId());
                    expect(auth.getUser().getSecurityLevel()).toBe(10); // Regular Trainer
                    expect(auth.getUser().getVerified()).toBeTrue();
                    expect(auth.getUser().hasPermission("user")).toBeTrue();

                    sleep(4000);
                });

                it("User can log out", () => {
                    event = post(route = "/logout");

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue("relocate_URI")).toBe("/"); // home page

                    expect(auth.isLoggedIn()).toBeFalse();
                });

                it("Can get to forgot password form", () => {
                    event = get(route = "/forgot");
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude("data-handler=login");
                    expect(event.getRenderedContent()).toInclude("data-action=forgotpasswordform");
                });

                it("Can request a reset password email and reset password", () => {
                    before = globalFunctions.countTestEmails();

                    event = post(route = "/login/forgotPassword", params = {email: testingEmail});

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);

                    email = globalFunctions.readEmail();
                    link  = email.select("##resetLink").attr("href");

                    uri  = right(link, link.len() - link.find(application.cbController.getSetting("httpPort")) - 3);
                    code = right(uri, uri.len() - 7);

                    expect(uri.len()).toBeGTE(1);

                    // Get the reset password form using the link emailed
                    event = get(route = uri, params = {});
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude("data-handler=login");
                    expect(event.getRenderedContent()).toInclude("data-action=resetpasswordform");

                    // A password that fails validation is rejected without using up the link
                    event = post(route = "/login/resetPassword", params = {resetCode: code, password: "short"});
                    expect(event.getValue("relocate_URI")).toBe("/login");

                    // Reset the password - same link still works
                    event = post(route = "/login/resetPassword", params = {resetCode: code, password: createUUID()});

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue("relocate_URI")).toBe("/login"); // login form
                    expect(getFlashScope().exists("alert")).toBeTrue();
                    expect(getFlashScope().get("alert").message).toBe("Successfully reset password.");

                    expect(auth.isLoggedIn()).toBeFalse();
                });
            });

            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });
        });
    }

}
