component extends="coldbox.system.testing.BaseInterceptorTest" interceptor="interceptors.logRequest" {

    function beforeAll() {
        super.beforeAll();

        // Mock interceptor dependencies
        mockAuditService = createEmptyMock(className = "models.services.audit");
        mockUtilService  = createEmptyMock(className = "models.services.util");
        mockConcurrency  = {slowRequests: []};

        // Mock audit settings - copied fresh into mockAuditSettings before each spec so overrides don't leak
        defaultAuditSettings = {slowRequestThreshold: 1000, maxSlowRequests: 25};
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Run preProcess on the interceptor with the shared mocks
     */
    private function announcePreProcess() {
        interceptor.preProcess(
            event  = mockRequestContext,
            data   = {},
            buffer = "",
            rc     = rc,
            prc    = prc
        );
    }

    /**
     * Run postProcess on the interceptor with the shared mocks
     */
    private function announcePostProcess() {
        interceptor.postProcess(event = mockRequestContext, rc = rc, prc = prc);
    }

    /**
     * Fill the slow request log with entryCount entries
     *
     * @entryCount Number of entries to add
     * @prefix     urlpath prefix, suffixed with the entry number
     * @time       Timestamp of every entry
     */
    private function fillSlowRequests(
        required numeric entryCount,
        string prefix = "/api/old",
        date time     = now()
    ) {
        for(var i = 1; i <= arguments.entryCount; i++) {
            mockConcurrency.slowRequests.append({
                urlpath  : "#arguments.prefix##i#",
                method   : "GET",
                delta    : 1100,
                trainerid: i,
                time     : arguments.time
            });
        }
    }

    function run() {
        describe("RequestAudit Interceptor", () => {
            beforeEach(() => {
                setup();

                // Reset mocks before each test
                mockAuditService.$reset();
                mockUtilService.$reset();

                // Reset concurrency struct and settings
                mockConcurrency.slowRequests = [];
                mockAuditSettings            = duplicate(defaultAuditSettings);

                // Inject dependencies
                interceptor.$property(propertyName = "concurrency", mock = mockConcurrency);
                interceptor.$property(propertyName = "REQUEST_LOG_SETTINGS", mock = mockAuditSettings);
                interceptor.$property(propertyName = "LOG_REQUESTS", mock = true);

                interceptor.$property(propertyName = "auditService", mock = mockAuditService);
                interceptor.$property(propertyName = "utilService", mock = mockUtilService);

                // Mock event object
                mockRequestContext = createEmptyMock("coldbox.system.web.context.RequestContext");

                rc  = {};
                prc = {};

                // Setup default mock responses
                mockUtilService.$("getRequestIP", "192.168.1.100");
                mockUtilService.$("getUserAgent", "Mozilla/5.0 Test Browser");
                mockUtilService.$("getReferer", "https://pogotracker.app");
                mockUtilService.$("isJsonRequest", true);
                mockRequestContext.$("getFullPath", "/api/v1/users");
                mockRequestContext.$("getHTTPMethod", "GET");
                mockAuditService.$("logRequest");
            });

            describe("configure()", () => {
                it("Should configure all settings in one call", () => {
                    var customSettings = {slowRequestThreshold: 500, maxSlowRequests: 10};
                    interceptor.$property(propertyName = "REQUEST_LOG_SETTINGS", mock = customSettings);

                    interceptor.configure();

                    expect(interceptor.$getProperty("SLOW_REQUEST_THRESHOLD")).toBe(500);
                    expect(interceptor.$getProperty("MAX_SLOW_REQUESTS")).toBe(10);
                });
            });

            describe("preProcess()", () => {
                beforeEach(() => {
                    interceptor.configure();
                });

                it("Should build prc.requestAudit from the request", () => {
                    var beforeTick = getTickCount();
                    announcePreProcess();
                    var afterTick = getTickCount();

                    expect(prc).toHaveKey("requestAudit");
                    expect(prc.requestAudit).toBeStruct();
                    expect(prc.requestAudit).toHaveKey("ip");
                    expect(prc.requestAudit).toHaveKey("urlpath");
                    expect(prc.requestAudit).toHaveKey("method");
                    expect(prc.requestAudit).toHaveKey("start");
                    expect(prc.requestAudit).toHaveKey("agent");
                    expect(prc.requestAudit).toHaveKey("referer");
                    expect(prc.requestAudit).toHaveKey("statuscode");
                    expect(prc.requestAudit).toHaveKey("trainerid");

                    expect(mockUtilService.$once("getRequestIP")).toBeTrue();
                    expect(prc.requestAudit.ip).toBe("192.168.1.100");

                    expect(mockRequestContext.$once("getFullPath")).toBeTrue();
                    expect(prc.requestAudit.urlpath).toBe("/api/v1/users");

                    expect(mockRequestContext.$once("getHTTPMethod")).toBeTrue();
                    expect(prc.requestAudit.method).toBe("GET");

                    expect(prc.requestAudit.start).toBeGTE(beforeTick);
                    expect(prc.requestAudit.start).toBeLTE(afterTick);

                    expect(mockUtilService.$once("getUserAgent")).toBeTrue();
                    expect(prc.requestAudit.agent).toBe("Mozilla/5.0 Test Browser");

                    expect(mockUtilService.$once("getReferer")).toBeTrue();
                    expect(prc.requestAudit.referer).toBe("https://pogotracker.app");

                    expect(prc.requestAudit.statuscode).toBe(-1);
                    expect(prc.requestAudit.trainerid).toBe(-1);
                });

                it("Should use an empty referer when the request has none", () => {
                    mockUtilService.$("getReferer", "");

                    announcePreProcess();

                    expect(mockUtilService.$once("getReferer")).toBeTrue();
                    expect(prc.requestAudit.referer).toBe("");
                });
            });

            describe("postProcess()", () => {
                beforeEach(() => {
                    interceptor.configure();

                    // Setup prc.requestAudit as if preProcess ran
                    prc.requestAudit = {
                        ip        : "192.168.1.100",
                        urlpath   : "/api/test",
                        method    : "POST",
                        start     : getTickCount() - 500,
                        agent     : "Test Agent",
                        referer   : "https://chaselane.dev",
                        statuscode: -1,
                        trainerid : 123
                    };

                    prc.responseObj = {
                        success   : false,
                        message   : "",
                        statusCode: 210
                    };
                });

                it("Should do nothing when preProcess never ran (the request failed before it)", () => {
                    prc.delete("requestAudit");

                    announcePostProcess();

                    expect(prc).notToHaveKey("requestAudit");
                    expect(mockAuditService.$never("logRequest")).toBeTrue();
                });

                it("Should calculate delta from start time", () => {
                    announcePostProcess();

                    expect(prc.requestAudit).toHaveKey("delta");
                    expect(prc.requestAudit.delta).toBeGTE(0);
                    expect(prc.requestAudit.delta).toBeNumeric();
                });

                describe("JSON Request", () => {
                    beforeEach(() => {
                        mockUtilService.$("isJsonRequest", true);
                    });

                    it("Should set statuscode from prc.responseObj", () => {
                        announcePostProcess();

                        expect(prc.requestAudit.statuscode).toBe(210);
                    });

                    it("Should use -1 for statuscode and an empty response when responseObj does not exist", () => {
                        structDelete(prc, "responseObj");

                        announcePostProcess();

                        expect(prc.requestAudit.statuscode).toBe(-1);
                        expect(prc.requestAudit.response).toBe("{}");
                    });

                    it("Should use the entire serialized responseObj for response", () => {
                        prc.responseObj.success = true;
                        prc.responseObj.message = "this will be serialized";

                        announcePostProcess();

                        expect(prc.requestAudit.response).toInclude("""success"":true");
                        expect(prc.requestAudit.response).toInclude("""message"":""this will be serialized""");
                    });
                });

                describe("Coldbox Request", () => {
                    beforeEach(() => {
                        mockUtilService.$("isJsonRequest", false);

                        mockRequestContext.$("getStatusCode");
                        mockRequestContext.$("getCurrentLayout", "");
                        mockRequestContext.$("getCurrentView", "");
                    });

                    it("Should set statuscode from prc.statuscode", () => {
                        prc.statuscode = 87;

                        announcePostProcess();

                        expect(prc.requestAudit.statuscode).toBe(87);
                    });

                    it("Should set statuscode from event.getStatusCode() if prc.statuscode does not exist", () => {
                        mockRequestContext.$("getStatusCode", 71);

                        announcePostProcess();

                        expect(prc.requestAudit.statuscode).toBe(71);
                    });

                    it("Should use -1 if prc.statuscode and event.getStatusCode() do not exist", () => {
                        announcePostProcess();

                        expect(prc.requestAudit.statuscode).toBe(-1);
                    });

                    it("Should set the response to serialize the current layout and view", () => {
                        mockRequestContext.$("getCurrentLayout", "mockLayout");
                        mockRequestContext.$("getCurrentView", "mockView");

                        announcePostProcess();

                        expect(prc.requestAudit.response).toInclude("""layout"":""mockLayout""");
                        expect(prc.requestAudit.response).toInclude("""view"":""mockView""");
                    });

                    it("Should skip audit if both current layout and current view are empty", () => {
                        announcePostProcess();

                        expect(mockAuditService.$never("logRequest")).toBeTrue();
                    });
                });

                it("Should call auditService.logRequest() when LOG_REQUESTS is true", () => {
                    announcePostProcess();

                    expect(mockAuditService.$once("logRequest")).toBeTrue();
                });

                it("Should not call auditService.logRequest() when LOG_REQUESTS is false", () => {
                    interceptor.$property(propertyName = "LOG_REQUESTS", mock = false);

                    announcePostProcess();

                    expect(mockAuditService.$never("logRequest")).toBeTrue();
                });

                it("Should not add to slowRequests when delta equals threshold", () => {
                    // Pin the clock - a real tick between start and postProcess would push the delta past 1000
                    prc.requestAudit.start = 0;
                    interceptor.$("tick", 1000);

                    announcePostProcess();

                    expect(prc.requestAudit.delta).toBe(1000);
                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(0);
                });

                it("Should add the request details to slowRequests when delta exceeds threshold", () => {
                    prc.requestAudit.start = getTickCount() - 1500;

                    announcePostProcess();

                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(1);
                    var slowReq = mockConcurrency.slowRequests[1];
                    expect(slowReq.urlpath).toBe("/api/test");
                    expect(slowReq.method).toBe("POST");
                    expect(slowReq.delta).toBeGT(1000);
                    expect(slowReq.trainerid).toBe(123);
                    expect(isDate(slowReq.time)).toBeTrue();
                });

                it("Should respect custom SLOW_REQUEST_THRESHOLD setting", () => {
                    mockAuditSettings.slowRequestThreshold = 500;
                    interceptor.configure();
                    prc.requestAudit.start = getTickCount() - 600;

                    announcePostProcess();

                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(1);
                });

                it("Should filter out requests older than 24 hour", () => {
                    fillSlowRequests(entryCount = 2, time = dateAdd("h", -26, now()));
                    mockConcurrency.slowRequests.append({
                        urlpath  : "/recent",
                        method   : "GET",
                        delta    : 1300,
                        trainerid: 3,
                        time     : dateAdd("n", -30, now())
                    });
                    prc.requestAudit.start = getTickCount() - 1500;

                    announcePostProcess();

                    // recent + new
                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(2);
                    expect(mockConcurrency.slowRequests[1].urlpath).toBe("/recent");
                    expect(mockConcurrency.slowRequests[2].urlpath).toBe("/api/test");
                });

                it("Should drop the oldest entry when the log is at MAX_SLOW_REQUESTS", () => {
                    fillSlowRequests(entryCount = 25);
                    prc.requestAudit.start = getTickCount() - 1500;

                    announcePostProcess();

                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(25);
                    expect(mockConcurrency.slowRequests[1].urlpath).toBe("/api/old2");
                    expect(mockConcurrency.slowRequests[25].urlpath).toBe("/api/test");
                });

                it("Should trim multiple entries down to a custom MAX_SLOW_REQUESTS", () => {
                    mockAuditSettings.maxSlowRequests = 5;
                    interceptor.configure();

                    // 2 over the limit - the 3 oldest go to make room for the new one
                    fillSlowRequests(entryCount = 7);
                    prc.requestAudit.start = getTickCount() - 1500;

                    announcePostProcess();

                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(5);
                    expect(mockConcurrency.slowRequests[1].urlpath).toBe("/api/old4");
                    expect(mockConcurrency.slowRequests[5].urlpath).toBe("/api/test");
                });

                it("Should handle both filtering and size enforcement together", () => {
                    fillSlowRequests(
                        entryCount = 20,
                        prefix     = "/old",
                        time       = dateAdd("h", -26, now())
                    );
                    fillSlowRequests(entryCount = 10, prefix = "/recent");
                    prc.requestAudit.start = getTickCount() - 1500;

                    announcePostProcess();

                    // 10 recent + 1 new
                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(11);
                    expect(mockConcurrency.slowRequests[11].urlpath).toBe("/api/test");
                });
            });

            describe("Integration Tests", () => {
                beforeEach(() => {
                    interceptor.configure();
                });

                it("Should handle complete request lifecycle with slow request", () => {
                    prc.oCurrentUser = createStub().$("getId", 456);

                    announcePreProcess();
                    prc.requestAudit.start = getTickCount() - 2000;
                    announcePostProcess();

                    expect(prc.requestAudit.trainerid).toBe(456);
                    expect(prc.requestAudit.delta).toBeGT(1000);
                    expect(mockAuditService.$once("logRequest")).toBeTrue();
                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(1);
                });

                it("Should handle complete request lifecycle with fast request", () => {
                    prc.oCurrentUser = createStub().$("getId", 789);

                    announcePreProcess();
                    prc.requestAudit.start = getTickCount() - 100;
                    announcePostProcess();

                    expect(prc.requestAudit.trainerid).toBe(789);
                    expect(prc.requestAudit.delta).toBeLT(1000);
                    expect(mockAuditService.$once("logRequest")).toBeTrue();
                    expect(arrayLen(mockConcurrency.slowRequests)).toBe(0);
                });
            });
        });
    }

}
