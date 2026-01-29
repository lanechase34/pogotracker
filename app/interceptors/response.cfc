component extends="coldbox.system.Interceptor" {

    function configure() {
    }

    /**
     * Inject a struct for the response data (used by json requests)
     *
     * Key @prc.responseObj
     */
    function preProcess(event, data, buffer, rc, prc) {
        prc.responseObj = {
            success   : false,
            message   : '',
            statusCode: 500
        };
    }

}
