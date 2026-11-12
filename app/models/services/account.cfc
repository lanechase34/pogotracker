component singleton accessors="true" {

    property name="domain"         inject="coldbox:setting:domain";
    property name="emailService"   inject="services.email";
    property name="flash"          inject="coldbox:flash";
    property name="permissions"    inject="coldbox:setting:permissions";
    property name="persistService" inject="services.persist";
    property name="securityLevels" inject="coldbox:setting:securityLevels";
    property name="trainerService" inject="services.trainer";
    property name="userService"    inject="services.user";
    property name="utilService"    inject="services.util";

    property name="resetPasswordLifespan" inject="coldbox:setting:resetPasswordLifespan";
    property name="resetPasswordCooldown" inject="coldbox:setting:resetPasswordCooldown";
    property name="verificationLifespan"  inject="coldbox:setting:verificationLifespan";
    property name="verificationCooldown"  inject="coldbox:setting:verificationCooldown";

    property name="hashing" inject="coldbox:setting:hashing" getter="false" setter="false";

    // Unverified trainers sit at this level, verifying moves them to VERIFIED_LEVEL
    variables.UNVERIFIED_LEVEL = 5;
    variables.VERIFIED_LEVEL   = 10;

    /**
     * Registers a new (unverified) trainer
     * Throws UniqueViolation when the username/email/friendcode was taken after validation ran
     *
     * @return the new trainer entity
     */
    public component function register(
        required string username,
        required string password,
        required string email,
        required string friendcode,
        required string icon
    ) {
        var passInfo = userService.hashPassword(arguments.password);

        var newTrainer = entityNew(
            "trainer",
            {
                email        : userService.normalizeEmail(arguments.email),
                username     : userService.normalizeUsername(arguments.username),
                friendcode   : arguments.friendcode,
                icon         : arguments.icon,
                password     : passInfo.hashedPassword,
                salt         : passInfo.salt,
                securityLevel: variables.UNVERIFIED_LEVEL,
                verified     : false
            }
        );

        try {
            entitySave(newTrainer);
            ormFlush();
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }
        return newTrainer;
    }

    /**
     * Updates a trainer's information
     * Password or privilege changes revoke all remember me cookies for this trainer
     * A password change also signs out every session they have open
     * The unverified security level and verified flag are kept in step:
     * - changing the level to unverified unverifies them, changing it from unverified verifies them
     * - otherwise verifying a trainer at the unverified level moves them to the verified level
     */
    public void function update(
        required numeric trainerid,
        required string username,
        required string password,
        required string email,
        required string icon,
        string friendcode,
        string securityLevel,
        string verified
    ) {
        // Load a fresh copy so the save happens in this orm session
        trainerService.clearCache(arguments.trainerid);

        var trainer = trainerService.getFromId(arguments.trainerid);
        trainer.setUsername(userService.normalizeUsername(arguments.username));
        trainer.setEmail(userService.normalizeEmail(arguments.email));
        trainer.setIcon(arguments.icon);

        var revokePersist = false;

        if(arguments.password.len()) {
            var passInfo = userService.hashPassword(arguments.password);
            trainer.setPassword(passInfo.hashedPassword);
            trainer.setSalt(passInfo.salt);
            trainer.setSessionVersion(val(trainer.getSessionVersion()) + 1);
            revokePersist = true;
        }

        if(arguments.keyExists("friendcode") && arguments.friendcode.len()) {
            trainer.setFriendcode(arguments.friendcode);
        }

        var levelBefore    = val(trainer.getSecurityLevel());
        var verifiedBefore = trainer.getVerified() ?: false;
        var level          = levelBefore;
        var verified       = verifiedBefore;

        if(arguments.keyExists("verified") && arguments.verified.len()) {
            verified = booleanFormat(arguments.verified);
        }

        if(arguments.keyExists("securityLevel") && arguments.securityLevel.len()) {
            level = val(arguments.securityLevel);
        }

        if(level != levelBefore && (level == variables.UNVERIFIED_LEVEL || levelBefore == variables.UNVERIFIED_LEVEL)) {
            verified = level != variables.UNVERIFIED_LEVEL;
        }
        else if(verified && level == variables.UNVERIFIED_LEVEL) {
            level = variables.VERIFIED_LEVEL;
        }
        else if(level == variables.UNVERIFIED_LEVEL) {
            verified = false;
        }

        if(level != levelBefore || verified != verifiedBefore) {
            revokePersist = true;
        }
        trainer.setSecurityLevel(level);
        trainer.setVerified(verified);

        try {
            entitySave(trainer);
            ormFlush();
        }
        catch(any e) {
            // The cached trainer holds the rejected values - drop it so the next load reads the database
            trainerService.clearCache(trainer.getId());
            utilService.rethrowUniqueViolation(e);
        }

        // Permissions are read from the trainer on every request, so this takes effect immediately
        trainerService.clearCache(trainer.getId());

        if(revokePersist) {
            persistService.revokeAll(trainer.getId());
        }

        return;
    }

    /**
     * Security levels that can be given through a profile update - everything below developer
     * Developer is never assignable from the app, it can only be set in the database
     *
     * @return struct of level -> display name
     */
    public struct function getAssignableLevels() {
        var developerLevel = getPermissions().developer;
        return getSecurityLevels().filter((level) => val(level) < developerLevel);
    }

    /**
     * Validate the values of a profile update - valid options and unique username/email/friendcode
     * Whether the caller may edit these fields is checked by cbsecurity in trainer.updateProfile
     */
    public boolean function validateUpdateProfile(
        required string trainerid,
        required string username,
        required string email,
        required string friendcode,
        required string securityLevel,
        required string verified
    ) {
        var trainer = trainerService.getFromId(parseNumber(arguments.trainerid));

        var checkBoxOptions = ["off", "on"];
        if(
            (arguments.securityLevel.len() && !getAssignableLevels().keyExists(arguments.securityLevel)) ||
            (arguments.verified.len() && !checkBoxOptions.contains(arguments.verified))
        ) {
            return false;
        }

        // Make sure email is unique
        var emailOwner = userService.findByEmail(arguments.email);
        if(!isNull(emailOwner) && emailOwner.getId() != trainer.getId()) {
            return false;
        }

        // Make sure username is unique ignoring case - lower() matches unq_trainer_lower_username so the index is used
        var usernameOwners = ormExecuteQuery(
            "from trainer where lower(username) = :username and id != :trainerid",
            {username: lCase(userService.normalizeUsername(arguments.username)), trainerid: trainer.getId()}
        );
        if(usernameOwners.len()) {
            return false;
        }

        // Make sure friendcode is unique
        if(arguments.friendcode.len() && arguments.friendcode != trainer.getFriendcode()) {
            if(entityLoad("trainer", {"friendcode": arguments.friendcode}).len()) {
                return false;
            }
        }

        return true;
    }

    /**
     * Send a verification code to the supplied email
     *
     * @email  email to send to
     * @resend If true, attempt to resend this code (may fail based on when last code was requested)
     */
    public void function sendVerificationCode(required string email, required boolean resend = false) {
        var trainer = userService.findByEmail(arguments.email);
        if(isNull(trainer)) return;

        if(arguments.resend) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Please wait #int(getVerificationCooldown() / 60)# minutes before resending the verification code."
                }
            );
        }

        // If code has not been sent or
        // previous sent code expired or
        // force resend (must wait verificationCooldown from previous code)
        if(
            isNull(trainer.getVerificationSentDate()) ||
            isNull(trainer.getVerificationCode()) ||
            dateDiff("n", trainer.getVerificationSentDate(), now()) > getVerificationLifespan() ||
            (arguments.resend && dateDiff("s", trainer.getVerificationSentDate(), now()) > getVerificationCooldown())
        ) {
            var verificationInfo = createVerificationCode(trainer);
            var expires          = dateAdd(
                "n",
                getVerificationLifespan(),
                verificationInfo.sent
            );

            emailService.sendVerificationCode(
                arguments.email,
                verificationInfo.code,
                expires,
                getVerificationLifespan()
            );

            if(arguments.resend) {
                flash.put(
                    name  = "alert",
                    value = {
                        "type"       : "success",
                        "dismissible": true,
                        "icon"       : "bi-check-square-fill",
                        "message"    : "Verification code resent!"
                    }
                );
            }
        }

        return;
    }

    /**
     * Check the supplied verification code against the trainer (loaded by email)
     * On success the trainer becomes a verified regular user
     *
     * @email trainer's email
     * @code  user entered verification code
     */
    public boolean function checkVerificationCode(required string email, required string code) {
        // Codes are generated uppercase and the hash below is case sensitive - accept them typed in any case
        arguments.code = uCase(trim(arguments.code));

        // 1. Check this is a valid session
        if(!session.keyExists("verificationCode") || session.verificationCode != arguments.code) {
            return false;
        }

        // 2. Check the code has not expired
        var trainer = userService.findByEmail(arguments.email);
        if(
            isNull(trainer) ||
            isNull(trainer.getVerificationSentDate()) ||
            dateDiff("n", trainer.getVerificationSentDate(), now()) > getVerificationLifespan()
        ) {
            return false;
        }

        // 3. Check the code against value hashed in DB
        if(trainer.getVerificationCode() != hashCode(arguments.code & session.sessionid)) {
            return false;
        }

        // Passed verification
        session.delete("verificationCode");
        trainer.setVerificationCode("");
        trainer.setVerified(true);
        trainer.setSecurityLevel(variables.VERIFIED_LEVEL);
        entitySave(trainer);
        ormFlush();
        trainerService.clearCache(trainer.getId());

        return true;
    }

    /**
     * Allow the trainer to create a new reset password link and send it to their email
     *
     * @email trainer's email
     */
    public void function sendResetCode(required string email) {
        var trainer = userService.findByEmail(arguments.email);
        if(isNull(trainer)) return;

        if(
            isNull(trainer.getResetSentDate()) ||
            isNull(trainer.getResetCode()) ||
            dateDiff("n", trainer.getResetSentDate(), now()) > getResetPasswordLifespan() ||
            dateDiff("s", trainer.getResetSentDate(), now()) > getResetPasswordCooldown()
        ) {
            var resetLinkInfo = createResetLink(trainer);
            var expires       = dateAdd(
                "n",
                getResetPasswordLifespan(),
                resetLinkInfo.sent
            );

            emailService.sendResetCode(
                arguments.email,
                resetLinkInfo.link,
                expires,
                getResetPasswordLifespan()
            );
        }

        return;
    }

    /**
     * Check the validity of this reset code by attempting to load the trainer it's attached to
     *
     * @resetCode user entered code
     * @delete    t/f will delete code associated to user if true
     *
     * @return the trainer's email, empty if the code is invalid or expired
     */
    public string function checkResetCode(required string resetCode, boolean delete = false) {
        var trainer = entityLoad(
            "trainer",
            {"resetCode": hashCode(arguments.resetCode), "verified": true},
            true
        );

        if(isNull(trainer)) {
            return "";
        }

        // Link was expired
        if(dateDiff("n", trainer.getResetSentDate(), now()) > getResetPasswordLifespan()) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Link has expired. Please request a new link"
                }
            );
            return "";
        }

        if(arguments.delete) {
            trainer.setResetCode("");
            entitySave(trainer);
            ormFlush();
        }

        return trainer.getEmail();
    }

    /**
     * Create a verification code and assign to session, trainer record
     */
    private struct function createVerificationCode(required component trainer) {
        // Generate 8-character verification code
        var verificationCode = left(replace(createUUID(), "-", "", "all"), 8).uCase();

        session.verificationCode = verificationCode;

        arguments.trainer.setVerificationCode(hashCode(verificationCode & session.sessionid));
        arguments.trainer.setVerificationSentDate(now());

        entitySave(arguments.trainer);
        ormFlush();

        return {code: verificationCode, sent: now()};
    }

    /**
     * Create a unique link that is tied to a trainer that will allow them to access the reset password form
     */
    private struct function createResetLink(required component trainer) {
        var resetCode = encodeForURL(generateSecretKey("AES", 256).replace("/", "", "all").left(25)).replace(
            "%",
            "",
            "all"
        );

        arguments.trainer.setResetCode(hashCode(resetCode));
        arguments.trainer.setResetSentDate(now());

        entitySave(arguments.trainer);
        ormFlush();

        return {link: "#getDomain()#/reset/#resetCode#", sent: now()};
    }

    /**
     * Peppered hash used for verification and reset codes stored in the database
     */
    private string function hashCode(required string value) {
        return hash(
            arguments.value & variables.hashing.pepper,
            variables.hashing.algorithm,
            variables.hashing.encoding,
            variables.hashing.iterations
        );
    }

}
