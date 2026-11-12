component extends="base" {

    property name="async"        inject="asyncManager@coldbox";
    property name="auditService" inject="services.audit";
    property name="bugService"   inject="services.bug";
    property name="emailService" inject="services.email";
    property name="utilService"  inject="services.util";

    this.prehandler_only  = "unauthorized,invalidHTTPMethod,notFound";
    this.posthandler_only = "unauthorized,invalidHTTPMethod,notFound";

    /**
     * Clear the current orm session so we know the audit will work
     * Set up audit object
     */
    function preHandler(event, rc, prc, action, eventArguments) {
        ormClearSession(); // Clear the current session so we know the audit will work
        prc.auditInfo = auditService.getAuditObj(
            trainerid = (prc?.oCurrentUser?.getId() ?: -1),
            referer   = rc?.referer ?: "",
            event     = rc?.event ?: "NA"
        );
    }

    /**
     * Fire async promise to audit
     */
    function postHandler(event, rc, prc, action, eventArguments) {
        if(!validate(target = prc.auditInfo, constraints = "audit").hasErrors()) {
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
        prc.auditInfo.detail = "Unauthorized Event";
        renderUnauthorized(event, prc);
    }

    /**
     * 405 Invalid HTTP Method
     */
    function invalidHTTPMethod(event, rc, prc) {
        prc.auditInfo.event  = left(event.getFullPath(), 250);
        prc.auditInfo.detail = "Invalid HTTP Method #event.getHTTPMethod()#";

        if(utilService.isJsonRequest()) {
            prc.responseObj.statusCode = 405;
            prc.responseObj.message    = "Method Not Allowed";
            renderJson(event = event, response = prc.responseObj);
        }
        else {
            event.setHTTPHeader(statusCode = 405);
            event.setView(view = "/views/fragment/invalidmethod", layout = "basic");
        }
    }

    /**
     * Exception handler - ColdBox runs it for any exception the request didn't handle
     * ColdBox discards what an exception handler renders, so every outcome either relocates or sets renderData / a view
     * for views/fragment/errortemplate.cfm to send
     */
    function onException(event, rc, prc) {
        // Security outcomes thrown mid request are not bugs
        switch(prc.exception.getType()) {
            // cbSecure().secure*() checks
            case "NotAuthorized":
                // cbcsrf auto verifier - missing or stale token
            case "TokenNotFoundException":
            case "TokenMismatchException": {
                denyException(event, rc, prc);
                return;
            }
            // Logged in trainer no longer exists - cbauth already dropped them from the session
            case "NoUserLoggedIn": {
                relocate(uri = "/login");
                return;
            }
        }

        reportBug(event, rc, prc);

        // fetch callers get json - relocating would hand them the html error page
        if(utilService.isJsonRequest()) {
            renderJson(
                event,
                {
                    success   : false,
                    message   : "Something went wrong. Please try again.",
                    statusCode: 500
                }
            );
            return;
        }

        // The error page failed too - relocating to it again would loop, errortemplate.cfm shows a static page instead
        if(isExceptionPage(event)) {
            return;
        }

        // The exception details are only shown outside production - don't put them in a production session
        relocate(
            uri           = "/exception",
            persistStruct = getSetting("environment") == "production" ? {} : {
                details     : prc.exception,
                erroredEvent: event.getCurrentEvent()
            }
        );
    }

    /**
     * Error output - use the exception template
     */
    function displayException(event, rc, prc) {
        // Page metadata
        prc.title           = "Something Went Wrong";
        prc.metaDescription = "An unexpected error occurred while processing your request.";

        // Debugging mode
        prc.debuggingMode = getSetting("environment") != "production";
        prc.erroredEvent  = prc?.erroredEvent ?: "home.home";

        event.setHTTPHeader(statusCode = 500);
        event.setView(view = "/views/fragment/exception").setLayout("basic");
    }

    /**
     * 404 Not Found
     */
    function notFound(event, rc, prc) {
        prc.auditInfo.event  = left(event.getFullPath(), 250);
        prc.auditInfo.detail = "404 Not Found";

        // Page metadata
        prc.title           = "404 - Page Not Found";
        prc.metaDescription = "The page you are looking for does not exist.";

        event.setHTTPHeader(statusCode = 404);
        event.setView(view = "/views/fragment/404");
    }

    /**
     * Log the bug and email it
     * Reporting must never stop the trainer reaching the error page - a failure here is only logged
     */
    private void function reportBug(event, rc, prc) {
        try {
            prc.bugInfo = {
                ip       : utilService.getRequestIP(),
                event    : left(prc?.currentRoutedURL ?: event.getFullPath(), 250),
                message  : left(prc.exception.getMessage(), 250),
                stack    : prc.exception.getStackTrace(),
                trainerid: (prc?.oCurrentUser?.getId() ?: -1)
            };

            if(!validate(target = prc.bugInfo, constraints = "bug").hasErrors()) {
                async.newFuture(() => {
                    bugService.logBug(argumentCollection = prc.bugInfo);
                });
            }

            emailService.sendBug(prc.exception.getExceptionStruct(), rc);
        }
        catch(any e) {
            log.error(
                "Unhandled exception: #prc.exception.getMessage()# #prc.exception.getDetail()#",
                prc.exception.getExceptionStruct()
            );
            log.error("Failed to report it: #e.message# #e.detail#", e);
        }
    }

    /**
     * Whether this request is the error page itself
     * Checks the path too - an exception before routing (onRequestCapture) has no current event yet
     */
    private boolean function isExceptionPage(event) {
        return lCase(event.getCurrentEvent()) == "error.displayexception" || reFindNoCase(
            "^/?exception/?$",
            cgi.path_info
        );
    }

    /**
     * 403 for an exception thrown by a security check
     * Login forms with a stale token go back to the login page instead
     */
    private void function denyException(event, rc, prc) {
        var auditInfo = auditService.getAuditObj(
            trainerid = (prc?.oCurrentUser?.getId() ?: -1),
            event     = left(event.getCurrentEvent(), 250)
        );
        auditInfo.detail = left("Unauthorized: #prc.exception.getType()# #prc.exception.getMessage()#", 250);
        async.newFuture(() => {
            auditService.audit(argumentCollection = auditInfo);
        });

        if(lCase(event.getCurrentHandler()) == "login" && !utilService.isJsonRequest()) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Invalid. Please try again."
                }
            );
            relocate(uri = "/login");
            return;
        }

        renderUnauthorized(event, prc);
    }

    /**
     * 403 response - json for fetch callers, the access denied page otherwise
     */
    private void function renderUnauthorized(event, prc) {
        if(utilService.isJsonRequest()) {
            renderJson(
                event,
                {
                    success   : false,
                    message   : "You do not have permission to do that.",
                    statusCode: 403
                }
            );
            return;
        }

        prc.title           = "Access Denied";
        prc.metaDescription = "You do not have permission to access this resource.";
        prc.canonicalURL    = prc?.canonicalURL ?: "#getSetting("domain")#/unauthorized";
        prc.metaRobots      = "noindex, nofollow";

        event.setHTTPHeader(statusCode = 403);
        event.setView(view = "/views/fragment/unauthorized", layout = "basic");
    }

}
