component extends="base" secured="user" {

    this.allowedMethods = {
        viewProfile  : "GET",
        editProfile  : "GET",
        updateProfile: "POST"
    };

    property name="generationService" inject="services.generation";
    property name="accountService"    inject="services.account";
    property name="sessionService"    inject="services.session";
    property name="trainerService"    inject="services.trainer";
    property name="userService"       inject="services.user";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = "Profile | #getSetting("title")#";
        prc.metaDescription = "View your profile, friend requests, Pokedex summary, Stats summary, medal overview, and more.";
        prc.metaRobots      = "noindex, nofollow";
    }

    /**
     * View a trainer's profile
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function viewProfile(event, rc, prc) {
        rc.trainerid  = rc?.trainerid ?: prc.oCurrentUser.getId();
        prc.myProfile = rc.trainerid == prc.oCurrentUser.getId();

        // If you are visiting someone else's profile, check that you are friends with them
        if(!prc.myProfile && hasValidationErrors(target = rc, constraints = "trainer.viewProfile")) {
            htmlValidationFailure(event = event, redirectUri = "/profile");
            return;
        }

        // Set up for profile cards
        prc.startDate = dateFormat(createDate(year(now()), month(now()), 1), "MM-DD-YYYY");
        prc.endDate   = dateFormat(
            createDate(
                year(now()),
                month(now()),
                daysInMonth(prc.startDate)
            ),
            "MM-DD-YYYY"
        );

        prc.trainer    = trainerService.getFromId(trainerid = rc.trainerid);
        prc.statStruct = prc.trainer.getCurrentLevel();
    }

    /**
     * Edit profile form
     */
    function editProfile(event, rc, prc) {
        prc.trainer       = prc.oCurrentUser;
        prc.baseIcons     = trainerService.getIconMap();
        prc.unlockedIcons = prc.trainer.getUnlockedIcons();

        event.setView(
            view     = "/views/trainer/modal/editProfile",
            nolayout = true,
            args     = {
                trainer    : prc.trainer,
                iconMap    : arrayMerge(prc.baseIcons, prc.unlockedIcons),
                settings   : prc.oCurrentUser.getSettings(),
                viewMap    : getSetting("viewMap"),
                generations: generationService.getAll(),
                pageMap    : getSetting("pageMap")
            }
        );
    }

    /**
     * Update profile endpoint
     * Trainers edit their own profile, admins can edit anyone's plus friendcode, security level and verified
     * Changing your own email or password needs your current password
     * Returns JSON
     */
    function updateProfile(event, rc, prc) {
        param name="rc.trainerid"       default="";
        param name="rc.username"        default="";
        param name="rc.password"        default="";
        param name="rc.currentPassword" default="";
        param name="rc.email"           default="";
        param name="rc.icon"            default="";
        param name="rc.friendcode"      default="";
        param name="rc.securityLevel"   default="";
        param name="rc.verified"        default="";
        param name="rc.defaultView"     default="";
        param name="rc.defaultRegion"   default="";
        param name="rc.defaultPage"     default="";

        prc.validation = validate(target = rc, constraints = "trainer.updateProfile");
        if(prc.validation.hasErrors()) {
            prc.responseObj.message = "Invalid profile update. Please verify all fields.";
        }
        else {
            var target = trainerService.getFromId(parseNumber(rc.trainerid));

            // Only admins may edit other trainers or the admin only fields - NotAuthorized -> 403 (error.onException)
            cbSecure().secureWhen((user) => !user.hasPermission("admin") && (
                target.getId() != user.getId()
                || rc.friendcode.len()
                || rc.securityLevel.len()
                || rc.verified.len()
            ), "Only admins can edit other trainers or their friend code, security level, and verification");

            // No one edits an account that outranks them
            cbSecure().secureWhen((user) => target.getId() != user.getId() && val(target.getSecurityLevel()) > val(user.getSecurityLevel()), "You can't edit a trainer with a higher security level than your own");

            // Your own email or password - prove it's you first
            var credentialChange = rc.password.len() || lCase(trim(rc.email)) != lCase(target.getEmail());
            if(
                target.getId() == prc.oCurrentUser.getId()
                && credentialChange
                && !userService.checkPassword(target, rc.currentPassword)
            ) {
                prc.responseObj.message = "Current password is incorrect.";
            }
            // Only icons the edit form offers this trainer - base icons plus their unlocked ones
            else if(!trainerService.isAllowedIcon(rc.icon, target)) {
                prc.responseObj.message = "Invalid profile update. That icon is not unlocked.";
            }
        }

        if(!prc.responseObj.message.len()) {
            prc.securityValidation = accountService.validateUpdateProfile(
                trainerid     = rc.trainerid,
                username      = rc.username,
                email         = rc.email,
                friendcode    = rc.friendcode,
                securityLevel = rc.securityLevel,
                verified      = rc.verified
            );

            if(!prc.securityValidation) {
                prc.responseObj.message = "Username/email already taken. Please use another.";
            }
        }

        if(!prc.responseObj.message.len()) {
            prc.trainerid = parseNumber(rc.trainerid);
            prc.verified  = rc.verified.len() ? rc.verified == "on" ? "true" : "false" : "";

            try {
                accountService.update(
                    trainerid     = prc.trainerid,
                    username      = rc.username,
                    password      = rc.password,
                    email         = rc.email,
                    icon          = rc.icon,
                    friendcode    = rc.friendcode,
                    securityLevel = rc.securityLevel,
                    verified      = prc.verified
                );
            }
            catch(UniqueViolation e) {
                prc.responseObj.message = e.message;
                renderJson(event = event, response = prc.responseObj);
                return;
            }

            // A password change signs out the trainer's sessions - keep this one when they changed their own
            if(rc.password.len() && prc.trainerid == prc.oCurrentUser.getId()) {
                sessionService.keepVersion(trainerService.getFromId(prc.trainerid));
            }

            // Permission was checked above - the cached trainer was refreshed by update()
            trainerService.updateSettings(
                trainerService.getFromId(prc.trainerid),
                {
                    "defaultView"  : rc.defaultView,
                    "defaultRegion": rc.defaultRegion,
                    "defaultPage"  : rc.defaultPage
                }
            );

            prc.responseObj.success    = true;
            prc.responseObj.statusCode = 200;
        }

        renderJson(event = event, response = prc.responseObj);
    }

}
