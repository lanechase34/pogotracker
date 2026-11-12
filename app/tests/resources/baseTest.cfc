component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

    this.loadColdBox   = true;
    this.unloadColdBox = false;

    function beforeAll() {
        /**
         * Re-wire everything
         */
        super.beforeAll();
        application.wirebox.autowire(this);

        // Check if there is a lingering session (from error)
        if(session.keyExists("mocktrainerid")) {
            getInstance("tests.resources.mocktrainer").delete();
        }

        globalFunctions = getInstance("tests.resources.globalFunctions");

        // Check if this test has helper functions
        var metadata = this.getMetaData();
        var testName = listToArray(metadata.fullname, ".");
        if(testname.len() == 5 && fileExists("tests/resources/#testname[4]#HelperFunctions.cfc")) {
            variables["#testname[4]#HelperFunctions"] = getInstance("tests.resources.#testname[4]#HelperFunctions");
        }
    }

    function afterAll() {
        super.afterAll();
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
                return createEmptyMock("coldbox.system.async.tasks.Future");
            });
    }

}
