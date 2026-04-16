component extends="coldbox.system.Interceptor" {

    property name="sessionService" inject="provider:services.session";

    function configure() {
    }

    /**
     * Check if there's an alert set to session.alert, if so, move to request.alert for rendering
     * Delete the session key
     */
    function postEvent(event, data, buffer, rc, prc) {
        if(session.keyExists('alert')) {
            request.alert = session.alert;
            sessionService.clearAlert();
        }
    }

    /**
     * Clean up request scope
     */
    function postProcess(event, data, buffer, rc, prc) {
        request.delete('alert');
    }

}
