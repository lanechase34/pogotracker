component extends="coldbox.system.Interceptor" {

    property name="async"       inject="asyncManager@coldbox";
    property name="concurrency" inject="coldbox:setting:concurrency";

    // Request Log Settings
    property name="REQUEST_LOG_SETTINGS" inject="coldbox:setting:requestLog";
    property name="LOG_REQUESTS"         inject="coldbox:setting:logRequests";

    property name="URLPATH_LENGTH" type="numeric";
    property name="METHOD_LENGTH"  type="numeric";
    property name="AGENT_LENGTH"   type="numeric";
    property name="REFERER_LENGTH" type="numeric";

    // Slow Request Settings
    property name="SLOW_REQUEST_THRESHOLD";
    property name="MAX_SLOW_REQUESTS";

    /**
     * Set configuration based on REQUEST_LOG_SETTINGS struct
     */
    function configure() {
        URLPATH_LENGTH         = REQUEST_LOG_SETTINGS.urlpathLength;
        METHOD_LENGTH          = REQUEST_LOG_SETTINGS.methodLength;
        AGENT_LENGTH           = REQUEST_LOG_SETTINGS.agentLength;
        REFERER_LENGTH         = REQUEST_LOG_SETTINGS.refererLength;
        SLOW_REQUEST_THRESHOLD = REQUEST_LOG_SETTINGS.slowRequestThreshold;
        MAX_SLOW_REQUESTS      = REQUEST_LOG_SETTINGS.maxSlowRequests;
    }

    /**
     * Set up request audit object
     */
    function preProcess(event, data, buffer, rc, prc) {
        prc.requestAudit = {
            ip        : getInstance('services.security').getRequestIP(),
            urlpath   : left(event.getFullPath(), URLPATH_LENGTH),
            method    : left(event.getHTTPMethod(), METHOD_LENGTH),
            start     : getTickCount(),
            agent     : left(getInstance('services.security').getUserAgent(), AGENT_LENGTH),
            referer   : left(getInstance('services.security').getReferer(), REFERER_LENGTH),
            response  : '',
            statuscode: -1,
            trainerid : session?.trainerid ?: -1
        };
    }

    /**
     * Add remaining details and
     * Fire async function to audit the request
     */
    function postProcess(event, rc, prc) {
        var skip               = false;
        prc.requestAudit.delta = getTickCount() - prc.requestAudit.start;

        // If this was a json request
        if(getInstance('services.security').isJsonRequest()) {
            prc.requestAudit.statuscode = prc?.responseObj?.statuscode ?: -1;
            prc.requestAudit.response   = serializeJSON(prc?.responseObj ?: {});
        }
        // Get as much information about the layout, view, and data returned
        else {
            prc.requestAudit.statuscode = prc?.statuscode ?: event?.getStatusCode() ?: -1;
            prc.requestAudit.response   = serializeJSON({'layout': event.getCurrentLayout(), 'view': event.getCurrentView()});

            // If there's no layout or no view, this is not a valid request (relocated) so skip logging
            if(!event.getCurrentLayout().len() && !event.getCurrentView().len()) skip = true;
        }

        if(LOG_REQUESTS && !skip) {
            var auditData = duplicate(prc.requestAudit);
            async.newFuture(() => {
                getInstance('services.audit').logRequest(argumentCollection = auditData);
            });
        }

        /**
         * If this was a slow request, add it up to a max of MAX_SLOW_REQUESTS for display
         */
        if(prc.requestAudit.delta > SLOW_REQUEST_THRESHOLD) {
            var timestamp = now();

            lock name="slowRequestsLock" timeout="5" type="exclusive" throwOnTimeout=false {
                // Delete requests older than 24 hours
                var oneHourAgo           = dateAdd('h', -24, timestamp);
                concurrency.slowRequests = concurrency.slowRequests.filter((req) => {
                    return req.time > oneHourAgo;
                });

                // Add new request
                concurrency.slowRequests.append({
                    urlpath  : prc.requestAudit.urlpath,
                    method   : prc.requestAudit.method,
                    delta    : prc.requestAudit.delta,
                    trainerid: prc.requestAudit.trainerid,
                    time     : now()
                });

                // Enforces max array size
                while(concurrency.slowRequests.len() > MAX_SLOW_REQUESTS) {
                    concurrency.slowRequests.shift();
                }
            }
        }
    }

}
