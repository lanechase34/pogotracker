component singleton accessors="true" {

    property name="secretKey"     inject="coldbox:setting:reCaptchaSecretKey";
    property name="useRecaptcha"  inject="coldbox:setting:useRecaptcha";
    property name="skipRecaptcha" inject="coldbox:setting:skipRecaptcha";
    property name="utilService"   inject="services.util";
    property name="logger"        inject="logbox:logger:{this}";

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
            action   : "",
            reason   : ""
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

                if(isStruct(recaptchaResponse) && !recaptchaResponse.isEmpty()) {
                    var success = (recaptchaResponse?.success ?: false) == true;
                    var score   = val(recaptchaResponse?.score ?: 0);

                    recaptchaResult.valid  = success && score > 0.5;
                    recaptchaResult.action = recaptchaResponse?.action ?: "";

                    var context = "action: #recaptchaResult.action#, hostname: #recaptchaResponse?.hostname ?: ""#";
                    if(!success) {
                        var errorCodes         = recaptchaResponse?.keyExists("error-codes") ? recaptchaResponse["error-codes"] : [];
                        recaptchaResult.reason = "Rejected by Google (error-codes: #isArray(errorCodes) ? errorCodes.toList(", ") : ""#, #context#)";
                    }
                    else if(!recaptchaResult.valid) {
                        recaptchaResult.reason = "Score too low (score: #score#, threshold: 0.5, #context#)";
                    }
                }
                else {
                    recaptchaResult.reason = "Unexpected response from Google (status: #local.result?.statuscode ?: "none"#)";
                }
            }
            catch(any e) {
                recaptchaResult.valid  = false;
                recaptchaResult.reason = "Request to Google failed (#e.message#)";
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

        if(getSkipRecaptcha()) {
            logger.error("reCAPTCHA skipped for '#arguments.expectedAction#' - RECAPTCHASITEKEY/RECAPTCHASECRETKEY are not set in development");
        }

        return !getUseRecaptcha() ? true : valid;
    }

    private struct function blankResult() {
        return {
            token    : "",
            valid    : false,
            timestamp: now(),
            action   : "",
            reason   : ""
        };
    }

}
