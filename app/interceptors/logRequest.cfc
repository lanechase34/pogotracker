component extends="baseInterceptor" {

    property name="concurrency" inject="coldbox:setting:concurrency";

    property name="auditService" inject="provider:services.audit";
    property name="utilService"  inject="provider:services.util";

    // Request Log Settings
    property name="REQUEST_LOG_SETTINGS" inject="coldbox:setting:requestLog";
    property name="LOG_REQUESTS"         inject="coldbox:setting:logRequests";

    // Slow Request Settings
    property name="SLOW_REQUEST_THRESHOLD";
    property name="MAX_SLOW_REQUESTS";

    /**
     * Set configuration based on REQUEST_LOG_SETTINGS struct
     */
    function configure() {
        SLOW_REQUEST_THRESHOLD = REQUEST_LOG_SETTINGS.slowRequestThreshold;
        MAX_SLOW_REQUESTS      = REQUEST_LOG_SETTINGS.maxSlowRequests;
    }

    /**
     * Set up request audit object
     */
    function preProcess(event, data, buffer, rc, prc) {
        prc.requestAudit = {
            ip        : utilService.getRequestIP(),
            urlpath   : event.getFullPath(),
            method    : event.getHTTPMethod(),
            start     : tick(),
            agent     : utilService.getUserAgent(),
            referer   : utilService.getReferer(),
            response  : "",
            statuscode: -1,
            trainerid : (prc?.oCurrentUser?.getId() ?: -1)
        };
    }

    /**
     * Add remaining details and
     * Log the request
     */
    function postProcess(event, rc, prc) {
        // preProcess never ran - the request failed before reaching it (onRequestCapture or an earlier preProcess)
        // and error.onException's relocate is announcing postProcess. Nothing to log, and throwing here would hide the real error
        if(!prc.keyExists("requestAudit")) {
            return;
        }

        var skip               = false;
        prc.requestAudit.delta = tick() - prc.requestAudit.start;

        // If this was a json request
        if(utilService.isJsonRequest()) {
            prc.requestAudit.statuscode = prc?.responseObj?.statuscode ?: -1;
            prc.requestAudit.response   = serializeJSON(prc?.responseObj ?: {});
        }
        // Get as much information about the layout, view, and data returned
        else {
            prc.requestAudit.statuscode = prc?.statuscode ?: event?.getStatusCode() ?: -1;
            prc.requestAudit.response   = serializeJSON({"layout": event.getCurrentLayout(), "view": event.getCurrentView()});

            // If there's no layout or no view, this is not a valid request (relocated) so skip logging
            if(!event.getCurrentLayout().len() && !event.getCurrentView().len()) skip = true;
        }

        if(LOG_REQUESTS && !skip) {
            auditService.logRequest(argumentCollection = prc.requestAudit);
        }

        /**
         * If this was a slow request, add it up to a max of MAX_SLOW_REQUESTS for display
         */
        if(prc.requestAudit.delta > SLOW_REQUEST_THRESHOLD) {
            var timestamp = now();

            lock name="slowRequestsLock" timeout="5" type="exclusive" throwOnTimeout=false {
                // Delete requests older than 24 hours
                var cutoff               = dateAdd("h", -24, timestamp);
                concurrency.slowRequests = concurrency.slowRequests.filter((req) => {
                    return req.time > cutoff;
                });

                // Add new request
                concurrency.slowRequests.append({
                    urlpath  : prc.requestAudit.urlpath,
                    method   : prc.requestAudit.method,
                    delta    : prc.requestAudit.delta,
                    trainerid: prc.requestAudit.trainerid,
                    time     : timestamp
                });

                // Enforces max array size
                while(concurrency.slowRequests.len() > MAX_SLOW_REQUESTS) {
                    concurrency.slowRequests.shift();
                }
            }
        }
    }

    /**
     * Current tick count - wrapped so tests can pin the clock
     */
    private numeric function tick() {
        return getTickCount();
    }

}
