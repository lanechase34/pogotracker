component extends="base" {

    this.allowedMethods = {
        loginForm         : 'GET',
        doLogin           : 'POST',
        persistLogin      : 'GET',
        registrationForm  : 'GET',
        register          : 'POST',
        verifyForm        : 'GET,POST',
        verify            : 'POST',
        forgotPasswordForm: 'GET',
        forgotPassword    : 'POST',
        resetPasswordForm : 'GET',
        resetPassword     : 'POST',
        verifyRecaptcha   : 'POST'
    };

    property name="auditService"    inject="services.audit";
    property name="persistService"  inject="services.persist";
    property name="trainerService"  inject="services.trainer";
    property name="securityService" inject="services.security";
    property name="sessionService"  inject="services.session";

    this.prehandler_except = 'logout';

    // Fires before the handler action is invoked
    function preHandler(event, rc, prc, action, eventArguments) {
        // If the user is already logged in and verified -> relocate home
        if(session.authenticated && session.verified) {
            relocate(uri = '/')
        }

        // Validate the incoming user
        prc.auditInfo = auditService.getAuditObj(trainerid = session?.trainerid ?: -1, event = rc.event);
        if(hasValidationErrors(target = prc.auditInfo, constraints = 'audit')) {
            htmlValidationFailure(event = event, redirectUri = '/unauthorized');
            return;
        }

        prc.genericFailure = {
            type       : 'danger',
            dismissible: true,
            icon       : 'bi-exclamation-diamond-fill',
            message    : 'Invalid. Please try again.'
        };

        // Ensure signups are allowed if attempting signup
        if(
            !getSetting('signups') &&
            ['register', 'registrationform'].contains(prc.currAction)
        ) {
            relocate(uri = '/login');
        }

        // Ensure these actions are submitted from correct referer
        if(
            getSetting('refererChecks').keyExists(prc.currAction) && (
                !findNoCase(cgi.http_host, securityService.getReferer()) ||
                !securityService.getReferer().find(getSetting('refererChecks')[prc.currAction])
            )
        ) {
            sessionService.setAlert(argumentCollection = prc.genericFailure);
            prc.auditInfo.detail = 'Failed Referer Check';
            auditService.audit(argumentCollection = prc.auditInfo);
            relocate(uri = '/login');
        }

        // Ensure the CSRF Token validates for these actions
        if(
            getSetting('csrfChecks').keyExists(prc.currAction) && (
                !rc.keyExists(getSetting('csrfTokenField')) ||
                !csrfVerifyToken(rc[getSetting('csrfTokenField')])
            )
        ) {
            sessionService.setAlert(argumentCollection = prc.genericFailure);
            persistService.deleteCookie(); // delete persist cookie if exists
            prc.auditInfo.detail = 'Failed CSRF Validation';
            auditService.audit(argumentCollection = prc.auditInfo);
            relocate(uri = '/login');
        }

        // Ensure the user has passed the recaptcha check
        if(
            getSetting('recaptchaChecks').keyExists(prc.currAction) &&
            !securityService.checkRecaptcha(prc.currAction)
        ) {
            sessionService.setAlert(argumentCollection = prc.genericFailure);
            prc.auditInfo.detail = 'Failed Recaptcha Check';
            auditService.audit(argumentCollection = prc.auditInfo);
            relocate(uri = '/login');
        }

        prc.title = 'Login - #getSetting('title')#';

        event.setLayout('basic');
    }

    function loginForm(event, rc, prc) {
        if(prc.keyExists('statusCode')) {
            event.setHTTPHeader(statusCode = 401);
        }
    }

    function persistLogin(event, rc, prc) {
        param name="rc.persistCookie" default="";

        // Atempt to receive valid user with this persist cookie
        prc.loginStruct = persistService.login(rc.persistCookie);
        if(!prc.loginStruct.success) {
            prc.auditInfo.detail = 'Failed Persist Login';
            auditService.audit(argumentCollection = prc.auditInfo);
            persistService.deleteCookie();
            relocate(uri = '/login');
        }

        prc.auditInfo.detail = 'Successful Persist Login';
        sessionService.create(
            email     = prc.loginStruct.email,
            persist   = false,
            auditInfo = prc.auditInfo
        );

        relocate(uri = request?.linkedEvent ?: '/');
    }

    function doLogin(event, rc, prc) {
        param name="rc.email"    default="";
        param name="rc.password" default="";
        param name="rc.persist"  default="off";

        prc.validation = validate(target = rc, constraints = 'loginForm');
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = 'Failed Login Validation';
            auditService.audit(argumentCollection = prc.auditInfo);

            sessionService.setAlert(argumentCollection = prc.genericFailure);
            relocate(uri = '/login');
        }

        rc.email  = lCase(rc.email);
        prc.login = securityService.login(rc.email, rc.password);
        if(!prc.login) {
            prc.auditInfo.detail = 'Incorrect Login Credentials';
            auditService.audit(argumentCollection = prc.auditInfo);

            sessionService.setAlert(argumentCollection = prc.genericFailure);
            relocate(uri = '/login');
        }

        prc.persist = rc.persist == 'on' ? true : false;

        prc.auditInfo.detail = 'Successful Login';
        sessionService.create(
            email     = rc.email,
            persist   = prc.persist,
            auditInfo = prc.auditInfo
        );

        relocate(uri = request.linkedEvent);
    }

    function registrationForm(event, rc, prc) {
        prc.iconMap = trainerService.getIconMap();
    }

    function register(event, rc, prc) {
        param name="rc.username"   default="";
        param name="rc.password"   default="";
        param name="rc.email"      default="";
        param name="rc.friendcode" default="";
        param name="rc.icon"       default="";

        prc.validation = validate(target = rc, constraints = 'registrationForm');
        if(prc.validation.hasErrors()) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Invalid registration. Username/email/friendcode already taken, please try again.'
            );
            relocate(event = 'register');
        }

        securityService.register(
            rc.username,
            rc.password,
            rc.email,
            rc.friendcode,
            rc.icon
        );

        sessionService.setAlert(
            'success',
            true,
            'bi-check-square-fill',
            'Registration complete!'
        );

        prc.auditInfo.detail = 'Successful Registration';
        sessionService.create(
            email     = rc.email,
            persist   = false,
            auditInfo = prc.auditInfo
        );

        securityService.sendVerificationCode(session.email, false);

        relocate(uri = '/verify');
    }

    function verifyForm(event, rc, prc) {
        if(session.verified) relocate(uri = '/');
        if(!session.authenticated) relocate(uri = '/login');

        param name="rc.resend" type="boolean" default="false";

        if(isBoolean(rc.resend) && booleanFormat(rc.resend)) {
            securityService.sendVerificationCode(session.email, rc.resend);
        }
    }

    function verify(event, rc, prc) {
        if(session.verified) relocate(uri = '/');
        if(!session.authenticated) relocate(uri = '/login');

        param name="rc.code" default="";

        prc.validation = validate(target = rc, constraints = 'verifyForm');
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = 'Failed Verification Code Validation';
            auditService.audit(argumentCollection = prc.auditInfo);
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Invalid verification code. Please try again.'
            );
            relocate(uri = '/verify');
        }

        rc.code = trim(rc.code);
        if(!securityService.checkVerificationCode(session.email, rc.code)) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Invalid verification code. Please try again.'
            );
            relocate(uri = '/verify');
        }

        prc.auditInfo.detail    = 'Successfully Verified';
        prc.auditInfo.trainerid = session.trainerid;
        auditService.audit(argumentCollection = prc.auditInfo);

        sessionService.update(session.trainerid);
        relocate(uri = '/');
    }

    function logout(event, rc, prc) {
        param name="rc.idle" default="false";
        sessionService.destroy(rc.idle);
        relocate(uri = '/');
    }

    function forgotPasswordForm(event, rc, prc) {
    }

    function forgotPassword(event, rc, prc) {
        param name="rc.email" default="";

        prc.validation = validate(target = rc, constraints = 'forgotPasswordForm');
        if(prc.validation.hasErrors()) {
            prc.auditInfo.detail = 'Failed Forgot Password Validation. User attempting to reset password #rc.email# that does not exist.';
            auditService.audit(argumentCollection = prc.auditInfo);
        }
        else {
            rc.email = lCase(rc.email);
            securityService.sendResetCode(rc.email);

            prc.auditInfo.detail = 'Forgot password email sent for #rc.email#';
            auditService.audit(argumentCollection = prc.auditInfo);
        }

        sessionService.setAlert(
            'success',
            true,
            'bi-check-square-fill',
            'Reset password email sent. Please check your email.'
        );
        relocate(uri = '/login');
    }

    function resetPasswordForm(event, rc, prc) {
        param name="rc.resetCode" default="";

        // Check the reset code for a valid user
        prc.email = securityService.checkResetCode(rc.resetCode);
        if(!prc.email.len()) {
            prc.auditInfo.detail = 'Failed Reset Code Check';
            auditService.audit(argumentCollection = prc.auditInfo);

            relocate(uri = '/login');
        }
    }

    function resetPassword(event, rc, prc) {
        param name="rc.resetCode" default="";
        param name="rc.password"  default="";

        prc.validation = validate(target = rc, constraints = 'resetPasswordForm');
        prc.email      = securityService.checkResetCode(rc.resetCode, true);
        if(prc.validation.hasErrors() || !prc.email.len()) {
            prc.auditInfo.detail = 'Failed Reset Password Validation';
            auditService.audit(argumentCollection = prc.auditInfo);

            relocate(uri = '/login');
        }

        prc.trainer = securityService.getTrainer(prc.email)[1];
        securityService.update(
            prc.trainer.getId(),
            prc.trainer.getUsername(),
            rc.password,
            prc.trainer.getEmail(),
            prc.trainer.getIcon()
        );

        sessionService.setAlert(
            'success',
            true,
            'bi-check-square-fill',
            'Successfully reset password.'
        );
        relocate(uri = '/login');
    }

    /**
     * Verify a user's action with recaptcha
     *
     * @rc.recaptchaToken user's unique token
     */
    function verifyRecaptcha(event, rc, prc) {
        prc.validation = validate(target = rc, constraints = 'verifyRecaptcha');
        if(!prc.validation.hasErrors()) {
            prc.verifyRecaptcha = securityService.verifyRecaptcha(rc.recaptchaToken);

            prc.responseObj.success = prc.verifyRecaptcha;
            if(!prc.verifyRecaptcha) {
                prc.responseObj.message = 'Please try again.';
            }
            else {
                prc.responseObj.message    = 'Success';
                prc.responseObj.statusCode = 200;
            }
        }

        event.renderData(
            type       = 'json',
            data       = prc.responseObj,
            statusCode = prc.responseObj.statusCode
        );
    }

}
