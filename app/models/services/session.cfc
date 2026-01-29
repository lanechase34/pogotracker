component singleton accessors="true" {

    property name="auditService"    inject="services.audit";
    property name="cacheService"    inject="services.cache";
    property name="persistService"  inject="services.persist";
    property name="securityService" inject="services.security";
    property name="trainerService"  inject="services.trainer";

    property name="defaultSettings" inject="coldbox:setting:defaultSettings";

    public void function destroy(required boolean idle) {
        if(session.keyExists('trainerid')) {
            cacheService.remove('trainer.getFromId|trainerid=#session.trainerid#');
        }

        // Invalidate JEE session
        getPageContext().getSession().invalidate();
        sessionInvalidate();

        if(!arguments.idle) {
            persistService.deleteCookie();
        }

        return;
    }

    public void function rotate() {
        // https://www.petefreitag.com/blog/sessionrotate-solution-jee/
        session.sessionid = getPageContext().getRequest().changeSessionId();

        return;
    }

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
        cacheService.remove('trainer.getFromId|trainerid=#session.trainerid#');

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
        required string message
    ) {
        session.alert = {
            'type'       : arguments.type,
            'dismissible': arguments.dismissible,
            'icon'       : arguments.icon,
            'message'    : arguments.message
        };
        return;
    }

    public void function clearAlert() {
        session.delete('alert');
        return;
    }

}
