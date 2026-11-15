component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();
    }

    function afterAll() {
        restoreBackgroundLogs();
        super.afterAll();
    }

    function run() {
        describe("Default Behaviors", () => {
            beforeEach(() => {
                setup(); // Setup as a new ColdBox request
            });

            it("Ping database", () => {
                var sysdate = queryExecute("select current_timestamp").current_timestamp;
                expect(dateDiff("s", now(), sysdate)).toBeBetween(0, 5);
            });

            it("Request start handler sets the request variables", () => {
                var event = execute("main.onRequestStart");
                expect(event.getPrivateValue("currEvent")).toBe("main.onrequeststart");
                expect(event.getPrivateValue("canonicalURL")).toBe("#getController().getSetting("domain")#/");
                expect(event.getPrivateValue("title")).toBe("");
                expect(event.getPrivateValue("metaDescription")).toBe("");
            });

            it("Can handle exceptions", () => {
                var chase;
                try {
                    var test = 1 / 0;
                }
                catch(any e) {
                    chase = e;
                }

                // You need to create an exception bean first and place it on the request context FIRST as a setup.
                var exceptionBean = createMock("coldbox.system.web.context.ExceptionBean").init(
                    errorStruct  = chase,
                    extraMessage = "My unit test exception",
                    extraInfo    = "Any extra info, simple or complex"
                );

                prepareMock(getRequestContext())
                    .setValue(
                        name    = "exception",
                        value   = exceptionBean,
                        private = true
                    )
                    .setValue(
                        name    = "currentRoutedURL",
                        value   = "test.defaultTest",
                        private = true
                    )
                    .$("setHTTPHeader");

                // Verify bug is successfully logged
                var bugCountBefore = globalFunctions.countBugLog();

                execute(event = "error.onException"); // logs bug and emails bug
                var event2 = execute(event = "error.displayException", renderResults = true); // generic error display only
                expect(event2.getRenderedContent()).toInclude("Something Went Wrong");

                var bugCountAfter = globalFunctions.countBugLog();
                expect(bugCountAfter - bugCountBefore).toBe(1);
            });
        });
    }

}
