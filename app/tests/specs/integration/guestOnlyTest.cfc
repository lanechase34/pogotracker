/**
 * interceptors/guestonly.cfc
 *  - logged in trainers are kept out of the guest-only events (settings.guestOnlyEvents)
 *  - unverified trainers can only verify their account or log out
 * firewallTest has the access matrix, this covers the edges - posts, json callers, switching accounts, logout
 */
component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");
        requestStub = getInstance("tests.resources.requestStub");
        auth        = getInstance("authenticationService@cbauth");

        personas = {
            unverified: mockTrainer.make(verified = false, autoLogin = false),
            verified  : mockTrainer.make(autoLogin = false),
            other     : mockTrainer.make(autoLogin = false) // an account someone tries to switch to
        };

        // A page view or form post that would otherwise be accepted, per guest-only route
        guestRoutes = [
            {method: "get", route: "/login"},
            {method: "get", route: "/register"},
            {method: "get", route: "/forgot"},
            {method: "get", route: "/reset/notarealcode"},
            {
                // Switching accounts - the tests below check the trainer is still logged in as themselves
                method: "post",
                route : "/login/doLogin",
                params: {email: personas.other.getEmail(), password: createUUID()}
            },
            {
                method: "post",
                route : "/login/register",
                params: {
                    username  : "GUEST_#left(createUUID().replace("-", "", "all"), 10)#",
                    password  : createUUID(),
                    email     : "guest_#left(createUUID().replace("-", "", "all"), 10)#@gmail.com",
                    friendcode: mockTrainer.makeFriendcode(),
                    icon      : "mudkip"
                }
            },
            {
                method: "post",
                route : "/login/forgotPassword",
                params: {email: personas.other.getEmail()}
            },
            {
                method: "post",
                route : "/login/resetPassword",
                params: {resetCode: "notarealcode", password: createUUID()}
            }
        ];
    }

    function afterAll() {
        personas.each((name, trainer) => mockTrainer.delete(trainer.getId()));
        super.afterAll();
    }

    private any function submitRoute(required struct guestRoute) {
        setup();
        return arguments.guestRoute.method == "get"
         ? get(route = arguments.guestRoute.route)
         : post(route = arguments.guestRoute.route, params = arguments.guestRoute.params);
    }

    private numeric function countTrainers() {
        return ormExecuteQuery("select count(id) from trainer", true);
    }

    function run() {
        describe("Guest-only events setting", () => {
            it("Lists every login action except verifying and logging out", () => {
                var guestOnly = getController().getSetting("guestOnlyEvents");
                var exempt    = ["verifyForm", "verify", "logout"];
                var implicit  = [
                    "preHandler",
                    "postHandler",
                    "aroundHandler",
                    "onMissingAction",
                    "onError",
                    "onInvalidHTTPMethod"
                ];

                // A new login action has to be added to the setting (or exempt here) on purpose
                var missing = getComponentMetadata("handlers.login").functions
                    .filter((fn) => (fn.access ?: "public") == "public")
                    .map((fn) => fn.name)
                    .filter((name) => !exempt.findNoCase(name) && !implicit.findNoCase(name))
                    .filter((name) => !guestOnly.findNoCase("login.#name#"));

                expect(missing).toBeEmpty("Not in guestOnlyEvents: #missing.toList()#");
                for(var name in exempt) {
                    expect(guestOnly.findNoCase("login.#name#")).toBe(0, "login.#name# must stay reachable");
                }
            });
        });

        describe("Guests", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAsGuest();
            });

            it("Can reach the guest-only pages", () => {
                var pages = {
                    "/login"   : "login.loginForm",
                    "/register": "login.registrationForm",
                    "/forgot"  : "login.forgotPasswordForm"
                };
                for(var route in pages) {
                    setup();
                    var event = execute(route = route);
                    expect(event.getValue("relocate_uri", "")).toBe("", route);
                    expect(event.getCurrentEvent()).toBe(pages[route], route);
                }
            });
        });

        describe("Verified trainers", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAs(personas.verified);
            });

            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Are sent home from every guest-only page and form post", () => {
                var trainersBefore = countTrainers();
                for(var guestRoute in guestRoutes) {
                    var event = submitRoute(guestRoute);
                    expect(event.getValue("relocate_uri")).toBe("/", guestRoute.route);
                    expect(auth.getUserId()).toBe(personas.verified.getId(), guestRoute.route);
                }
                expect(countTrainers()).toBe(trainersBefore); // the registration post never ran
            });

            it("Are sent home from the verify post", () => {
                expect(post(route = "/login/verify", params = {code: "12345678"}).getValue("relocate_uri")).toBe("/");
            });

            it("Get a 400 from a guest-only json endpoint", () => {
                session.delete("recaptcha");
                var event = requestStub.asJsonRequest(() => post(route = "/verifyrecaptcha", params = {recaptchaToken: "test-token"}));
                var data  = event.getPrivateValue("cbox_renderdata");

                expect(data.statusCode).toBe(400);
                expect(data.data.success).toBeFalse();
                expect(data.data.message).toBe("You are already logged in.");
                expect(event.getValue("relocate_uri", "")).toBe("");
                expect(session).notToHaveKey("recaptcha"); // the action never ran
            });
        });

        describe("Unverified trainers", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAs(personas.unverified);
            });

            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Are sent to verify from every guest-only page and form post", () => {
                var trainersBefore = countTrainers();
                for(var guestRoute in guestRoutes) {
                    var event = submitRoute(guestRoute);
                    expect(event.getValue("relocate_uri")).toBe("/verify", guestRoute.route);
                    expect(auth.getUserId()).toBe(personas.unverified.getId(), guestRoute.route);
                }
                expect(countTrainers()).toBe(trainersBefore);
            });

            it("Can reach the verify form, with a way to log out", () => {
                var event = execute(route = "/verify", renderResults = true);

                expect(event.getValue("relocate_uri", "")).toBe("");
                expect(event.getCurrentEvent()).toBe("login.verifyForm");
                expect(event.getRenderedContent()).toInclude("data-action=verifyform");
                expect(event.getRenderedContent()).toInclude("action=""/logout""");
            });

            it("Can submit a verification code", () => {
                // A wrong code reaches the action and is rejected there - not blocked by the interceptor
                var event = post(route = "/login/verify", params = {code: "00000000"});

                expect(event.getCurrentEvent()).toBe("login.verify");
                expect(event.getValue("relocate_uri")).toBe("/verify");
                expect(getFlashScope().get("alert").message).toBe("Invalid verification code. Please try again.");
            });

            it("Can log out", () => {
                var event = post(route = "/logout");

                expect(event.getValue("relocate_uri")).toBe("/");
                expect(auth.isLoggedIn()).toBeFalse();
            });

            it("Can still see error pages", () => {
                var event = execute(event = "error.notFound");

                expect(event.getValue("relocate_uri", "")).toBe("");
                expect(event.getCurrentEvent()).toBe("error.notFound");
            });

            it("Get a 403 from json endpoints", () => {
                session.delete("recaptcha");
                var event = requestStub.asJsonRequest(() => post(route = "/verifyrecaptcha", params = {recaptchaToken: "test-token"}));
                var data  = event.getPrivateValue("cbox_renderdata");

                expect(data.statusCode).toBe(403);
                expect(data.data.success).toBeFalse();
                expect(data.data.message).toBe("Please verify your account.");
                expect(event.getValue("relocate_uri", "")).toBe("");
                expect(session).notToHaveKey("recaptcha");
            });
        });
    }

}
