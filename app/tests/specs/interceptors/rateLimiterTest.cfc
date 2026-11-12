component extends="coldbox.system.testing.BaseInterceptorTest" interceptor="interceptors.ratelimiter" {

    function beforeAll() {
        super.beforeAll();

        // Init interceptor
        super.setup();

        // Mock interceptor dependencies
        mockUtilService      = createEmptyMock(className = "models.services.util");
        mockFlash            = createEmptyMock(className = "coldbox.system.web.flash.SessionFlash");
        mockRateLimitService = createEmptyMock(className = "models.services.rateLimit");
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

    function run() {
        describe("RateLimiter Interceptor", () => {
            beforeEach(() => {
                setup();

                // Reset mocks before each test
                mockUtilService.$reset();
                mockUtilService.$("getRequestIP", "192.168.1.1");

                mockFlash.$reset();
                mockFlash.$("put");

                mockRateLimitService.$reset();
                mockRateLimitService.$("allow", true);
                mockRateLimitService.$("reset");

                // Inject dependencies
                interceptor.$property(propertyName = "utilService", mock = mockUtilService);
                interceptor.$property(propertyName = "flash", mock = mockFlash);
                interceptor.$property(propertyName = "rateLimitService", mock = mockRateLimitService);
                interceptor.$("relocate");
                withLimits({
                    "login.dologin": {redirect: "/login", rules: [{by: "ip", limit: 5, window: 15}]},
                    "home.contact" : {redirect: "", rules: [{by: "ip", limit: 5, window: 60}]}
                });

                // Mock event object
                mockRequestContext = createEmptyMock("coldbox.system.web.context.RequestContext");
                mockRequestContext.$("getCurrentEvent", "login.doLogin");
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
                expect(mockRequestContext.$never("renderData")).toBeTrue();
                expect(mockRequestContext.$never("noExecution")).toBeTrue();
            });

            it("Should relocate form posts with an alert when the limit is exceeded", () => {
                mockRateLimitService.$("allow", false);

                announce();

                expect(mockFlash.$once("put")).toBeTrue();
                expect(mockFlash.$callLog().put[1].name).toBe("alert");
                expect(mockFlash.$callLog().put[1].value.type).toBe("danger");
                expect(interceptor.$once("relocate")).toBeTrue();
                expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                expect(mockRequestContext.$never("renderData")).toBeTrue();
            });

            it("Should return a json 429 for ajax endpoints when the limit is exceeded", () => {
                mockRequestContext.$("getCurrentEvent", "home.contact");
                mockRateLimitService.$("allow", false);

                announce();

                expect(mockRequestContext.$once("renderData")).toBeTrue();
                var renderDataCall = mockRequestContext.$callLog().renderData[1];
                expect(renderDataCall.statusCode).toBe(429);
                expect(renderDataCall.type).toBe("json");
                expect(renderDataCall.data.success).toBeFalse();
                expect(mockRequestContext.$once("noExecution")).toBeTrue();
                expect(interceptor.$never("relocate")).toBeTrue();
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
