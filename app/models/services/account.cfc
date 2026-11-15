component singleton accessors="true" {

    property name="bcrypt"         inject="@BCrypt";
    property name="domain"         inject="coldbox:setting:domain";
    property name="emailService"   inject="services.email";
    property name="flash"          inject="coldbox:flash";
    property name="persistService" inject="services.persist";
    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

    property name="resetPasswordLifespan" inject="coldbox:setting:resetPasswordLifespan";
    property name="resetPasswordCooldown" inject="coldbox:setting:resetPasswordCooldown";
    property name="verificationLifespan"  inject="coldbox:setting:verificationLifespan";
    property name="verificationCooldown"  inject="coldbox:setting:verificationCooldown";

    // Unverified trainers sit at this level, verifying moves them to VERIFIED_LEVEL
    variables.UNVERIFIED_LEVEL = 5;
    variables.VERIFIED_LEVEL   = 10;

    /**
     * Registers a new (unverified) trainer
     * Throws UniqueViolation when the username/email/friendcode was taken after validation ran
     *
     * @return the new trainer (trainerService.getFromId)
     */
    public struct function register(
        required string username,
        required string password,
        required string email,
        required string friendcode,
        required string icon
    ) {
        var params = {
            email        : {value: trainerService.normalizeEmail(arguments.email), cfsqltype: "varchar"},
            username     : {value: trainerService.normalizeUsername(arguments.username), cfsqltype: "varchar"},
            friendcode   : {value: arguments.friendcode, cfsqltype: "varchar"},
            icon         : {value: arguments.icon, cfsqltype: "varchar"},
            securitylevel: {value: variables.UNVERIFIED_LEVEL, cfsqltype: "integer"}
        };
        params.append(passwordParams(arguments.password));

        try {
            var trainerid = queryExecute(
                "
                INSERT INTO trainer (email, username, friendcode, icon, password, salt, securitylevel, verified)
                VALUES (:email, :username, :friendcode, :icon, :password, :salt, :securitylevel, false)
                RETURNING id
                ",
                params
            ).id;
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }
        return trainerService.getFromId(trainerid);
    }

    /**
     * Updates a trainer's information
     * Password or privilege changes revoke all remember me cookies for this trainer
     * A password change also signs out every session they have open
     * The security level and verified flag are kept in step (see resolveAccess)
     * commentbanned - "true"/"false", blank leaves it as it is
     *
     * @reverifyEmail a new email unverifies the trainer and sends a code to it - for trainers changing their own
     *
     * @return true when the trainer now has to verify their new email
     */
    public boolean function updateTrainer(
        required numeric trainerid,
        required string username,
        required string password,
        required string email,
        required string icon,
        string friendcode,
        string securityLevel,
        string verified,
        string commentbanned,
        boolean reverifyEmail = false
    ) {
        // A fresh read - the level and verified flag below are worked out from what is saved now
        trainerService.clearCache(arguments.trainerid);
        var trainer = trainerService.getFromId(arguments.trainerid);

        var sets = [
            "username = :username",
            "email = :email",
            "icon = :icon",
            "securitylevel = :securitylevel",
            "verified = :verified"
        ];
        var params = {
            trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
            username : {value: trainerService.normalizeUsername(arguments.username), cfsqltype: "varchar"},
            email    : {value: trainerService.normalizeEmail(arguments.email), cfsqltype: "varchar"},
            icon     : {value: arguments.icon, cfsqltype: "varchar"}
        };

        var passwordChanged = arguments.password.len() > 0;
        if(passwordChanged) {
            sets.append(
                [
                    "password = :password",
                    "salt = :salt",
                    "sessionversion = sessionversion + 1"
                ],
                true
            );
            params.append(passwordParams(arguments.password));
        }

        // A reset link already sent (maybe to an old, compromised inbox) stops working once the password or email changes
        var emailChanged = params.email.value != trainerService.normalizeEmail(trainer.email ?: "");
        if(passwordChanged || emailChanged) {
            sets.append("resetcode = ''");
        }

        if((arguments.friendcode ?: "").len()) {
            sets.append("friendcode = :friendcode");
            params.friendcode = {value: arguments.friendcode, cfsqltype: "varchar"};
        }

        // Admin only - set when an admin deletes one of the trainer's comments
        if((arguments.commentbanned ?: "").len()) {
            sets.append("commentbanned = :commentbanned");
            params.commentbanned = {value: booleanFormat(arguments.commentbanned), cfsqltype: "boolean"};
        }

        // Nobody has confirmed the new inbox yet
        var reverify = emailChanged && arguments.reverifyEmail;

        var access = resolveAccess(
            currentLevel      = val(trainer.securitylevel),
            currentVerified   = trainer.verified ? true : false,
            requestedLevel    = arguments.securityLevel ?: "",
            requestedVerified = reverify ? "false" : (arguments.verified ?: "")
        );
        params.securitylevel = {value: access.securitylevel, cfsqltype: "integer"};
        params.verified      = {value: access.verified, cfsqltype: "boolean"};

        try {
            queryExecute("UPDATE trainer SET #sets.toList(", ")# WHERE id = :trainerid", params);
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }

        // Permissions are read from the trainer on every request, so this takes effect immediately
        trainerService.clearCache(arguments.trainerid);

        if(passwordChanged || access.changed) {
            persistService.revokeAll(arguments.trainerid);
        }

        if(reverify) {
            sendVerificationCode(email = params.email.value, resend = false);
        }

        return reverify;
    }

    /**
     * Send a verification code to the supplied email
     * A new code goes out when none is active, or on resend once the cooldown has passed
     *
     * @email  email to send to
     * @resend If true, attempt to resend this code (may fail based on when last code was requested)
     */
    public void function sendVerificationCode(required string email, required boolean resend = false) {
        var trainer = findCredentialsByEmail(arguments.email);
        if(isNull(trainer)) return;

        // Replaced by the success alert below when the code is actually resent
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

        var needsCode = !len(trainer.verificationcode)
        || hasExpired(trainer.verificationsentdate, getVerificationLifespan())
        || (arguments.resend && cooldownPassed(trainer.verificationsentdate, getVerificationCooldown()));
        if(!needsCode) return;

        var verificationInfo = createVerificationCode(trainer.id);
        emailService.sendVerificationCode(
            arguments.email,
            verificationInfo.code,
            dateAdd(
                "n",
                getVerificationLifespan(),
                verificationInfo.sent
            ),
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

        return;
    }

    /**
     * Check the supplied verification code against the trainer (loaded by email)
     * On success the trainer becomes verified - at least a regular user, a higher level re-verifying an email keeps it
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
        var trainer = findCredentialsByEmail(arguments.email);
        if(isNull(trainer) || hasExpired(trainer.verificationsentdate, getVerificationLifespan())) {
            return false;
        }

        // 3. Check the code against value hashed in DB
        if(trainer.verificationcode != hashVerificationCode(arguments.code)) {
            return false;
        }

        // Passed verification
        session.delete("verificationCode");
        queryExecute(
            "UPDATE trainer SET verificationcode = '', verified = true, securitylevel = GREATEST(securitylevel, :level) WHERE id = :trainerid",
            {
                level    : {value: variables.VERIFIED_LEVEL, cfsqltype: "integer"},
                trainerid: {value: trainer.id, cfsqltype: "integer"}
            }
        );
        trainerService.clearCache(trainer.id);

        return true;
    }

    /**
     * Allow the trainer to create a new reset password link and send it to their email
     * A new link goes out when none is active or the cooldown has passed
     *
     * @email trainer's email
     */
    public void function sendResetCode(required string email) {
        var trainer = findCredentialsByEmail(arguments.email);
        if(isNull(trainer)) return;

        var needsCode = !len(trainer.resetcode)
        || hasExpired(trainer.resetsentdate, getResetPasswordLifespan())
        || cooldownPassed(trainer.resetsentdate, getResetPasswordCooldown());
        if(!needsCode) return;

        var resetLinkInfo = createResetLink(trainer.id);
        emailService.sendResetCode(
            arguments.email,
            resetLinkInfo.link,
            dateAdd(
                "n",
                getResetPasswordLifespan(),
                resetLinkInfo.sent
            ),
            getResetPasswordLifespan()
        );

        return;
    }

    /**
     * Check the validity of this reset code by attempting to load the trainer it's attached to
     *
     * @resetCode user entered code
     * @clearCode t/f clears the reset code from the trainer when true
     *
     * @return the trainer's email, empty if the code is invalid or expired
     */
    public string function checkResetCode(required string resetCode, boolean clearCode = false) {
        var trainer = findCredentials(
            // resetcode <> '' matches the partial index (idx_trainer_resetcode) so it is used
            "resetcode = :resetcode AND resetcode <> '' AND verified = true",
            {resetcode: {value: utilService.pepperedHash(arguments.resetCode), cfsqltype: "varchar"}}
        );

        if(isNull(trainer)) {
            return "";
        }

        if(hasExpired(trainer.resetsentdate, getResetPasswordLifespan())) {
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

        if(arguments.clearCode) {
            queryExecute(
                "UPDATE trainer SET resetcode = '' WHERE id = :trainerid",
                {trainerid: {value: trainer.id, cfsqltype: "integer"}}
            );
        }

        return trainer.email;
    }

    /**
     * Check a trainer's email and password for login
     * Legacy hashes are upgraded to bcrypt on a successful check
     * An unknown email still costs one bcrypt check, so it takes as long as a real one
     *
     * @email            trainer's email
     * @password         user entered password
     * @allowAnyPassword accept any password for an existing trainer (impersonation)
     */
    public boolean function checkLogin(
        required string email,
        required string password,
        boolean allowAnyPassword = false
    ) {
        var credentials = findCredentialsByEmail(arguments.email);

        if(isNull(credentials)) {
            // Dummy password check
            bcrypt.checkPassword(candidate = arguments.password, bCryptHash = getDummyHash());
            return false;
        }

        var verified = verifyPassword(arguments.password, credentials);

        // Upgrade legacy hashes to bcrypt now that we have the plain text password
        if(verified && !isBcryptHash(credentials.password)) {
            var params       = passwordParams(arguments.password);
            params.trainerid = {value: credentials.id, cfsqltype: "integer"};
            queryExecute("UPDATE trainer SET password = :password, salt = :salt WHERE id = :trainerid", params);
            trainerService.clearCache(credentials.id);
        }

        return verified || arguments.allowAnyPassword;
    }

    /**
     * Check a trainer's current password - impersonation never applies
     * Used to confirm it's really the trainer before they change their email or password
     *
     * @trainerid trainer pk
     * @password  user entered password
     */
    public boolean function checkPassword(required numeric trainerid, required string password) {
        if(!arguments.password.len()) {
            return false;
        }
        var credentials = findCredentials(
            "id = :trainerid",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
        );
        return !isNull(credentials) && verifyPassword(arguments.password, credentials);
    }

    /**
     * Work out the security level and verified flag to save, keeping the two in step:
     * - changing the level to unverified unverifies them, changing it from unverified verifies them
     * - otherwise verifying a trainer at the unverified level moves them to the verified level
     * - a trainer left at the unverified level is never verified
     *
     * @currentLevel      saved security level
     * @currentVerified   saved verified flag
     * @requestedLevel    new security level, empty to keep the saved one
     * @requestedVerified new verified flag, empty to keep the saved one
     *
     * @return {securitylevel, verified, changed} - changed is true when either differs from what is saved
     */
    private struct function resolveAccess(
        required numeric currentLevel,
        required boolean currentVerified,
        required string requestedLevel,
        required string requestedVerified
    ) {
        var level    = arguments.requestedLevel.len() ? val(arguments.requestedLevel) : arguments.currentLevel;
        var verified = arguments.requestedVerified.len() ? booleanFormat(arguments.requestedVerified) : arguments.currentVerified;

        var levelChanged      = level != arguments.currentLevel;
        var crossesUnverified = level == variables.UNVERIFIED_LEVEL || arguments.currentLevel == variables.UNVERIFIED_LEVEL;

        if(levelChanged && crossesUnverified) {
            verified = level != variables.UNVERIFIED_LEVEL;
        }
        else if(verified && level == variables.UNVERIFIED_LEVEL) {
            level = variables.VERIFIED_LEVEL;
        }
        else if(level == variables.UNVERIFIED_LEVEL) {
            verified = false;
        }

        verified = verified ? true : false;
        return {
            securitylevel: level,
            verified     : verified,
            changed      : level != arguments.currentLevel || verified != arguments.currentVerified
        };
    }

    /**
     * A trainer's secrets - id, email, password, salt and the verification/reset codes and when they were sent
     * Kept out of the trainer struct, which is cached and handed to views
     * Null columns come back as empty strings
     *
     * @whereSQL condition on the trainer table, with named params
     * @params   query params for whereSQL
     *
     * @return struct, or null when no trainer matches
     */
    private any function findCredentials(required string whereSQL, required struct params) {
        var rows = queryExecute(
            "
            SELECT id, email, verified, COALESCE(password, '') AS password, COALESCE(salt, '') AS salt,
                COALESCE(verificationcode, '') AS verificationcode, verificationsentdate,
                COALESCE(resetcode, '') AS resetcode, resetsentdate
            FROM trainer
            WHERE #arguments.whereSQL#
            LIMIT 1
            ",
            arguments.params,
            {returnType: "array"}
        );
        return utilService.firstRow(rows);
    }

    /**
     * The trainer's secrets (findCredentials) by email, null when no trainer has it
     *
     * @email trainer's email
     */
    private any function findCredentialsByEmail(required string email) {
        return findCredentials(
            "email = :email",
            {email: {value: trainerService.normalizeEmail(arguments.email), cfsqltype: "varchar"}}
        );
    }

    /**
     * Create a verification code and assign to session, trainer record
     *
     * @trainerid trainer pk
     *
     * @return {code, sent}
     */
    private struct function createVerificationCode(required numeric trainerid) {
        // 8-character uppercase code
        var verificationCode = left(replace(createUUID(), "-", "", "all"), 8).uCase();
        var sent             = now();

        session.verificationCode = verificationCode;

        queryExecute(
            "UPDATE trainer SET verificationcode = :code, verificationsentdate = :sent WHERE id = :trainerid",
            {
                code     : {value: hashVerificationCode(verificationCode), cfsqltype: "varchar"},
                sent     : {value: sent, cfsqltype: "timestamp"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
            }
        );

        return {code: verificationCode, sent: sent};
    }

    /**
     * Create a unique link that is tied to a trainer that will allow them to access the reset password form
     *
     * @trainerid trainer pk
     *
     * @return {link, sent}
     */
    private struct function createResetLink(required numeric trainerid) {
        // 25 random characters, with anything that would need URL encoding dropped
        var secret    = generateSecretKey("AES", 256).replace("/", "", "all").left(25);
        var resetCode = encodeForURL(secret).replace("%", "", "all");
        var sent      = now();

        queryExecute(
            "UPDATE trainer SET resetcode = :code, resetsentdate = :sent WHERE id = :trainerid",
            {
                code     : {value: utilService.pepperedHash(resetCode), cfsqltype: "varchar"},
                sent     : {value: sent, cfsqltype: "timestamp"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
            }
        );

        return {link: "#getDomain()#/reset/#resetCode#", sent: sent};
    }

    /**
     * True when a code sent at this time is past its lifespan, or was never sent
     *
     * @sent            when the code was sent (empty when never sent)
     * @lifespanMinutes how long the code is valid for
     */
    private boolean function hasExpired(required any sent, required numeric lifespanMinutes) {
        return !isDate(arguments.sent) || dateDiff("n", arguments.sent, now()) > arguments.lifespanMinutes;
    }

    /**
     * True when enough time has passed since a code was sent to send another
     *
     * @sent            when the code was sent
     * @cooldownSeconds wait required between codes
     */
    private boolean function cooldownPassed(required date sent, required numeric cooldownSeconds) {
        return dateDiff("s", arguments.sent, now()) > arguments.cooldownSeconds;
    }

    /**
     * The password and salt query params for a user inputted password, hashed with bcrypt
     * bcrypt stores its own salt in the hash, so the salt column is left blank
     *
     * @password plain text password
     */
    private struct function passwordParams(required string password) {
        return {
            password: {value: bcrypt.hashPassword(password = arguments.password), cfsqltype: "varchar"},
            salt    : {value: "", cfsqltype: "varchar"}
        };
    }

    /**
     * A bcrypt hash of a random password, made once with the configured work factor
     * Checked against when the email doesn't exist so a miss costs the same time as a real check
     */
    private string function getDummyHash() {
        if(!variables.keyExists("dummyHash")) {
            variables.dummyHash = bcrypt.hashPassword(password = generateSecretKey("AES", 256));
        }
        return variables.dummyHash;
    }

    /**
     * Verify the incoming password against the trainer's stored hash
     * Supports bcrypt hashes and legacy (salted + peppered SHA) hashes
     *
     * @suppliedPassword user entered password
     * @credentials      the trainer's secrets (findCredentials)
     */
    private boolean function verifyPassword(required string suppliedPassword, required struct credentials) {
        var storedHash = arguments.credentials.password;
        if(!storedHash.len()) {
            return false;
        }

        if(isBcryptHash(storedHash)) {
            return bcrypt.checkPassword(candidate = arguments.suppliedPassword, bCryptHash = storedHash);
        }

        // Legacy hash - constant time compare
        var legacyHash = utilService.pepperedHash(arguments.suppliedPassword & arguments.credentials.salt);
        return createObject("java", "java.security.MessageDigest").isEqual(
            storedHash.getBytes("UTF-8"),
            legacyHash.getBytes("UTF-8")
        );
    }

    /**
     * True if the stored password is a bcrypt hash (otherwise it is a legacy hash)
     */
    private boolean function isBcryptHash(required string storedPassword) {
        return reFind("^\$2[aby]\$\d{2}\$", arguments.storedPassword) > 0;
    }

    /**
     * The stored form of a verification code - tied to this session, so it only verifies here
     *
     * @code plain verification code
     */
    private string function hashVerificationCode(required string code) {
        return utilService.pepperedHash(arguments.code & session.sessionid);
    }

}
