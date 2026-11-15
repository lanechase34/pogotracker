component extends="baseInterceptor" {

    property name="rateLimits"       inject="coldbox:setting:rateLimits";
    property name="recaptchaChecks"  inject="coldbox:setting:reCaptchaChecks";
    property name="auditService"     inject="provider:services.audit";
    property name="rateLimitService" inject="provider:services.rateLimit";
    property name="recaptchaService" inject="provider:services.recaptcha";
    property name="utilService"      inject="provider:services.util";

    /**
     * Rate limit requests on a per event basis on server side, and gate reCaptchaChecks events on their recaptcha result
     *
     * 1. rules without afterRecaptcha - counted first so failed recaptcha posts still use up the ip's allowance
     * 2. the recaptcha check
     * 3. rules marked afterRecaptcha - scoped to someone else's value (email), so junk posts can't lock that person out
     */
    function preProcess(event, data, buffer, rc, prc) {
        // Skip requests an earlier interceptor already rejected (e.g. guestOnly) - they shouldn't count
        if(event.isNoExecution()) {
            return;
        }

        var currEvent = lCase(event.getCurrentEvent());
        var limited   = rateLimits.keyExists(currEvent);
        var gated     = recaptchaChecks.keyExists(currEvent);
        if(!limited && !gated) {
            return;
        }

        var ip      = utilService.getRequestIP();
        var allowed = !limited || rateLimitService.allow(name = currEvent, ip = ip, context = rc);

        if(allowed && gated) {
            // The recaptcha action is the bare action the page ran grecaptcha.execute with
            if(!recaptchaService.check(expectedAction = lCase(event.getCurrentAction()))) {
                var auditInfo    = auditService.getAuditObj(trainerid = -1, event = currEvent);
                auditInfo.detail = "Failed Recaptcha Check";
                auditService.audit(argumentCollection = auditInfo);

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

            allowed = !limited || rateLimitService.allow(
                name           = currEvent,
                ip             = ip,
                context        = rc,
                afterRecaptcha = true
            );
        }

        if(allowed) {
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

        // AJAX endpoints get a json 429 and the request stops here
        renderJsonError(event, 429, message);
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
