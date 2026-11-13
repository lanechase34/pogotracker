component extends="base" {

    this.allowedMethods = {
        loginForm         : "GET",
        doLogin           : "POST",
        registrationForm  : "GET",
        register          : "POST",
        verifyForm        : "GET,POST",
        verify            : "POST",
        forgotPasswordForm: "GET",
        forgotPassword    : "POST",
        resetPasswordForm : "GET",
        resetPassword     : "POST",
        verifyRecaptcha   : "POST",
        logout            : "POST"
    };

    property name="accountService"   inject="services.account";
    property name="auditService"     inject="services.audit";
    property name="persistService"   inject="services.persist";
    property name="recaptchaService" inject="services.recaptcha";
    property name="sessionService"   inject="services.session";
    property name="trainerService"   inject="services.trainer";
    property name="userService"      inject="services.user";

    this.prehandler_except = "logout";

    // Fires before the handler action is invoked
    function preHandler(event, rc, prc, action, eventArguments) {
        // Validate the incoming user
        prc.auditInfo = auditService.getAuditObj(trainerid = (prc?.oCurrentUser?.getId() ?: -1), event = rc.event);
        if(hasValidationErrors(target = prc.auditInfo, constraints = "audit")) {
            htmlValidationFailure(event = event, redirectUri = "/unauthorized");
            return;
        }

        prc.genericFailure = {
            type       : "danger",
            dismissible: true,
            icon       : "bi-exclamation-diamond-fill",
            message    : "Invalid. Please try again."
        };

        // Ensure signups are allowed if attempting signup
        var signupEndpoints = ["register", "registrationform"];
        if(
            !getSetting("signups") &&
            signupEndpoints.contains(prc.currAction)
        ) {
            relocate(uri = "/login");
        }

        // Ensure the user has passed the recaptcha check
        if(
            getSetting("recaptchaChecks").keyExists(prc.currAction) &&
            !recaptchaService.check(prc.currAction)
        ) {
            flash.put(name = "alert", value = prc.genericFailure);
            prc.auditInfo.detail = "Failed Recaptcha Check";
            auditService.audit(argumentCollection = prc.auditInfo);
            relocate(uri = "/login");
        }

        prc.title      = "Sign In | #getSetting("title")#";
        prc.metaRobots = "noindex, nofollow";

        event.setLayout("basic");
    }

    function loginForm(event, rc, prc) {
        prc.loadRecaptcha   = true;
        prc.title           = "Sign In | #getSetting("title")#";
        prc.metaDescription = "Sign in to POGO Tracker to track your Pokémon GO journey — Pokédex, XP, medals, shiny collection, and more.";
    }

    function doLogin(event, rc, prc) {
        param name="rc.email"    default="";
        param name="rc.password" default="";
        param name="rc.persist"  default="off";

        prc.validation = validate(target = rc, constraints = "loginForm");
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = "Failed Login Validation";
            auditService.audit(argumentCollection = prc.auditInfo);

            flash.put(name = "alert", value = prc.genericFailure);
            relocate(uri = "/login");
        }

        rc.email = lCase(rc.email);
        try {
            prc.trainer = auth().authenticate(rc.email, rc.password);
        }
        catch(InvalidCredentials e) {
            prc.auditInfo.detail = "Incorrect Login Credentials";
            auditService.audit(argumentCollection = prc.auditInfo);

            flash.put(name = "alert", value = prc.genericFailure);
            relocate(uri = "/login");
        }

        if(rc.persist == "on") {
            persistService.addCookie(prc.trainer);
        }

        prc.auditInfo.trainerid = prc.trainer.getId();
        prc.auditInfo.detail    = "Successful Login";
        auditService.audit(argumentCollection = prc.auditInfo);

        if(!prc.trainer.getVerified()) {
            relocate(uri = "/verify");
        }

        relocate(uri = takeLinkedEvent(prc.trainer));
    }

    function registrationForm(event, rc, prc) {
        prc.loadRecaptcha   = true;
        prc.title           = "Create Account | #getSetting("title")#";
        prc.metaDescription = "Create your free POGO Tracker account. Track your Pokémon GO Pokédex, XP, medals, shinies, walking distance, and plan trades with friends.";
        prc.iconMap         = trainerService.getIconMap();
    }

    function register(event, rc, prc) {
        param name="rc.username"   default="";
        param name="rc.password"   default="";
        param name="rc.email"      default="";
        param name="rc.friendcode" default="";
        param name="rc.icon"       default="";

        prc.validation = validate(target = rc, constraints = "registrationForm");
        if(prc.validation.hasErrors() || !trainerService.isAllowedIcon(rc.icon)) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Invalid registration. Username/email/friendcode already taken, please try again.",
                    "margin"     : 0
                }
            );
            relocate(event = "register");
        }

        try {
            var newTrainer = accountService.register(
                rc.username,
                rc.password,
                rc.email,
                rc.friendcode,
                rc.icon
            );
        }
        catch(UniqueViolation e) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Invalid registration. #e.message# Please try again.",
                    "margin"     : 0
                }
            );
            relocate(event = "register");
        }

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi-check-square-fill",
                "message"    : "Registration complete!"
            }
        );

        auth().login(trainerService.getFromId(newTrainer.getId()));

        prc.auditInfo.trainerid = newTrainer.getId();
        prc.auditInfo.detail    = "Successful Registration";
        auditService.audit(argumentCollection = prc.auditInfo);

        accountService.sendVerificationCode(newTrainer.getEmail(), false);

        relocate(uri = "/verify");
    }

    function verifyForm(event, rc, prc) {
        // User not logged in -> go to login form
        if(!prc.keyExists("oCurrentUser")) relocate(uri = "/login");
        // User already verified -> go to home page
        if(prc.oCurrentUser.getVerified()) relocate(uri = "/");

        prc.title           = "Verify Your Account | #getSetting("title")#";
        prc.metaDescription = "Verify your POGO Tracker account with the confirmation code sent to your email address.";

        param name="rc.resend" type="boolean" default="false";

        // Resending sends an email - only from the posted resend form (csrf checked), never a plain link
        if(event.getHTTPMethod() == "POST" && isBoolean(rc.resend) && booleanFormat(rc.resend)) {
            accountService.sendVerificationCode(prc.oCurrentUser.getEmail(), rc.resend);
            // Flash alerts show on the next request - redirect so the resend result renders
            relocate(uri = "/verify");
        }
    }

    function verify(event, rc, prc) {
        // User not logged in -> go to login form
        if(!prc.keyExists("oCurrentUser")) relocate(uri = "/login");
        // User already verified -> go to home page
        if(prc.oCurrentUser.getVerified()) relocate(uri = "/");

        param name="rc.code" default="";

        prc.validation = validate(target = rc, constraints = "verifyForm");
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = "Failed Verification Code Validation";
            auditService.audit(argumentCollection = prc.auditInfo);
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Invalid verification code. Please try again.",
                    "margin"     : 0
                }
            );
            relocate(uri = "/verify");
        }

        rc.code = trim(rc.code);
        if(!accountService.checkVerificationCode(prc.oCurrentUser.getEmail(), rc.code)) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Invalid verification code. Please try again.",
                    "margin"     : 0
                }
            );
            relocate(uri = "/verify");
        }

        prc.auditInfo.detail = "Successfully Verified";
        auditService.audit(argumentCollection = prc.auditInfo);

        relocate(uri = "/");
    }

    function logout(event, rc, prc) {
        param name="rc.idle" default="false";
        sessionService.destroy(isBoolean(rc.idle) && booleanFormat(rc.idle));
        relocate(uri = "/");
    }

    function forgotPasswordForm(event, rc, prc) {
        prc.loadRecaptcha   = true;
        prc.title           = "Reset Password | #getSetting("title")#";
        prc.metaDescription = "Forgot your POGO Tracker password? Enter your email and we will send you a link to reset it.";
    }

    function forgotPassword(event, rc, prc) {
        param name="rc.email" default="";

        prc.validation = validate(target = rc, constraints = "forgotPasswordForm");
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = "Failed Forgot Password Validation. User attempting to reset password #rc.email# that does not exist.";
            auditService.audit(argumentCollection = prc.auditInfo);
        }
        else {
            rc.email = lCase(rc.email);
            accountService.sendResetCode(rc.email);

            prc.auditInfo.detail = "Forgot password email sent for #rc.email#";
            auditService.audit(argumentCollection = prc.auditInfo);
        }

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi-check-square-fill",
                "message"    : "Reset password email sent. Please check your email.",
                "margin"     : 0
            }
        );
        relocate(uri = "/login");
    }

    function resetPasswordForm(event, rc, prc) {
        param name="rc.resetCode" default="";

        // Check the reset code for a valid user
        prc.email = accountService.checkResetCode(rc.resetCode);
        if(!prc.email.len()) {
            prc.auditInfo.detail = "Failed Reset Code Check";
            auditService.audit(argumentCollection = prc.auditInfo);

            relocate(uri = "/login");
        }
    }

    function resetPassword(event, rc, prc) {
        param name="rc.resetCode" default="";
        param name="rc.password"  default="";

        // Only use up the reset code once the new password is valid - a bad password keeps the link working
        prc.validation = validate(target = rc, constraints = "resetPasswordForm");
        prc.email      = prc.validation.hasErrors() ? "" : accountService.checkResetCode(rc.resetCode, true);
        if(prc.validation.hasErrors() || !prc.email.len()) {
            prc.auditInfo.detail = "Failed Reset Password Validation";
            auditService.audit(argumentCollection = prc.auditInfo);

            relocate(uri = "/login");
        }

        prc.trainer = userService.findByEmail(prc.email);
        accountService.update(
            prc.trainer.getId(),
            prc.trainer.getUsername(),
            rc.password,
            prc.trainer.getEmail(),
            prc.trainer.getIcon()
        );

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi-check-square-fill",
                "message"    : "Successfully reset password.",
                "margin"     : 0
            }
        );
        relocate(uri = "/login");
    }

    /**
     * Verify a user's action with recaptcha
     *
     * @rc.recaptchaToken user's unique token
     */
    function verifyRecaptcha(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "verifyRecaptcha")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.verifyRecaptcha = recaptchaService.verify(rc.recaptchaToken);

        prc.responseObj.success = prc.verifyRecaptcha;
        if(!prc.verifyRecaptcha) {
            prc.responseObj.message    = "Please try again.";
            prc.responseObj.statusCode = 400;
        }
        else {
            prc.responseObj.message    = "Success";
            prc.responseObj.statusCode = 200;
        }

        renderJson(event = event, response = prc.responseObj);
    }

    /**
     * Where to send the trainer after logging in - the page the firewall stopped them
     */
    private string function takeLinkedEvent(required component trainer) {
        var target = session?.linkedEvent ?: "";
        session.delete("linkedEvent");

        if(!target.len()) {
            target = arguments.trainer.getSettings()?.defaultPage ?: "/";
        }

        // Relative paths only - never a //host redirect
        return "/#reReplace(target, "^[/\\]+", "")#";
    }

}
