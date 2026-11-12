component extends="coldbox.system.Interceptor" {

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
     * Json requests get a json error, page requests are redirected
     */
    private void function block(
        required event,
        required numeric statusCode,
        required string message,
        required string redirectUri
    ) {
        if(utilService.isJsonRequest()) {
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
            return;
        }

        relocate(uri = arguments.redirectUri);
    }

}
