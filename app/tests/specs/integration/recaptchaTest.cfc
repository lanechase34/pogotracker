component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer      = getInstance("tests.resources.mocktrainer");
        auth             = getInstance("authenticationService@cbauth");
        recaptchaService = getInstance("services.recaptcha");
        trainer          = mockTrainer.make(autoLogin = false);

        // Each gated action and a body that would otherwise be accepted
        gatedForms = {
            "dologin" : {route: "/login/doLogin", params: {email: trainer.getEmail(), password: createUUID()}},
            "register": {
                route : "/login/register",
                params: {
                    username  : "REC_#left(createUUID().replace("-", "", "all"), 10)#",
                    password  : createUUID(),
                    email     : "rec_#left(createUUID().replace("-", "", "all"), 10)#@gmail.com",
                    friendcode: mockTrainer.makeFriendcode(),
                    icon      : "mudkip"
                }
            },
            "forgotpassword": {route: "/login/forgotPassword", params: {email: "nobody_#createUUID()#@example.com"}}
        };
    }

    function afterAll() {
        mockTrainer.delete(trainer.getId());
        super.afterAll();
    }

    private void function storeResult(
        required string action,
        boolean valid      = true,
        numeric secondsAgo = 0
    ) {
        session.recaptcha = {
            token    : "token",
            valid    : arguments.valid,
            timestamp: dateAdd("s", -arguments.secondsAgo, now()),
            action   : arguments.action
        };
    }

    private numeric function countFailedChecks() {
        return ormExecuteQuery("select count(id) from audit where detail = 'Failed Recaptcha Check'", true);
    }

    private any function submit(required string action) {
        setup();
        return post(route = gatedForms[arguments.action].route, params = gatedForms[arguments.action].params);
    }

    private void function expectRejected(required any event, required string action) {
        expect(arguments.event.getValue("relocate_uri")).toBe("/login", arguments.action);
        expect(getFlashScope().get("alert").message).toBe("Invalid. Please try again.", arguments.action);
        expect(auth.isLoggedIn()).toBeFalse(arguments.action);
    }

    function run() {
        describe("reCAPTCHA gates", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAsGuest();
                originalUseRecaptcha = recaptchaService.getUseRecaptcha();
                recaptchaService.setUseRecaptcha(true);
            });

            afterEach(() => {
                recaptchaService.setUseRecaptcha(originalUseRecaptcha);
                session.delete("recaptcha");
                mockTrainer.actAsGuest();
            });

            it("Rejects each gated form without a reCAPTCHA result", () => {
                for(var action in gatedForms) {
                    session.delete("recaptcha");
                    var before = countFailedChecks();

                    expectRejected(submit(action), action);
                    expect(countFailedChecks()).toBe(before + 1, action);
                }
            });

            it("Rejects each gated form sent without a User-Agent", () => {
                // No User-Agent fails the login preHandler's audit check, which must stop the request
                // rather than skip the reCAPTCHA check below it
                var auditService = prepareMock(getInstance("services.audit"));
                var originalUtil = auditService.$getProperty("utilService");
                var blankAgent   = createMock("models.services.util")
                    .$("getUserAgent", "")
                    .$("getRequestIP", "127.0.0.1")
                    .$("getReferer", "");

                auditService.$property(propertyName = "utilService", mock = blankAgent);
                try {
                    for(var action in gatedForms) {
                        session.delete("recaptcha");
                        var event = submit(action);

                        expect(event.getValue("relocate_uri", "")).toBe("/unauthorized", action);
                        expect(auth.isLoggedIn()).toBeFalse(action);
                    }
                    expect(entityLoad("trainer", {username: gatedForms.register.params.username})).toBeEmpty();
                }
                finally {
                    auditService.$property(propertyName = "utilService", mock = originalUtil);
                }
            });

            it("Rejects a failed reCAPTCHA result", () => {
                for(var action in gatedForms) {
                    storeResult(action = action, valid = false);
                    expectRejected(submit(action), action);
                }
            });

            it("Rejects a result older than 30 seconds", () => {
                for(var action in gatedForms) {
                    storeResult(action = action, secondsAgo = 60);
                    expectRejected(submit(action), action);
                }
            });

            it("Rejects a result for a different action", () => {
                storeResult(action = "register");
                expectRejected(submit("dologin"), "dologin");
            });

            it("Accepts a fresh result for the action", () => {
                storeResult(action = "doLogin");
                var event = submit("dologin");

                expect(event.getValue("relocate_uri")).toBe("/");
                expect(auth.getUserId()).toBe(trainer.getId());
            });

            it("Only accepts a result once", () => {
                storeResult(action = "forgotPassword");
                submit("forgotpassword");
                expect(getFlashScope().get("alert").message).toBe("Reset password email sent. Please check your email.");

                // Same session, no new reCAPTCHA
                expectRejected(submit("forgotpassword"), "forgotpassword");
            });
        });

        describe("/verifyrecaptcha", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAsGuest();
            });

            it("Rejects a request without a token", () => {
                var event = post(route = "/verifyrecaptcha", params = {});
                var data  = event.getPrivateValue("cbox_renderdata");

                expect(data.statusCode).toBe(400);
                expect(data.data.success).toBeFalse();
            });

            it("Stores the result for the next form post when reCAPTCHA is off", () => {
                var event = post(route = "/verifyrecaptcha", params = {recaptchaToken: "test-token"});

                expect(event.getPrivateValue("cbox_renderdata").data.success).toBeTrue();
                expect(session.recaptcha.valid).toBeTrue();
                expect(session.recaptcha.token).toBe("test-token");
            });
        });
    }

}
