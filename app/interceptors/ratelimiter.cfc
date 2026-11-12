component extends="coldbox.system.Interceptor" {

    property name="rateLimits"       inject="coldbox:setting:rateLimits";
    property name="rateLimitService" inject="provider:services.rateLimit";
    property name="utilService"      inject="provider:services.util";

    /**
     * Rate limit requests on a per event basis on server side
     */
    function preProcess(event, data, buffer, rc, prc) {
        // Skip requests an earlier interceptor already rejected (e.g. guestOnly) - they shouldn't count
        if(event.isNoExecution()) {
            return;
        }

        var currEvent = lCase(event.getCurrentEvent());
        if(
            !rateLimits.keyExists(currEvent)
            || rateLimitService.allow(
                name    = currEvent,
                ip      = utilService.getRequestIP(),
                context = rc
            )
        ) {
            return;
        }

        var limit = rateLimits[currEvent];

        // Not allowed - too many requests
        var message = "Too many attempts. Please try again later.";

        // Form posts go back to their page with an alert
        if(len(limit?.redirect ?: "")) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : message
                }
            );
            relocate(uri = limit.redirect);
            return;
        }

        // AJAX endpoints get a json 429
        event.renderData(
            type = "json",
            data = {
                success   : false,
                message   : message,
                statusCode: 429
            },
            statusCode = 429
        );

        // Stop execution of the current request - the response is handled above
        event.noExecution();
    }

    /**
     * Clear the counters of rules marked resetOnSuccess after a successful login
     * Runs on cbauth's postLogin - login.dologin relocates on success, so postProcess never sees it
     */
    function postLogin(event, data, buffer, rc, prc) {
        rateLimitService.reset(
            name    = lCase(event.getCurrentEvent()),
            ip      = utilService.getRequestIP(),
            context = rc
        );
    }

}
