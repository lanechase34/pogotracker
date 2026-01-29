component extends="base" {

    this.allowedMethods = {
        index        : 'GET',
        viewProfile  : 'GET',
        editProfile  : 'GET',
        updateProfile: 'POST',
        getSettings  : 'GET'
    };

    property name="friendService"     inject="services.friend";
    property name="generationService" inject="services.generation";
    property name="securityService"   inject="services.security";
    property name="sessionService"    inject="services.session";
    property name="trainerService"    inject="services.trainer";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = 'Profile - #getSetting('title')#';
        prc.metaDescription = 'View your profile, friend requests, Pokedex summary, Stats summary, medal overview, and more.';
    }

    /**
     * View a trainer's profile
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function viewProfile(event, rc, prc) {
        rc.trainerid  = rc?.trainerid ?: session.trainerid;
        prc.myProfile = rc.trainerid == session.trainerid;

        // If you are visiting someone else's profile, check that you are friends with them
        if(!prc.myProfile && hasValidationErrors(target = rc, constraints = 'trainer.viewProfile')) {
            htmlValidationFailure(event = event, redirectUri = '/profile');
            return;
        }

        // Set up for profile cards
        prc.startDate = dateFormat(createDate(year(now()), month(now()), 1), 'MM-DD-YYYY');
        prc.endDate   = dateFormat(
            createDate(
                year(now()),
                month(now()),
                daysInMonth(prc.startDate)
            ),
            'MM-DD-YYYY'
        );

        prc.trainer    = trainerService.getFromId(trainerid = rc.trainerid);
        prc.statStruct = prc.myProfile ? session.statStruct : prc.trainer.getCurrentLevel();
    }

    /**
     * Edit profile form
     */
    function editProfile(event, rc, prc) {
        prc.trainer       = trainerService.getFromId(trainerid = session.trainerid);
        prc.baseIcons     = trainerService.getIconMap();
        prc.unlockedIcons = prc.trainer.getUnlockedIcons();

        event.setView(
            view     = '/views/trainer/modal/editProfile',
            nolayout = true,
            args     = {
                trainer    : prc.trainer,
                iconMap    : arrayMerge(prc.baseIcons, prc.unlockedIcons),
                viewMap    : getSetting('viewMap'),
                generations: generationService.getAll(),
                pageMap    : getSetting('pageMap')
            }
        );
    }

    /**
     * Update profile endpoint
     * Returns JSON
     */
    function updateProfile(event, rc, prc) {
        param name="rc.trainerid"     default="";
        param name="rc.username"      default="";
        param name="rc.password"      default="";
        param name="rc.email"         default="";
        param name="rc.icon"          default="";
        param name="rc.friendcode"    default="";
        param name="rc.securityLevel" default="";
        param name="rc.verified"      default="";
        param name="rc.defaultView"   default="";
        param name="rc.defaultRegion" default="";
        param name="rc.defaultPage"   default="";

        prc.validation = validate(target = rc, constraints = 'trainer.updateProfile');
        if(prc.validation.hasErrors()) {
            prc.responseObj.message = 'Invalid profile update. Please verify all fields.';
        }
        else {
            prc.securityValidation = securityService.validateUpdateProfile(
                rc.trainerid,
                rc.username,
                rc.password,
                rc.email,
                rc.icon,
                rc.friendcode,
                rc.securityLevel,
                rc.verified
            );

            if(!prc.securityValidation) {
                prc.responseObj.message = 'Username/email already taken. Please use another.';
            }
        }

        if(!prc.responseObj.message.len()) {
            prc.trainerid = parseNumber(rc.trainerid);
            prc.verified  = rc.verified.len() ? rc.verified == 'on' ? 'true' : 'false' : '';

            securityService.update(
                trainerid     = prc.trainerid,
                username      = rc.username,
                password      = rc.password,
                email         = rc.email,
                icon          = rc.icon,
                friendcode    = rc.friendcode,
                securityLevel = rc.securityLevel,
                verified      = prc.verified
            );

            if(prc.trainerid == session.trainerid) {
                // Update settings
                prc.trainer = trainerService.getFromId(prc.trainerid);
                trainerService.updateSettings(
                    prc.trainer,
                    {
                        'defaultView'  : rc.defaultView,
                        'defaultRegion': rc.defaultRegion,
                        'defaultPage'  : rc.defaultPage
                    }
                );

                // Refresh current session
                sessionService.update(prc.trainerid);
            }

            prc.responseObj.success    = true;
            prc.responseObj.statusCode = 200;
        }

        event.renderData(
            type       = 'json',
            data       = prc.responseObj,
            statusCode = prc.responseObj.statusCode
        );
    }

}
