component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        requestStub    = getInstance("tests.resources.requestStub");
        auth           = getInstance("authenticationService@cbauth");
        cbcsrf         = getInstance("@cbcsrf");
        trainerService = getInstance("services.trainer");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.delete();
    }

    /**
     * Stand-in request context for the verifier
     */
    private any function fakeEvent(
        string method       = "POST",
        string currentEvent = "home.contact",
        struct form         = {},
        struct headers      = {}
    ) {
        var formValues   = arguments.form;
        var headerValues = arguments.headers;
        var httpMethod   = arguments.method;
        var eventName    = arguments.currentEvent;
        return createStub()
            .$("getHTTPMethod", httpMethod)
            .$("getCurrentEvent", eventName)
            .$(method = "valueExists", callback = (name) => formValues.keyExists(name))
            .$(
                method   = "getValue",
                callback = (name, defaultValue = "") => formValues.keyExists(name) ? formValues[name] : defaultValue
            )
            .$(
                method   = "getHTTPHeader",
                callback = (name, defaultValue = "") => headerValues.keyExists(name) ? headerValues[name] : defaultValue
            );
    }

    /**
     * Run the real cbcsrf verifier with test mode off
     */
    private void function verify(required any event) {
        verifier.preProcess(
            event         = arguments.event,
            interceptData = {},
            rc            = {},
            prc           = {}
        );
    }

    /**
     * Run error.onException for an exception thrown during `erroredEvent`
     */
    private any function handleException(required string type, string erroredEvent = "pokedex.myPokedex") {
        setup();
        var event = getRequestContext();
        event.setValue("event", arguments.erroredEvent);
        try {
            throw(type = arguments.type, message = "test #arguments.type#");
        }
        catch(any e) {
            event.setPrivateValue("exception", new coldbox.system.web.context.ExceptionBean(errorStruct = e));
        }
        try {
            getController().runEvent(event = "error.onException", prePostExempt = true);
        }
        catch(TestController.relocate e) {
            // MockController signals a relocate by throwing - execute() swallows it, runEvent() doesn't
        }
        return event;
    }

    function run() {
        describe("cbcsrf verifier", () => {
            beforeEach(() => {
                setup();
                verifier = prepareMock(getController().getInterceptorService().getInterceptor("VerifyCsfr@cbcsrf"));

                originalTestMode       = verifier.$getProperty("isTestMode");
                originalHandlerService = verifier.$getProperty("handlerService");

                verifier.$property(propertyName = "isTestMode", mock = false);
                // No skipCsrf annotations - keeps the stub event away from real handler loading
                verifier.$property(
                    propertyName = "handlerService",
                    mock         = createStub().$("getHandlerBean", createStub().$("getHandler", ""))
                );
            });

            afterEach(() => {
                verifier.$property(propertyName = "isTestMode", mock = originalTestMode);
                verifier.$property(propertyName = "handlerService", mock = originalHandlerService);
            });

            it("Rejects a post without a token", () => {
                expect(() => verify(fakeEvent())).toThrow("TokenNotFoundException");
            });

            it("Rejects a post with the wrong token", () => {
                cbcsrf.generate();
                expect(() => verify(fakeEvent(form = {csrf: "not-the-token"}))).toThrow("TokenMismatchException");
                expect(() => verify(fakeEvent(headers = {"x-csrf-token": "not-the-token"}))).toThrow(
                    "TokenMismatchException"
                );
            });

            it("Accepts the session's token as a form field or header", () => {
                var token = cbcsrf.generate();
                expect(() => verify(fakeEvent(form = {csrf: token}))).notToThrow();
                expect(() => verify(fakeEvent(headers = {"x-csrf-token": token}))).notToThrow();
            });

            it("Skips safe methods", () => {
                for(var method in ["GET", "HEAD", "OPTIONS"]) {
                    expect(() => verify(fakeEvent(method = method))).notToThrow(method);
                }
            });

            it("Skips error events", () => {
                expect(() => verify(fakeEvent(currentEvent = "error.unauthorized"))).notToThrow();
            });
        });

        describe("Token rotation", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Invalidates tokens issued before a login", () => {
                var trainer = mockTrainer.make(autoLogin = false);
                var token   = cbcsrf.generate();
                expect(cbcsrf.verify(token)).toBeTrue();

                auth.login(trainerService.getFromId(trainer.getId()));

                expect(cbcsrf.verify(token)).toBeFalse();
                expect(cbcsrf.verify(cbcsrf.generate())).toBeTrue(); // the new page gets a fresh one
            });
        });

        describe("Security exceptions in error.onException", () => {
            it("Turns a csrf failure into a 403 without a bug email", () => {
                for(
                    var type in [
                        "TokenNotFoundException",
                        "TokenMismatchException",
                        "NotAuthorized"
                    ]
                ) {
                    var emailsBefore = globalFunctions.countTestEmails();
                    var event        = handleException(type);

                    expect(event.getStatusCode()).toBe(403, type);
                    expect(event.getCurrentView()).toBe("/views/fragment/unauthorized", type);
                    expect(event.getValue("relocate_uri", "")).toBe("", type);
                    expect(globalFunctions.countTestEmails()).toBe(emailsBefore, type);
                }
            });

            it("Answers fetch callers with json", () => {
                var event = requestStub.asJsonRequest(() => handleException("TokenMismatchException"));
                var data  = event.getPrivateValue("cbox_renderdata");

                expect(data.statusCode).toBe(403);
                expect(data.data.success).toBeFalse();
            });

            it("Sends a stale login form back to the login page", () => {
                var event = handleException("TokenMismatchException", "login.doLogin");

                expect(event.getValue("relocate_uri")).toBe("/login");
                expect(getFlashScope().get("alert").message).toBe("Invalid. Please try again.");
            });

            it("Sends a trainer that no longer exists to the login page", () => {
                var event = handleException("NoUserLoggedIn");
                expect(event.getValue("relocate_uri")).toBe("/login");
            });
        });

        describe("Bugs in error.onException", () => {
            it("Answers fetch callers with a json 500 instead of relocating", () => {
                var event = requestStub.asJsonRequest(() => handleException("Application"));
                var data  = event.getPrivateValue("cbox_renderdata");

                expect(data.statusCode).toBe(500);
                expect(data.data.success).toBeFalse();
                expect(event.getValue("relocate_uri", "")).toBe("");
            });

            it("Relocates page requests to the error page", () => {
                var event = handleException("Application");
                expect(event.getValue("relocate_uri")).toBe("/exception");
            });

            it("Does not relocate when the error page itself failed", () => {
                var event = handleException("Application", "error.displayException");
                expect(event.getValue("relocate_uri", "")).toBe("");
            });
        });

        describe("Post forms", () => {
            it("Every post form in the views carries a csrf field", () => {
                // Cached fragments can't hold a per-session token - form.js adds one from the csrf-token meta tag
                var cachedFragments = ["views/pokemon/fragment/detailcontent.cfm"];
                var viewsPath       = expandPath("/views");
                var missing         = [];

                directoryList(viewsPath, true, "path", "*.cfm").each((path) => {
                    var relative = "views" & replace(replace(path, viewsPath, ""), "\", "/", "all");
                    if(cachedFragments.contains(relative)) return;

                    var html = fileRead(path);
                    var pos  = 1;
                    while(true) {
                        var found = reFindNoCase("<form\b[^>]*>", html, pos, true);
                        if(!found.pos[1]) break;

                        var tag      = mid(html, found.pos[1], found.len[1]);
                        var closeTag = findNoCase("</form>", html, found.pos[1]);
                        var body     = mid(
                            html,
                            found.pos[1],
                            (closeTag ? closeTag : html.len()) - found.pos[1]
                        );

                        if(reFindNoCase("method\s*=\s*[""']?post", tag) && !findNoCase("name=""csrf""", body)) {
                            missing.append("#relative#: #left(tag, 80)#");
                        }
                        pos = found.pos[1] + found.len[1];
                    }
                });

                expect(missing).toBeEmpty("Add <input type=""hidden"" name=""csrf"" value=""##csrfToken()##"">: #missing.toList("; ")#");
            });

            it("The layouts publish the token for fetch requests", () => {
                expect(fileRead(expandPath("/layouts/header.cfm"))).toInclude("name=""csrf-token""");
            });
        });
    }

}
