component singleton accessors="true" {

    property name="securityService"   inject="services.security";
    property name="persistCookieName" inject="coldbox:setting:persistCookieName";
    property name="persistDuration"   inject="coldbox:setting:persistDuration";
    property name="persistUse"        inject="coldbox:setting:persistUse";

    property name="algorithm"  type="string" setter="false";
    property name="encoding"   type="string" setter="false";
    property name="iterations" type="number" setter="false";
    property name="pepper"     type="string" setter="false";

    public void function init() {
        var env = new coldbox.system.core.delegates.Env();

        this.algorithm  = env.getEnv("ALGORITHM");
        this.encoding   = "UTF-8";
        this.iterations = env.getEnv("ITERATIONS");
        this.pepper     = env.getEnv("PEPPER");
    }

    /**
     * Creates and sets the browser unhashed persist cookie and returns the hashed cookie
     */
    private string function createCookie() {
        var persistCookie = left(
            hash(
                generateSecretKey("AES", 256) & createUUID() & now(),
                this.algorithm,
                this.encoding,
                this.iterations
            ),
            128
        );

        setPersistCookie(persistCookie = persistCookie, maxAge = getPersistDuration());

        if(application.cbController.getSetting("environment") != "production") {
            cfcookie(
                name     = getPersistCookieName(),
                value    = persistCookie,
                expires  = getPersistDuration(),
                path     = "/",
                secure   = true,
                httponly = true,
                samesite = "strict"
            );
        }

        // Hash and store in database
        return hashCookie(persistCookie);
    }

    /**
     * Use cfheader to set the cookie back to browser
     *
     * @persistCookie value to set
     * @maxAge        age in days
     */
    private void function setPersistCookie(required string persistCookie, required numeric maxAge) {
        // Set the cookie in the browser. HTTP Only and Secure. Expires in persistDuration days.
        // SameSite=strict browser will only send cookie in requests that originate from the same domain
        var duration = arguments.maxAge * 24 * 60 * 60;
        cfheader(
            name  = "Set-Cookie",
            value = "#getPersistCookieName()#=#arguments.persistCookie#; Path=/; Max-Age=#duration#; Secure; HttpOnly; SameSite=Strict"
        );
    }

    /**
     * Adds a persist cookie for a user logging in
     *
     * @trainer The trainer entity to add cookie to
     */
    public void function addCookie(required component trainer) {
        var persistCookie = createCookie();
        var persist       = entityNew(
            "persist",
            {
                cookie     : persistCookie,
                agent      : left(securityService.getUserAgent(), 512),
                lastused   : now(),
                lastrotated: now()
            }
        );
        persist.setTrainer(arguments.trainer);
        entitySave(persist);
        ormFlush();
        return;
    }

    /**
     * Rotates the existing persist cookie
     *
     * @persist The persist entity to rotate
     */
    public void function rotateCookie(required component persist) {
        var newPersistCookie = createCookie();

        persist.setCookie(newPersistCookie);
        persist.setLastRotated(now());
        persist.setLastUsed(now());
        entitySave(persist);
        ormFlush();
        return;
    }

    /**
     * Attempt to login a user with the incoming persist cookie
     *
     * @persistCookie The encoded persist cookie
     */
    public struct function login(required string persistCookie) {
        var result = {success: false, email: ""};

        var persist = entityLoad(
            "persist",
            {cookie: hashCookie(arguments.persistCookie), agent: left(securityService.getUserAgent(), 512)},
            true
        );

        if(isNull(persist)) return result;

        // Enforce expiry here too - the cleanup task only runs hourly
        if(
            (!isNull(persist.getCreated()) && dateDiff("d", persist.getCreated(), now()) >= getPersistDuration()) ||
            (!isNull(persist.getLastUsed()) && dateDiff("d", persist.getLastUsed(), now()) >= getPersistUse())
        ) {
            entityDelete(persist);
            ormFlush();
            return result;
        }

        // Found a persist entry, get the associated trainer
        // If the cookie was last used more than a day ago, rotate it
        if(dateDiff("d", persist.getLastRotated(), now()) >= 1) {
            rotateCookie(persist);
        }
        else {
            persist.setLastUsed(now());
            entitySave(persist);
            ormFlush();
        }

        result.success = true;
        result.email   = persist.getTrainer().getEmail();
        return result;
    }

    /**
     * Check if the user has the persist cookie
     */
    public boolean function checkCookie() {
        return cookie.keyExists(getPersistCookieName());
    }

    /**
     * Get the cookie from cookie scope
     */
    public string function getCookie() {
        return cookie[getPersistCookieName()];
    }

    /**
     * Delete the cookie by telling the browser cookie has expired
     */
    public void function deleteCookie() {
        if(checkCookie()) {
            // Revoke server side so a copied cookie can't be replayed after logout
            queryExecute(
                "delete from persist where cookie = :cookie",
                {cookie: {value: hashCookie(getCookie()), cfsqltype: "varchar"}}
            );
            cookie.delete(getPersistCookieName());
        }
        // Set maxage to 0 will tell browser to delete cookie
        setPersistCookie(persistCookie = "delete", maxAge = 0);
    }

    /**
     * Revoke every persist cookie for a trainer (password change/reset, privilege change)
     *
     * @trainerid trainer pk
     */
    public void function revokeAll(required numeric trainerid) {
        queryExecute(
            "delete from persist where trainerid = :trainerid",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
        );
        return;
    }

    /**
     * Hash the raw browser cookie the same way it is stored
     */
    private string function hashCookie(required string persistCookie) {
        return hash(
            arguments.persistCookie & this.pepper,
            this.algorithm,
            this.encoding,
            this.iterations
        );
    }

    /**
     * Scheduled job to cleanup expired and unused
     */
    public void function cleanupCookies() {
        // Delete cookies that were created > cookieDuration days ago
        queryExecute(
            "
            delete from persist
            where created <= :dateCheck
        ",
            {dateCheck: {value: dateAdd("d", -1 * getPersistDuration(), now()), cfsqltype: "timestamp"}}
        );

        // Delete cookies that have not been used in cookieUse days
        queryExecute(
            "
            delete from persist
            where lastused <= :dateCheck
        ",
            {dateCheck: {value: dateAdd("d", -1 * getPersistUse(), now()), cfsqltype: "timestamp"}}
        );

        return;
    }

}
