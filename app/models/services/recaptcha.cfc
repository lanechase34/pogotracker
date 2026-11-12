component singleton accessors="true" {

    property name="secretKey"    inject="coldbox:setting:reCaptchaSecretKey";
    property name="useRecaptcha" inject="coldbox:setting:useRecaptcha";
    property name="utilService"  inject="services.util";

    /**
     * Submit the user's recaptcha token to google to verify
     *
     * @token user's recaptcha token
     */
    public boolean function verify(required string token) {
        // Returns {success, challenge_ts, hostname, score, action}
        var recaptchaResult = {
            token    : arguments.token,
            valid    : !getUseRecaptcha(),
            timestamp: now(),
            action   : ""
        };

        if(getUseRecaptcha()) {
            // Google down, a timeout, or an unexpected response fails the check instead of erroring the login page
            try {
                cfhttp(
                    url     = "https://www.google.com/recaptcha/api/siteverify",
                    result  = "local.result",
                    method  = "POST",
                    timeout = 5
                ) {
                    cfhttpparam(
                        name  = "secret",
                        type  = "formfield",
                        value = getSecretKey()
                    );
                    cfhttpparam(
                        name  = "response",
                        type  = "formfield",
                        value = arguments.token
                    );
                    cfhttpparam(
                        name  = "remoteip",
                        type  = "formfield",
                        value = utilService.getRequestIP()
                    );
                };

                var recaptchaResponse = isJSON(local.result?.filecontent ?: "")
                 ? deserializeJSON(local.result.filecontent)
                 : {};

                if(isStruct(recaptchaResponse)) {
                    recaptchaResult.valid = (recaptchaResponse?.success ?: false) == true
                    && val(recaptchaResponse?.score ?: 0) > 0.5;
                    recaptchaResult.action = recaptchaResponse?.action ?: "";
                }
            }
            catch(any e) {
                recaptchaResult.valid = false;
            }
        }

        session.recaptcha = recaptchaResult;
        return recaptchaResult.valid;
    }

    /**
     * Checks the user's session for a valid recaptcha response for the expected action
     * The stored result is single use - it is blanked after every check
     *
     * @expectedAction Action to match in the session data
     */
    public boolean function check(required string expectedAction) {
        var stored = session?.recaptcha ?: blankResult();
        var valid  = (
            stored.valid &&
            stored.token.len() &&
            dateDiff("s", stored.timestamp, now()) <= 30 &&
            arguments.expectedAction == stored.action
        );

        session.recaptcha = blankResult();

        return !getUseRecaptcha() ? true : valid;
    }

    private struct function blankResult() {
        return {
            token    : "",
            valid    : false,
            timestamp: now(),
            action   : ""
        };
    }

}
