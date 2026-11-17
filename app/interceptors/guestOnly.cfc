component extends="baseInterceptor" {

    property name="guestOnlyEvents" inject="coldbox:setting:guestOnlyEvents";
    property name="utilService"     inject="provider:services.util";

    // The only events an unverified trainer can reach (error.* is always allowed so error pages render)
    variables.unverifiedEvents = [
        "login.verifyForm",
        "login.verify",
        "login.logout"
    ];

    /**
     * Keep logged in trainers out of guest-only events, and unverified trainers to verifying or logging out
     */
    function preProcess(event, data, buffer, rc, prc) {
        if(!prc.keyExists("oCurrentUser")) {
            return;
        }

        var currentEvent = event.getCurrentEvent();

        if(!prc.oCurrentUser.getVerified()) {
            if(variables.unverifiedEvents.findNoCase(currentEvent) || reFindNoCase("^error\.", currentEvent)) {
                return;
            }
            block(
                event,
                403,
                "Please verify your account.",
                "/verify"
            );
            return;
        }

        if(guestOnlyEvents.findNoCase(currentEvent)) {
            block(event, 400, "You are already logged in.", "/");
        }
    }

    /**
     * Json requests get a json error carrying where to go, page requests are redirected
     * A guest form's json call can be the request remember me logs the trainer in on (interceptors/security.cfc),
     * the redirect lets the page follow instead of failing
     */
    private void function block(
        required event,
        required numeric statusCode,
        required string message,
        required string redirectUri
    ) {
        if(utilService.isJsonRequest()) {
            renderJsonError(
                arguments.event,
                arguments.statusCode,
                arguments.message,
                arguments.redirectUri
            );
            return;
        }

        relocate(uri = arguments.redirectUri);
    }

}
