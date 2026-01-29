component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

    function beforeAll() {
        structDelete(application, 'cbController');
        structDelete(application, 'wirebox');
        super.beforeAll();
        application.wirebox.autowire(this);

        // Check if there is a lingering session (from error)
        if(session.keyExists('mocktrainerid')) getInstance('tests.resources.mocktrainer').delete();

        globalFunctions = getInstance('tests.resources.globalFunctions');

        // Check if this test has helper functions
        var metadata = this.getMetaData();
        var testName = listToArray(metadata.fullname, '.');
        if(testname.len() == 5 && fileExists('tests/resources/#testname[4]#HelperFunctions.cfc')) {
            variables['#testname[4]#HelperFunctions'] = getInstance('tests.resources.#testname[4]#HelperFunctions');
        }
    }

    function afterAll() {
        super.afterAll();
    }

}
