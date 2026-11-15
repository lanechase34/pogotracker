component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();
        mockTrainer      = getInstance("tests.resources.mockTrainer");
        auth             = getInstance("authenticationService@cbauth");
        recaptchaService = getInstance("services.recaptcha");
        trainer          = mockTrainer.make(autoLogin = false);

        // Each gated action and a body that would otherwise be accepted
        gatedForms = {
            "dologin" : {route: "/login/doLogin", params: {email: trainer.email, password: createUUID()}},
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
        mockTrainer.deleteTrainer(trainer.id);
        restoreBackgroundLogs();
        super.afterAll();
    }

    private numeric function countFailedChecks() {
        return testData.countRows("audit", {detail: "Failed Recaptcha Check"});
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
                var expected = countFailedChecks();
                for(var action in gatedForms) {
                    session.delete("recaptcha");

                    expectRejected(submit(action), action);
                    expect(countFailedChecks()).toBe(++expected, action);
                }
            });

            it("Rejects each gated form sent without a User-Agent", () => {
                // No User-Agent fails the login preHandler's audit check, which must stop the request
                // A valid result gets it past the rateLimiter interceptor's reCAPTCHA check to that preHandler
                var auditService = prepareMock(getInstance("services.audit"));
                var originalUtil = auditService.$getProperty("utilService");
                var blankAgent   = createMock("models.services.util")
                    .$("getUserAgent", "")
                    .$("getRequestIP", "127.0.0.1")
                    .$("getReferer", "")
                    // The mock has no AsyncManager or logger wired in - this spec only checks the gate, not the audit rows
                    .$("runInBackground");

                auditService.$property(propertyName = "utilService", mock = blankAgent);
                try {
                    for(var action in gatedForms) {
                        globalFunctions.storeRecaptcha(action = action);
                        var event = submit(action);

                        expect(event.getValue("relocate_uri", "")).toBe("/unauthorized", action);
                        expect(auth.isLoggedIn()).toBeFalse(action);
                    }
                    expect(testData.countRows("trainer", {username: gatedForms.register.params.username})).toBe(0);
                }
                finally {
                    auditService.$property(propertyName = "utilService", mock = originalUtil);
                }
            });

            it("Rejects a failed reCAPTCHA result", () => {
                for(var action in gatedForms) {
                    globalFunctions.storeRecaptcha(action = action, valid = false);
                    expectRejected(submit(action), action);
                }
            });

            it("Rejects a result older than 30 seconds", () => {
                for(var action in gatedForms) {
                    globalFunctions.storeRecaptcha(action = action, secondsAgo = 60);
                    expectRejected(submit(action), action);
                }
            });

            it("Rejects a result for a different action", () => {
                globalFunctions.storeRecaptcha(action = "register");
                expectRejected(submit("dologin"), "dologin");
            });

            it("Accepts a fresh result for the action", () => {
                globalFunctions.storeRecaptcha(action = "doLogin");
                var event = submit("dologin");

                expect(event.getValue("relocate_uri")).toBe("/");
                expect(auth.getUserId()).toBe(trainer.id);
            });

            it("Only accepts a result once", () => {
                globalFunctions.storeRecaptcha(action = "forgotPassword");
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
