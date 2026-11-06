component extends="coldbox.system.Interceptor" {

    property name="rateLimits"       inject="coldbox:setting:rateLimits";
    property name="rateLimitService" inject="provider:services.rateLimit";
    property name="securityService"  inject="provider:services.security";
    property name="sessionService"   inject="provider:services.session";
    property name="useRateLimiter"   inject="coldbox:setting:useRateLimiter";

    /**
     * Rate limit requests on a per event basis on server side
     */
    function preProcess(event, data, buffer, rc, prc) {
        if(!useRateLimiter) {
            return;
        }

        var currEvent = lCase(event.getCurrentEvent());

        /**
         * Check if there's a rate limit in place for incoming handler.action
         */
        if(!rateLimits.keyExists(currEvent)) {
            return;
        }

        /**
         * For each rule, build the key and check
         */
        var limit = rateLimits[currEvent];
        var ip    = securityService.getRequestIP();

        var allowed = true;
        limit.rules.each((rule) => {
            var key = rateLimitService.buildKey(
                currentEvent = currEvent,
                by           = listToArray(rule.by),
                ip           = ip,
                context      = rc
            );

            if(!key.len()) {
                return;
            }

            var hitAllowed = rateLimitService.hit(
                key    = key,
                limit  = rule.limit,
                window = rule.window
            );

            if(!hitAllowed) allowed = false;
        });

        if(allowed) {
            return;
        }

        // Not allowed - too many requests
        var message = 'Too many attempts. Please try again later.';

        // Form posts go back to their page with an alert
        if(len(limit?.redirect ?: '')) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                message
            );
            relocate(uri = limit.redirect);
            return;
        }

        // AJAX endpoints get a json 429
        event.renderData(
            type = 'json',
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

}
