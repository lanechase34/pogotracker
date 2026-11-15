component extends="coldbox.system.testing.BaseInterceptorTest" interceptor="interceptors.rateLimiter" {

    function beforeAll() {
        super.beforeAll();

        // Mock interceptor dependencies - flash comes from setup()'s MockFlash
        mockUtilService      = createEmptyMock(className = "models.services.util");
        mockRateLimitService = createEmptyMock(className = "models.services.rateLimit");
        mockRecaptchaService = createEmptyMock(className = "models.services.recaptcha");
        mockAuditService     = createEmptyMock(className = "models.services.audit");
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Run preProcess on the interceptor with the shared mocks
     */
    private function announce() {
        interceptor.preProcess(
            event  = mockRequestContext,
            data   = {},
            buffer = "",
            rc     = rc,
            prc    = prc
        );
    }

    /**
     * Run postLogin on the interceptor with the shared mocks
     */
    private function announceLogin() {
        interceptor.postLogin(
            event  = mockRequestContext,
            data   = {},
            buffer = "",
            rc     = rc,
            prc    = prc
        );
    }

    /**
     * Configure the limits the interceptor sees
     */
    private function withLimits(required struct limits) {
        interceptor.$property(propertyName = "rateLimits", mock = limits);
    }

    /**
     * Configure the events the interceptor gates on recaptcha
     */
    private function withRecaptchaChecks(required struct checks) {
        interceptor.$property(propertyName = "recaptchaChecks", mock = checks);
    }

    /**
     * The afterRecaptcha flag of each allow call, in order
     */
    private array function allowPasses() {
        return mockRateLimitService.$callLog().allow.map((call) => call?.afterRecaptcha ?: false);
    }

    function run() {
        describe("RateLimiter Interceptor", () => {
            beforeEach(() => {
                setup();

                // Reset mocks before each test
                mockUtilService.$reset();
                mockUtilService.$("getRequestIP", "192.168.1.1");
                interceptor.$("renderJsonError");

                mockFlash.$("put");

                mockRateLimitService.$reset();
                mockRateLimitService.$("allow", true);
                mockRateLimitService.$("reset");

                // Inject dependencies
                interceptor.$property(propertyName = "utilService", mock = mockUtilService);
                interceptor.$property(propertyName = "flash", mock = mockFlash);
                interceptor.$property(propertyName = "rateLimitService", mock = mockRateLimitService);

                mockRecaptchaService.$reset();
                mockRecaptchaService.$("check", true);
                interceptor.$property(propertyName = "recaptchaService", mock = mockRecaptchaService);

                mockAuditService.$reset();
                mockAuditService.$("getAuditObj", {trainerid: -1, event: "", detail: ""});
                mockAuditService.$("audit");
                interceptor.$property(propertyName = "auditService", mock = mockAuditService);

                interceptor.$("relocate");
                withLimits({
                    "login.dologin": {redirect: "/login", rules: [{by: "ip", limit: 5, window: 15}]},
                    "home.contact" : {redirect: "", rules: [{by: "ip", limit: 5, window: 60}]}
                });
                withRecaptchaChecks({});

                // Mock event object
                mockRequestContext = createEmptyMock("coldbox.system.web.context.RequestContext");
                mockRequestContext.$("getCurrentEvent", "login.doLogin");
                mockRequestContext.$("getCurrentAction", "doLogin");
                mockRequestContext.$("renderData", mockRequestContext);
                mockRequestContext.$("noExecution", mockRequestContext);
                mockRequestContext.$("isNoExecution", false);

                rc  = {};
                prc = {};
            });

            it("Should skip rate limiting when an earlier interceptor already blocked the request", () => {
                // e.g. guestOnly rendered a json error and called noExecution()
                mockRequestContext.$("isNoExecution", true);

                announce();

                expect(mockRequestContext.$never("getCurrentEvent")).toBeTrue();
                expect(mockRateLimitService.$never("allow")).toBeTrue();
            });

            it("Should skip rate limiting when current event has no rate limit configured", () => {
                mockRequestContext.$("getCurrentEvent", "pokedex.myPokedex");

                announce();

                expect(mockUtilService.$never("getRequestIP")).toBeTrue();
                expect(mockRateLimitService.$never("allow")).toBeTrue();
            });

            it("Should check the lowercased event with the request ip and rc", () => {
                rc.email = "test@gmail.com";

                announce();

                var allowCall = mockRateLimitService.$callLog().allow[1];
                expect(allowCall.name).toBe("login.dologin");
                expect(allowCall.ip).toBe("192.168.1.1");
                expect(allowCall.context.email).toBe("test@gmail.com");
            });

            it("Should allow the request when the limit is not exceeded", () => {
                announce();

                expect(mockRateLimitService.$once("allow")).toBeTrue();
                expect(interceptor.$never("relocate")).toBeTrue();
                expect(interceptor.$never("renderJsonError")).toBeTrue();
            });

            it("Should relocate form posts with an alert when the limit is exceeded", () => {
                mockRateLimitService.$("allow", false);

                announce();

                expect(mockFlash.$once("put")).toBeTrue();
                expect(mockFlash.$callLog().put[1].name).toBe("alert");
                expect(mockFlash.$callLog().put[1].value.type).toBe("danger");
                expect(interceptor.$once("relocate")).toBeTrue();
                expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                expect(interceptor.$never("renderJsonError")).toBeTrue();
            });

            it("Should return a json 429 for ajax endpoints when the limit is exceeded", () => {
                mockRequestContext.$("getCurrentEvent", "home.contact");
                mockRateLimitService.$("allow", false);

                announce();

                expect(interceptor.$once("renderJsonError")).toBeTrue();
                var renderCall = interceptor.$callLog().renderJsonError[1];
                // positional call: (event, statusCode, message)
                expect(renderCall[2]).toBe(429);
                expect(renderCall[3]).notToBeEmpty();
                expect(interceptor.$never("relocate")).toBeTrue();
            });

            it("Should not check recaptcha for events outside reCaptchaChecks", () => {
                announce();

                expect(mockRecaptchaService.$never("check")).toBeTrue();
                expect(allowPasses()).toBe([false]);
            });

            describe("reCaptchaChecks events", () => {
                beforeEach(() => {
                    withRecaptchaChecks({"login.dologin": true});
                });

                it("Should check recaptcha against the lowercased bare action", () => {
                    announce();

                    expect(mockRecaptchaService.$once("check")).toBeTrue();
                    expect(mockRecaptchaService.$callLog().check[1].expectedAction).toBe("dologin");
                });

                it("Should count the regular rules, then the afterRecaptcha rules once recaptcha passed", () => {
                    rc.email = "test@gmail.com";

                    announce();

                    expect(allowPasses()).toBe([false, true]);
                    var afterCall = mockRateLimitService.$callLog().allow[2];
                    expect(afterCall.name).toBe("login.dologin");
                    expect(afterCall.ip).toBe("192.168.1.1");
                    expect(afterCall.context.email).toBe("test@gmail.com");
                    expect(interceptor.$never("relocate")).toBeTrue();
                    expect(mockAuditService.$never("audit")).toBeTrue();
                });

                it("Should reject a failed recaptcha with an audit, a generic alert and a relocate to /login", () => {
                    mockRecaptchaService.$("check", false);

                    announce();

                    expect(mockAuditService.$once("audit")).toBeTrue();
                    expect(mockAuditService.$callLog().getAuditObj[1].event).toBe("login.dologin");
                    expect(mockAuditService.$callLog().audit[1].detail).toBe("Failed Recaptcha Check");
                    expect(mockFlash.$once("put")).toBeTrue();
                    expect(mockFlash.$callLog().put[1].value.message).toBe("Invalid. Please try again.");
                    expect(interceptor.$once("relocate")).toBeTrue();
                    expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                });

                it("Should count only the regular rules when recaptcha fails", () => {
                    // afterRecaptcha rules are scoped to someone else's email - junk posts mustn't count toward them
                    mockRecaptchaService.$("check", false);

                    announce();

                    expect(allowPasses()).toBe([false]);
                });

                it("Should not use up the recaptcha result when the regular rules are over the limit", () => {
                    mockRateLimitService.$("allow", false);

                    announce();

                    expect(mockRecaptchaService.$never("check")).toBeTrue();
                    expect(allowPasses()).toBe([false]);
                    expect(mockFlash.$callLog().put[1].value.message).toBe("Too many attempts. Please try again later.");
                    expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                });

                it("Should relocate with the too many attempts alert when the afterRecaptcha rules are over the limit", () => {
                    mockRateLimitService.$("allow").$results(true, false);

                    announce();

                    expect(allowPasses()).toBe([false, true]);
                    expect(mockAuditService.$never("audit")).toBeTrue();
                    expect(mockFlash.$once("put")).toBeTrue();
                    expect(mockFlash.$callLog().put[1].value.message).toBe("Too many attempts. Please try again later.");
                    expect(interceptor.$once("relocate")).toBeTrue();
                    expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                });

                it("Should check recaptcha for a gated event with no rate limits configured", () => {
                    withLimits({});

                    announce();

                    expect(mockRecaptchaService.$once("check")).toBeTrue();
                    expect(mockRateLimitService.$never("allow")).toBeTrue();
                });

                it("Should skip recaptcha when an earlier interceptor already blocked the request", () => {
                    mockRequestContext.$("isNoExecution", true);

                    announce();

                    expect(mockRecaptchaService.$never("check")).toBeTrue();
                });
            });

            describe("postLogin", () => {
                it("Should reset the lowercased event with the request ip and rc", () => {
                    rc.email = "test@gmail.com";

                    announceLogin();

                    expect(mockRateLimitService.$once("reset")).toBeTrue();
                    var resetCall = mockRateLimitService.$callLog().reset[1];
                    expect(resetCall.name).toBe("login.dologin");
                    expect(resetCall.ip).toBe("192.168.1.1");
                    expect(resetCall.context.email).toBe("test@gmail.com");
                });
            });
        });
    }

}
