component extends="coldbox.system.testing.BaseInterceptorTest" interceptor="interceptors.ratelimiter" {

    function beforeAll() {
        super.beforeAll();

        // Init interceptor
        super.setup();

        // Mock interceptor dependencies
        mockSecurityService  = createEmptyMock(className = "models.services.security");
        mockSessionService   = createEmptyMock(className = "models.services.session");
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
                mockSecurityService.$reset();
                mockSecurityService.$("getRequestIP", "192.168.1.1");

                mockSessionService.$reset();
                mockSessionService.$("setAlert");

                mockRateLimitService.$reset();
                mockRateLimitService.$("buildKey", "mock:key");
                mockRateLimitService.$("hit", true);

                // Inject dependencies
                interceptor.$property(propertyName = "securityService", mock = mockSecurityService);
                interceptor.$property(propertyName = "sessionService", mock = mockSessionService);
                interceptor.$property(propertyName = "rateLimitService", mock = mockRateLimitService);
                interceptor.$property(propertyName = "useRateLimiter", mock = true);
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

                rc  = {};
                prc = {};
            });

            it("Can be created", () => {
                expect(interceptor).toBeComponent();
            });

            it("Should skip rate limiting when useRateLimiter is false", () => {
                interceptor.$property(propertyName = "useRateLimiter", mock = false);

                announce();

                expect(mockRequestContext.$never("getCurrentEvent")).toBeTrue();
                expect(mockRateLimitService.$never("hit")).toBeTrue();
            });

            it("Should skip rate limiting when current event has no rate limit configured", () => {
                mockRequestContext.$("getCurrentEvent", "pokedex.myPokedex");

                announce();

                expect(mockSecurityService.$never("getRequestIP")).toBeTrue();
                expect(mockRateLimitService.$never("hit")).toBeTrue();
            });

            it("Should lowercase the event and use the request ip", () => {
                announce();

                var buildKeyCall = mockRateLimitService.$callLog().buildKey[1];
                expect(buildKeyCall.currentEvent).toBe("login.dologin");
                expect(buildKeyCall.ip).toBe("192.168.1.1");
            });

            it("Should build the key from the rule fields and the rc", () => {
                withLimits({"login.dologin": {redirect: "/login", rules: [{by: "ip,email", limit: 5, window: 15}]}});
                rc.email = "test@gmail.com";

                announce();

                var buildKeyCall = mockRateLimitService.$callLog().buildKey[1];
                expect(buildKeyCall.by).toBe(["ip", "email"]);
                expect(buildKeyCall.context.email).toBe("test@gmail.com");
            });

            it("Should skip a rule when its key cannot be built", () => {
                mockRateLimitService.$("buildKey", "");

                announce();

                expect(mockRateLimitService.$never("hit")).toBeTrue();
                expect(interceptor.$never("relocate")).toBeTrue();
            });

            it("Should count every rule configured for the event", () => {
                withLimits({
                    "login.dologin": {
                        redirect: "/login",
                        rules   : [
                            {by: "ip", limit: 20, window: 15},
                            {by: "ip,email", limit: 5, window: 15},
                            {by: "email", limit: 10, window: 30}
                        ]
                    }
                });
                mockRateLimitService.$("buildKey").$results("key:ip", "key:ip+email", "key:email");

                announce();

                var hitCalls = mockRateLimitService.$callLog().hit;
                expect(hitCalls.map((call) => call.key)).toBe(["key:ip", "key:ip+email", "key:email"]);
                expect(hitCalls.map((call) => call.limit)).toBe([20, 5, 10]);
                expect(hitCalls.map((call) => call.window)).toBe([15, 15, 30]);
            });

            it("Should allow the request when the limit is not exceeded", () => {
                announce();

                expect(mockRateLimitService.$once("hit")).toBeTrue();
                expect(interceptor.$never("relocate")).toBeTrue();
                expect(mockRequestContext.$never("renderData")).toBeTrue();
                expect(mockRequestContext.$never("noExecution")).toBeTrue();
            });

            it("Should relocate form posts with an alert when the limit is exceeded", () => {
                mockRateLimitService.$("hit", false);

                announce();

                expect(mockSessionService.$once("setAlert")).toBeTrue();
                expect(mockSessionService.$callLog().setAlert[1][1]).toBe("danger");
                expect(interceptor.$once("relocate")).toBeTrue();
                expect(interceptor.$callLog().relocate[1].uri).toBe("/login");
                expect(mockRequestContext.$never("renderData")).toBeTrue();
            });

            it("Should return a json 429 for ajax endpoints when the limit is exceeded", () => {
                mockRequestContext.$("getCurrentEvent", "home.contact");
                mockRateLimitService.$("hit", false);

                announce();

                expect(mockRequestContext.$once("renderData")).toBeTrue();
                var renderDataCall = mockRequestContext.$callLog().renderData[1];
                expect(renderDataCall.statusCode).toBe(429);
                expect(renderDataCall.type).toBe("json");
                expect(renderDataCall.data.success).toBeFalse();
                expect(mockRequestContext.$once("noExecution")).toBeTrue();
                expect(interceptor.$never("relocate")).toBeTrue();
            });

            it("Should block when any one rule is exceeded and still count every rule", () => {
                withLimits({
                    "login.dologin": {
                        redirect: "/login",
                        rules   : [
                            {by: "ip", limit: 20, window: 15},
                            {by: "ip,email", limit: 5, window: 15}
                        ]
                    }
                });
                mockRateLimitService.$("hit").$results(true, false);

                announce();

                expect(mockRateLimitService.$count("hit")).toBe(2);
                expect(interceptor.$once("relocate")).toBeTrue();
            });
        });
    }

}
