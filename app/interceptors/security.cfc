component extends="coldbox.system.Interceptor" {

    property name="auditService"     inject="provider:services.audit";
    property name="authService"      inject="provider:authenticationService@cbauth";
    property name="cbcsrf"           inject="provider:@cbcsrf";
    property name="persistService"   inject="provider:services.persist";
    property name="rateLimitService" inject="provider:services.rateLimit";
    property name="sessionService"   inject="provider:services.session";
    property name="trainerService"   inject="provider:services.trainer";
    property name="utilService"      inject="provider:services.util";

    // rateLimits entry for remember me logins
    variables.PERSIST_LIMIT = "persist.login";

    /**
     * Remember me - log the trainer in from their persist cookie
     * Runs at onRequestCapture so the trainer is logged in before the firewall (preProcess) checks the request,
     * and the request they asked for simply continues
     */
    function onRequestCapture(event, data, buffer, rc, prc) {
        if(authService.isLoggedIn() || !persistService.checkCookie()) {
            return;
        }

        // Over the limit - carry on as a guest, keep the cookie (it may be valid) and don't audit (the flood is the point)
        if(!rateLimitService.allow(name = variables.PERSIST_LIMIT, ip = utilService.getRequestIP())) {
            return;
        }

        var auditInfo = auditService.getAuditObj(trainerid = -1, event = "login.persistLogin");
        var result    = persistService.login(persistService.getCookie());

        if(!result.success) {
            persistService.deleteCookie();
            auditInfo.detail = "Failed Persist Login";
            auditService.audit(argumentCollection = auditInfo);
            return;
        }

        authService.login(authService.getUserService().retrieveUserById(result.trainerid));

        auditInfo.trainerid = result.trainerid;
        auditInfo.detail    = "Successful Persist Login from /#reReplace(event.getCurrentRoutedURL(), "^[/\\]+", "")#";
        auditService.audit(argumentCollection = auditInfo);
    }

    /**
     * prc.oCurrentUser - the logged in trainer (absent for guests)
     * cbsecurity sets it too, but at the end of its preProcess - setting it here makes it available to every interceptor
     */
    function preProcess(event, data, buffer, rc, prc) {
        if(authService.isLoggedIn()) {
            try {
                prc.oCurrentUser = authService.getUser();
            }
            catch(TrainerNotFound e) {
                // Trainer was deleted mid session - cbauth already dropped them, carry on as a guest
            }
        }
    }

    /**
     * Every login - form, registration and remember me
     * data: {user, sessionStorage, requestStorage}
     */
    function postLogin(event, data, buffer, rc, prc) {
        // Session fixation defense - new session id, new csrf tokens
        sessionService.rotate();
        cbcsrf.rotate();

        trainerService.updateLastLogin(data.user);

        // Settings added to settings.defaultSettings since the trainer last logged in
        data.user.fillDefaultSettings();
    }

    /**
     * Not logged in
     * - json requests get a 401 (fetch.js sends them to /login)
     * - page navigations remember where they were going and go to /login
     */
    function cbSecurity_onInvalidAuthentication(event, data, buffer, rc, prc) {
        data.processActions = false;

        if(utilService.isJsonRequest()) {
            renderBlocked(event, 401, "Please log in.");
            return;
        }

        if(event.getHTTPMethod() == "GET" && utilService.isNavigationRequest()) {
            // Relative path only
            session.linkedEvent = "/#reReplace(
                reReplace(event.getCurrentRoutedURL(), "^[/\\]+", ""),
                "/+$",
                ""
            )#";
        }

        relocate(uri = "/login");
    }

    /**
     * Logged in without the permission
     * - unverified trainers finish verifying first
     * - everyone else falls through to error.unauthorized (firewall default)
     */
    function cbSecurity_onInvalidAuthorization(event, data, buffer, rc, prc) {
        prc.unauthorizedEvent = event.getCurrentEvent();

        if(prc.oCurrentUser.getVerified()) {
            return;
        }

        data.processActions = false;
        if(utilService.isJsonRequest()) {
            renderBlocked(event, 403, "Please verify your account.");
            return;
        }
        relocate(uri = "/verify");
    }

    private void function renderBlocked(
        required event,
        required numeric statusCode,
        required string message
    ) {
        arguments.event
            .renderData(
                type = "json",
                data = {
                    success   : false,
                    message   : arguments.message,
                    statusCode: arguments.statusCode
                },
                statusCode = arguments.statusCode
            )
            .noExecution();
    }

}
