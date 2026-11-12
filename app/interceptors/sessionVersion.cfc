component extends="coldbox.system.Interceptor" {

    property name="authService"    inject="provider:authenticationService@cbauth";
    property name="sessionService" inject="provider:services.session";

    /**
     * Keep the version the trainer logged in under - every login (form, registration, remember me)
     */
    function postLogin(event, data, buffer, rc, prc) {
        sessionService.keepVersion(data.user);
    }

    /**
     * Signs out sessions started before the trainer's password last changed
     * A password change bumps the trainer's sessionversion, so every older session stops matching
     */
    function preProcess(event, data, buffer, rc, prc) {
        if(!authService.isLoggedIn()) {
            return;
        }

        try {
            var trainer = authService.getUser();
        }
        catch(TrainerNotFound e) {
            // cbauth has already signed out a session whose trainer was deleted
            return;
        }

        if(!sessionService.isCurrentVersion(trainer)) {
            authService.logout();
            sessionService.forgetVersion();
        }
    }

}
