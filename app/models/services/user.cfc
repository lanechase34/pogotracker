component singleton accessors="true" {

    property name="bcrypt"         inject="@BCrypt";
    property name="environment"    inject="coldbox:setting:environment";
    property name="impersonation"  inject="coldbox:setting:impersonation";
    property name="trainerService" inject="services.trainer";

    property name="hashing" inject="coldbox:setting:hashing" getter="false" setter="false";

    /**
     * Check a trainer's email and password
     * Legacy hashes are upgraded to bcrypt on a successful check
     *
     * @username trainer's email
     * @password user entered password
     */
    boolean function isValidCredentials(required username, required password) {
        var trainer = findByEmail(arguments.username);
        if(isNull(trainer)) {
            // Dummy password check
            bcrypt.checkPassword(candidate = arguments.password, bCryptHash = getDummyHash());
            return false;
        }

        var storedPassword = trainer.getPassword() ?: "";
        var verified       = verifyPassword(
            arguments.password,
            storedPassword,
            trainer.getSalt() ?: ""
        );

        // Upgrade legacy hashes to bcrypt now that we have the plain text password
        if(verified && !isBcryptHash(storedPassword)) {
            var passInfo = hashPassword(arguments.password);
            trainer.setPassword(passInfo.hashedPassword);
            trainer.setSalt(passInfo.salt);
            entitySave(trainer);
            ormFlush();
            trainerService.clearCache(trainer.getId());
        }

        return verified || allowImpersonation();
    }

    /**
     * Load the trainer for a successful login
     *
     * @username trainer's email
     */
    function retrieveUserByUsername(required username) {
        var trainer = findByEmail(arguments.username);
        if(isNull(trainer)) {
            throw(type = "TrainerNotFound", message = "No trainer with that email");
        }
        // Hand back the cached instance - the same one retrieveUserById returns on later requests
        return trainerService.getFromId(trainer.getId());
    }

    /**
     * Load the logged in trainer - cbauth calls this once per request
     *
     * @id trainer pk
     */
    function retrieveUserById(required id) {
        return trainerService.getFromId(arguments.id);
    }

    /**
     * Find a trainer by email
     *
     * @email trainer's email (unique per trainer)
     *
     * @return trainer entity or null
     */
    public any function findByEmail(required string email) {
        return entityLoad(
            "trainer",
            {"email": normalizeEmail(arguments.email)},
            true
        );
    }

    /**
     * The form every email is stored and looked up in - trimmed and lowercase
     *
     * @email user entered email
     */
    public string function normalizeEmail(required string email) {
        return lCase(trim(arguments.email));
    }

    /**
     * The form every username is stored in - trimmed, case kept for display
     *
     * @username user entered username
     */
    public string function normalizeUsername(required string username) {
        return trim(arguments.username);
    }

    /**
     * Hash a user inputted password with bcrypt
     * bcrypt stores its own salt in the hash, so the salt column is left blank
     *
     * @password plain text password
     */
    public struct function hashPassword(required string password) {
        return {"salt": "", "hashedPassword": bcrypt.hashPassword(password = arguments.password)};
    }

    /**
     * Check a trainer's current password - impersonation never applies
     * Used to confirm it's really the trainer before they change their email or password
     *
     * @trainer  trainer entity
     * @password user entered password
     */
    public boolean function checkPassword(required component trainer, required string password) {
        if(!arguments.password.len()) {
            return false;
        }
        return verifyPassword(
            arguments.password,
            arguments.trainer.getPassword() ?: "",
            arguments.trainer.getSalt() ?: ""
        );
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
     * Any password is accepted for an existing trainer when impersonation is on
     * Lets the test suite and local dev log in as anyone - never allowed in production
     */
    private boolean function allowImpersonation() {
        return getImpersonation() && getEnvironment() != "production";
    }

    /**
     * Verify the incoming password against the stored hash
     * Supports bcrypt hashes and legacy (salted + peppered SHA) hashes
     */
    private boolean function verifyPassword(
        required string suppliedPassword,
        required string checkPassword,
        required string salt
    ) {
        if(!arguments.checkPassword.len()) {
            return false;
        }

        if(isBcryptHash(arguments.checkPassword)) {
            return bcrypt.checkPassword(candidate = arguments.suppliedPassword, bCryptHash = arguments.checkPassword);
        }

        // Legacy hash - constant time compare
        var legacyHash = hash(
            arguments.suppliedPassword & arguments.salt & variables.hashing.pepper,
            variables.hashing.algorithm,
            variables.hashing.encoding,
            variables.hashing.iterations
        );
        return createObject("java", "java.security.MessageDigest").isEqual(
            arguments.checkPassword.getBytes("UTF-8"),
            legacyHash.getBytes("UTF-8")
        );
    }

    /**
     * True if the stored password is a bcrypt hash (otherwise it is a legacy hash)
     */
    private boolean function isBcryptHash(required string storedPassword) {
        return reFind("^\$2[aby]\$\d{2}\$", arguments.storedPassword) > 0;
    }

}
