component extends="base" {

    property name="async"           inject="asyncManager@coldbox";
    property name="auditService"    inject="services.audit";
    property name="bugService"      inject="services.bug";
    property name="emailService"    inject="services.email";
    property name="securityService" inject="services.security";

    this.prehandler_only  = 'unauthorized,invalidHTTPMethod,notFound';
    this.posthandler_only = 'unauthorized,invalidHTTPMethod,notFound';

    /**
     * Clear the current orm session so we know the audit will work
     * Set up audit object
     */
    function preHandler(event, rc, prc, action, eventArguments) {
        ormClearSession(); // Clear the current session so we know the audit will work
        prc.auditInfo = auditService.getAuditObj(
            trainerid = session?.trainerid ?: -1,
            referer   = rc?.referer ?: '',
            event     = rc?.event ?: 'NA'
        );
    }

    /**
     * Fire async promise to audit
     */
    function postHandler(event, rc, prc, action, eventArguments) {
        if(!validate(target = prc.auditInfo, constraints = 'audit').hasErrors()) {
            async.newFuture(() => {
                auditService.audit(argumentCollection = prc.auditInfo);
            });
        }
    }

    /**
     * 403 Unauthorized events
     */
    function unauthorized(event, rc, prc) {
        prc.auditInfo.event  = left(prc?.unauthorizedEvent ?: event.getFullPath(), 250);
        prc.auditInfo.detail = 'Unauthorized Event';

        // Page metadata
        prc.title           = 'Access Denied';
        prc.metaDescription = 'You do not have permission to access this resource.';

        event.setHTTPHeader(statusCode = 403);
        event.setView(view = '/views/fragment/unauthorized', layout = 'basic');
    }

    /**
     * 405 Invalid HTTP Method
     */
    function invalidHTTPMethod(event, rc, prc) {
        prc.auditInfo.event  = left(event.getFullPath(), 250);
        prc.auditInfo.detail = 'Invalid HTTP Method #event.getHTTPMethod()#';

        if(securityService.isJsonRequest()) {
            prc.responseObj.statusCode = 405;
            prc.responseObj.message    = 'Method Not Allowed';
            renderJson(event = event, response = responseObj);
        }
        else {
            event.setHTTPHeader(statusCode = 405);
            event.setView(view = '/views/fragment/invalidmethod', layout = 'basic');
        }
    }

    /**
     * Exception handler
     */
    function onException(event, rc, prc) {
        prc.bugInfo = {
            ip       : securityService.getRequestIP(),
            event    : left(prc?.currentRoutedURL ?: event.getFullPath(), 250),
            message  : left(prc.exception.getMessage(), 250),
            stack    : prc.exception.getStackTrace(),
            trainerid: session?.trainerid ?: -1
        };

        /**
         * Audit and email bug
         */
        if(!validate(target = prc.bugInfo, constraints = 'bug').hasErrors()) {
            async.newFuture(() => {
                bugService.logBug(argumentCollection = prc.bugInfo);
            });
        }

        emailService.sendBug(prc.exception.getExceptionStruct(), rc);

        relocate(uri = '/exception', persistStruct = {details: prc.exception});
    }

    /**
     * Error output - use the exception template
     */
    function displayException(event, rc, prc) {
        // Page metadata
        prc.title           = 'Something Went Wrong';
        prc.metaDescription = 'An unexpected error occurred while processing your request.';

        event.setHTTPHeader(statusCode = 500);
        event.setView(view = '/views/fragment/exception').setLayout('basic');
    }

    /**
     * 404 Not Found
     */
    function notFound(event, rc, prc) {
        prc.auditInfo.event  = left(event.getFullPath(), 250);
        prc.auditInfo.detail = '404 Not Found';

        // Page metadata
        prc.title           = '404 - Page Not Found';
        prc.metaDescription = 'The page you are looking for does not exist.';

        event.setHTTPHeader(statusCode = 404);
        event.setView(view = '/views/fragment/404');
    }

}
