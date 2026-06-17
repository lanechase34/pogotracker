component singleton accessors="true" {

    property name="auditService"    inject="services.audit";
    property name="cache"           inject="cachebox:appCache";
    property name="persistService"  inject="services.persist";
    property name="securityService" inject="services.security";
    property name="trainerService"  inject="services.trainer";

    property name="defaultSettings" inject="coldbox:setting:defaultSettings";

    public void function destroy(required boolean idle) {
        if(session.keyExists('trainerid')) {
            cache.clear('trainer.getFromId|trainerid=#session.trainerid#');
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
                    type    = 'SessionRotationFailed',
                    message = 'Failed to rotate session id; aborting authentication to prevent session fixation.'
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
        return getPageContext().getRequest().getRequestedSessionId() ?: '';
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

    /**
     * Creates a new session
     *
     * @email     email of trainer
     * @persist   t/f 
     * @auditInfo audit info struct
     */
    public void function create(
        required string email,
        required boolean persist,
        struct auditInfo = {}
    ) {
        var trainer = securityService.getTrainer(arguments.email)[1];

        if(arguments.persist) {
            persistService.addCookie(trainer);
        }

        session.authenticated = true;
        session.verified      = trainer.getVerified();
        session.trainerid     = trainer.getId();
        session.username      = trainer.getUsername();
        session.iconPath      = trainer.getIconPath();
        session.iconAlt       = trainer.getIconAltText();
        session.statStruct    = trainer.getCurrentLevel();
        session.email         = trainer.getEmail();
        session.securityLevel = trainer.getSecurityLevel();

        // Load user settings
        session.settings = trainer.getSettings();

        // If it's empty, give them the default settings
        if(session.settings.isEmpty()) {
            trainer.setSettings(defaultSettings);
            session.settings = defaultSettings;
        }

        // Update the user's settings if any of the keys are missing
        if(session.settings.count() < defaultSettings.count()) {
            defaultSettings.each((key, value) => {
                // Struct value
                if(isStruct(value)) {
                    // Add the struct
                    if(!session.settings.keyExists(key)) {
                        session.settings[key] = {};
                    }

                    // Add any missing keys from struct
                    value.each((propname, propvalue) => {
                        if(!session.settings[key].keyExists(propname)) {
                            session.settings[key][propname] = propvalue;
                        }
                    });
                }
                // Simple value
                else if(!session.settings.keyExists(key)) {
                    session.settings[key] = value;
                }
            });
            trainer.setSettings(session.settings);
        }

        if(!session.keyExists('linkedEvent')) {
            session.linkedEvent = session.settings.defaultPage;
        }

        request.linkedEvent = session.linkedEvent;

        session.loginTime = now();
        trainer.setLastLogin(session.loginTime);
        entitySave(trainer);
        ormFlush();

        session.trainer = trainer;

        if(!arguments.auditInfo.isEmpty()) {
            arguments.auditInfo.trainerid = session.trainerid;
            auditService.audit(argumentCollection = arguments.auditInfo);
        }

        rotate();
        return;
    }

    public void function update(required numeric trainerid) {
        // Clear cache first
        cache.clear('trainer.getFromId|trainerid=#session.trainerid#');

        var trainer = trainerService.getFromId(arguments.trainerid);

        session.verified      = trainer.getVerified();
        session.username      = trainer.getUsername();
        session.iconPath      = trainer.getIconPath();
        session.iconAlt       = trainer.getIconAltText();
        session.securityLevel = trainer.getSecurityLevel();
        session.statStruct    = trainer.getCurrentLevel();
        session.settings      = trainer.getSettings();
        session.trainer       = trainer;
        return;
    }

    public void function setAlert(
        required string type,
        required boolean dismissible,
        required string icon,
        required string message,
        numeric margin = 3
    ) {
        session.alert = {
            'type'       : arguments.type,
            'dismissible': arguments.dismissible,
            'icon'       : arguments.icon,
            'message'    : arguments.message,
            'margin'     : arguments.margin
        };
        return;
    }

    public void function clearAlert() {
        session.delete('alert');
        return;
    }

}
