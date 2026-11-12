component singleton accessors="true" {

    property name="auth"           inject="authenticationService@cbauth";
    property name="persistService" inject="services.persist";
    property name="sessionStorage" inject="SessionStorage@cbstorages";

    variables.SESSION_VERSION_KEY = "sessionVersion";

    /**
     * Remember the trainer's current sessionversion in this session
     * Called on every login, and after a trainer changes their own password so this session stays signed in
     *
     * @trainer trainer entity
     */
    public void function keepVersion(required component trainer) {
        sessionStorage.set(variables.SESSION_VERSION_KEY, val(arguments.trainer.getSessionVersion()));
        return;
    }

    /**
     * True if this session was started under the trainer's current sessionversion
     * Sessions from before versions were kept count as version 0
     *
     * @trainer trainer entity
     */
    public boolean function isCurrentVersion(required component trainer) {
        return sessionStorage.get(variables.SESSION_VERSION_KEY, 0) == val(arguments.trainer.getSessionVersion());
    }

    /**
     * Drop the stored sessionversion
     */
    public void function forgetVersion() {
        sessionStorage.delete(variables.SESSION_VERSION_KEY);
        return;
    }

    /**
     * Log the trainer out and throw away the session
     *
     * @idle true when the idle timer logged them out - keeps the remember me cookie
     */
    public void function destroy(required boolean idle) {
        try {
            auth.logout();
        }
        catch(TrainerNotFound e) {
            // logout() announces the trainer being logged out - they've been deleted, so just clear the login
            auth.quietLogout();
        }

        // Invalidate JEE session
        getPageContext().getSession().invalidate();
        sessionInvalidate();

        if(!arguments.idle) {
            persistService.deleteCookie();
        }

        return;
    }

    /**
     * Rotates the jsessionid to defend against session fixation
     * https://www.petefreitag.com/blog/sessionrotate-solution-jee/
     */
    public void function rotate() {
        // The id the browser presented before we authenticated (may be empty for a new visitor)
        var inboundId = getRequestedSessionId();

        // Force the underlying JEE HttpSession to exist before rotating the id
        ensureSession();

        try {
            session.sessionid = changeSessionId();
        }
        catch(any e) {
            var currentId = getCurrentSessionId();

            // Rotation failed and we are still on the id the client presented -> session fixation risk
            // Fail safe: tear the session down and abort.
            if(len(inboundId) && currentId == inboundId) {
                destroy(idle = false);
                throw(
                    type    = "SessionRotationFailed",
                    message = "Failed to rotate session id; aborting authentication to prevent session fixation."
                );
            }

            // Otherwise a concurrent request already rotated the id, or this is a
            // brand-new session the client never knew about -> safe to continue.
            session.sessionid = currentId;
        }

        return;
    }

    /**
     * The session id the client presented on this request (empty string if none)
     */
    private string function getRequestedSessionId() {
        return getPageContext().getRequest().getRequestedSessionId() ?: "";
    }

    /**
     * Forces request.getSession(true) so the underlying JEE HttpSession exists
     */
    private void function ensureSession() {
        getPageContext().getSession();
        return;
    }

    /**
     * Renames the underlying JEE session id and returns the new id
     */
    private string function changeSessionId() {
        return getPageContext().getRequest().changeSessionId();
    }

    /**
     * The current underlying JEE session id
     */
    private string function getCurrentSessionId() {
        return getPageContext().getSession().getId();
    }

}
