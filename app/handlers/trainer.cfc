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
        prc.statStruct = trainerService.getCurrentLevel(trainerid = prc.trainer.id);
    }

    /**
     * Edit profile form
     */
    function editProfile(event, rc, prc) {
        prc.trainer       = trainerService.getFromId(trainerid = prc.oCurrentUser.getId());
        prc.baseIcons     = trainerService.getIconMap();
        prc.unlockedIcons = trainerService.getUnlockedIcons(trainerid = prc.trainer.id);

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
     * Changing your own email unverifies you until you enter the code sent to it (reverify in the response)
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
        param name="rc.commentBanned"   default="";
        param name="rc.defaultView"     default="";
        param name="rc.defaultRegion"   default="";
        param name="rc.defaultPage"     default="";

        prc.validation = validate(target = rc, constraints = "trainer.updateProfile");
        if(prc.validation.hasErrors()) {
            prc.responseObj.message    = profileErrorMessage(validation = prc.validation);
            prc.responseObj.statusCode = 400;
        }
        else {
            prc.trainerid     = parseNumber(rc.trainerid);
            prc.verified      = rc.verified.len() ? rc.verified == "on" ? "true" : "false" : "";
            prc.commentbanned = rc.commentBanned.len() ? rc.commentBanned == "on" ? "true" : "false" : "";

            try {
                prc.reverify = accountService.updateTrainer(
                    trainerid     = prc.trainerid,
                    username      = rc.username,
                    password      = rc.password,
                    email         = rc.email,
                    icon          = rc.icon,
                    friendcode    = rc.friendcode,
                    securityLevel = rc.securityLevel,
                    verified      = prc.verified,
                    commentbanned = prc.commentbanned,
                    // A trainer changing their own email confirms the new one - an admin changing someone else's sets verified themselves
                    reverifyEmail = prc.trainerid == prc.oCurrentUser.getId()
                );
            }
            catch(UniqueViolation e) {
                // Username, email or friendcode already taken
                prc.responseObj.message    = e.message;
                prc.responseObj.statusCode = 409;
                renderJson(event = event, response = prc.responseObj);
                return;
            }

            // A password change signs out the trainer's sessions - keep this one when they changed their own
            if(rc.password.len() && prc.trainerid == prc.oCurrentUser.getId()) {
                sessionService.keepVersion(
                    sessionVersion = trainerService.getFromId(trainerid = prc.trainerid).sessionversion
                );
            }

            trainerService.updateSettings(
                trainerid = prc.trainerid,
                settings  = {
                    "defaultView"  : rc.defaultView,
                    "defaultRegion": rc.defaultRegion,
                    "defaultPage"  : rc.defaultPage
                }
            );

            prc.responseObj.success    = true;
            prc.responseObj.statusCode = 200;
            // The page sends them to /verify, where the code sent to the new email is entered
            prc.responseObj.reverify   = prc.reverify;
        }

        renderJson(event = event, response = prc.responseObj);
    }

    /**
     * Message for a failed profile update - the first that applies:
     * - any error without a custom message in trainer.updateProfile -> verify all fields
     * - a security check (another trainer, an admin only field, a trainer who outranks you) -> NotAuthorized, a 403 from error.onException
     * - the custom message, your current password first, then your icon, then an in use field
     *
     * @validation trainer.updateProfile validation result
     */
    private string function profileErrorMessage(required any validation) {
        var constraints  = arguments.validation.getConstraints();
        var unauthorized = [];
        var custom       = [];
        for(var error in arguments.validation.getErrors()) {
            if(error.getValidationType() == "securityCheck") {
                unauthorized.append(error.getMessage());
            }
            else if(constraints[error.getField()].keyExists("#error.getValidationType()#Message")) {
                custom.append(error);
            }
            else {
                return "Invalid profile update. Please verify all fields.";
            }
        }

        // Every failed check goes in the message, so the audit shows all of what was attempted
        if(unauthorized.len()) {
            cbSecure().secureWhen(true, unauthorized.toList("; "));
        }
        for(var field in ["currentPassword", "icon"]) {
            var index = custom.find((error) => error.getField() == field);
            if(index) {
                return custom[index].getMessage();
            }
        }
        return custom[1].getMessage();
    }

}
