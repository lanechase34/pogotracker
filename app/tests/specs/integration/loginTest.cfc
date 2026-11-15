component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer    = getInstance("tests.resources.mockTrainer");
        auth           = getInstance("authenticationService@cbauth");
        sessionService = getInstance("services.session");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
    }

    function run() {
        describe("Login handler tests", () => {
            beforeEach(() => {
                setup();
            });

            it("Authenticate with a valid email/password and receive a session", () => {
                var email = "test_0@gmail.com";

                // authenticate hands back the logged in user object
                var user = auth.authenticate(email, createUUID());
                expect(user.getEmail()).toBe(email);
                expect(auth.isLoggedIn()).toBeTrue();
                expect(auth.getUserId()).toBe(user.getId());

                sessionService.destroy(false);
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Rejects an unknown email", () => {
                expect(() => auth.authenticate("nobody_#createUUID()#@example.com", createUUID())).toThrow(
                    "InvalidCredentials"
                );
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Sends a guest back to the page they asked for after logging in", () => {
                var trainer = mockTrainer.make(autoLogin = false);

                setup();
                var event = execute(route = "/mypokedex");
                expect(event.getValue("relocate_uri")).toBe("/login");
                expect(session.linkedEvent).toBe("/mypokedex");

                mockTrainer.login(trainer = trainer, relocate_uri = "/mypokedex");
                expect(session).notToHaveKey("linkedEvent"); // single use
            });

            describe("Registration -> Login lifecycle", () => {
                it("Can get the login form", () => {
                    var event = get(route = "/login");
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude("data-handler=login");
                    expect(event.getRenderedContent()).toInclude("data-action=loginform");
                });

                it("Rejects registering with an icon that is not a base icon", () => {
                    globalFunctions.storeRecaptcha("register");

                    // mewtwo's file exists, so only the base icon check stops it
                    var lockedUsername = left(replace("locked_#createUUID()#", "-", "", "all"), 30);
                    var event          = post(
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
                    expect(testData.countRows("trainer", {username: lockedUsername})).toBe(0);
                });

                it("Can register a new user", () => {
                    var before = globalFunctions.countTestEmails();

                    globalFunctions.storeRecaptcha("register");

                    // Mock user
                    var username           = left(replace("register_#createUUID()#", "-", "", "all"), 30);
                    variables.testingEmail = "#username#@gmail.com"; // used in subsequent tests

                    var event = post(
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
                    var event = get(route = "/verify", renderResults = true);
                    expect(event.getResponse().getStatusCode()).toBe(200);

                    // Read most recent email to get the code
                    var code = globalFunctions
                        .readEmail()
                        .select("##verificationCode")
                        .text();

                    // Mock submitting verification code
                    event = post(route = "/login/verify", params = {code: code});

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue("relocate_URI")).toBe("/"); // home page

                    // Verification takes effect on the next request - no re-login needed
                    mockTrainer.refresh(auth.getUserId());
                    expect(auth.getUser().getSecurityLevel()).toBe(10); // Regular Trainer
                    expect(auth.getUser().getVerified()).toBeTrue();
                    expect(auth.getUser().hasPermission("user")).toBeTrue();
                });

                it("User can log out", () => {
                    var event = post(route = "/logout");

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue("relocate_URI")).toBe("/"); // home page

                    expect(auth.isLoggedIn()).toBeFalse();
                });

                it("Can get to forgot password form", () => {
                    var event = get(route = "/forgot");
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude("data-handler=login");
                    expect(event.getRenderedContent()).toInclude("data-action=forgotpasswordform");
                });

                it("Can request a reset password email and reset password", () => {
                    var before = globalFunctions.listTestEmails();

                    var event = post(route = "/login/forgotPassword", params = {email: testingEmail});

                    // Read the email this request sent - the verification emails above can share its timestamp
                    var sent = globalFunctions.listTestEmails().filter((name) => !before.contains(name));
                    expect(sent.len()).toBe(1);

                    var link = globalFunctions
                        .readEmail(sent[1])
                        .select("##resetLink")
                        .attr("href");
                    var uri  = right(link, link.len() - link.find(application.cbController.getSetting("httpPort")) - 3);
                    var code = right(uri, uri.len() - 7);

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
                if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
            });
        });
    }

}
