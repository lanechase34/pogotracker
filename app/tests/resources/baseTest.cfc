component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

    this.loadColdBox   = true;
    this.unloadColdBox = false;

    public void function beforeAll() {
        /**
         * Re-wire everything
         */
        super.beforeAll();
        stubRoutingCGI();
        application.wirebox.autowire(this);

        // Check if there is a lingering session (from error)
        if(session.keyExists("mocktrainerid")) {
            getInstance("tests.resources.mockTrainer").deleteTrainer();
        }

        globalFunctions = getInstance("tests.resources.globalFunctions");
        testData        = getInstance("tests.resources.testData");

        // Check if this test has helper functions
        var metadata = this.getMetaData();
        var testName = listToArray(metadata.fullname, ".");
        if(testname.len() == 5 && fileExists("tests/resources/#testname[4]#HelperFunctions.cfc")) {
            variables["#testname[4]#HelperFunctions"] = getInstance("tests.resources.#testname[4]#HelperFunctions");
        }
    }

    public void function afterAll() {
        super.afterAll();
    }

    /**
     * Stand in for MockBox on the routing service's getCGIElement - the CGI values every test request is routed by
     *
     * - BaseTestCase.execute() mocks getCGIElement afresh on every get()/post()/..., through MockBox: each $() writes,
     *   includes and deletes a generated stub file, and each call hashes its arguments - the request context's whole
     *   metadata serialized
     * - execute() only uses the $("getCGIElement").$args(element, event).$results(value) chain, and the routing service
     *   only asks for path_info, script_name and server_name - so the stand-in keeps the last value set for each
     * - Marking the service as already mocked (its mockbox key) makes prepareMock() hand it back as it is
     * - Re-check execute() and RoutingService's getCGIElement calls on every ColdBox or TestBox upgrade
     */
    private void function stubRoutingCGI() {
        var routingService = getController().getRoutingService();
        var state          = {values: {}, element: ""};

        new coldbox.system.core.dynamic.MixerUtil().start(routingService);
        routingService.mockbox = true;
        routingService.injectMixin("$", (required string method) => {
            if(arguments.method != "getCGIElement") {
                throw(
                    type    = "baseTest.UnsupportedMock",
                    message = "stubRoutingCGI() only stands in for getCGIElement, not #arguments.method#"
                );
            }
            return routingService;
        });
        routingService.injectMixin("$args", (required string element) => {
            state.element = arguments.element;
            return routingService;
        });
        routingService.injectMixin("$results", (required any value) => {
            state.values[state.element] = arguments.value;
            return routingService;
        });
        routingService.injectMixin("getCGIElement", (required string cgiElement, any event) => {
            return state.values[arguments.cgiElement] ?: "";
        });
    }

    /**
     * An AsyncManager whose newFuture runs the closure right away, so fire and forget work is done before the next line
     * Swap it in with $property(propertyName = "async", ...) and put the original back when the spec is done
     */
    public any function syncAsync() {
        return createEmptyMock("coldbox.system.async.AsyncManager")
            .$("newFuture")
            .$callback((value) => {
                arguments.value();
                return createEmptyMock("coldbox.system.async.tasks.Future").$("onException");
            });
    }

    /**
     * Run the service's fire and forget work inline while fn runs, then put its real AsyncManager back
     *
     * @service service whose async property is swapped
     * @fn      work to run with the swap in place, its result is returned
     */
    public any function withSyncAsync(required any service, required any fn) {
        var mockedService = prepareMock(arguments.service);
        var originalAsync = mockedService.$getProperty("async");
        mockedService.$property(propertyName = "async", mock = syncAsync());
        try {
            return arguments.fn();
        }
        finally {
            mockedService.$property(propertyName = "async", mock = originalAsync);
        }
    }

    /**
     * Run the audit, bug and request log inserts inline for the whole spec, so rows can be read right after the action that writes them
     * They go through utilService.runInBackground - call in beforeAll and pair with restoreBackgroundLogs() in afterAll
     */
    public void function inlineBackgroundLogs() {
        var utilService           = prepareMock(getInstance("services.util"));
        variables.backgroundAsync = utilService.$getProperty("async");
        utilService.$property(propertyName = "async", mock = syncAsync());
    }

    /**
     * Put the real AsyncManager back after inlineBackgroundLogs()
     */
    public void function restoreBackgroundLogs() {
        if(!variables.keyExists("backgroundAsync")) {
            return;
        }
        prepareMock(getInstance("services.util")).$property(propertyName = "async", mock = variables.backgroundAsync);
    }

}
