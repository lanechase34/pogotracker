component singleton accessors="true" {

    property name="securityService" inject="services.security";

    property name="algorithm"      type="string"  setter="false";
    property name="encoding"       type="string"  setter="false";
    property name="iterations"     type="number"  setter="false";
    property name="pepper"         type="string"  setter="false";
    property name="cookieName"     type="string"  setter="false";
    property name="cookieDuration" type="numeric" setter="false";
    property name="cookieUse"      type="numeric" setter="false";

    public void function init() {
        var env = new coldbox.system.core.delegates.Env();

        this.algorithm  = env.getEnv('ALGORITHM');
        this.encoding   = 'UTF-8';
        this.iterations = env.getEnv('ITERATIONS');
        this.pepper     = env.getEnv('PEPPER');

        this.cookieName     = application.cbController.getSetting('persistCookieName');
        this.cookieDuration = application.cbController.getSetting('persistDuration');
        this.cookieUse      = application.cbController.getSetting('persistUse');
    }

    /**
     * Creates and sets the browser unhashed persist cookie and returns the hashed cookie
     */
    private string function createCookie() {
        var persistCookie = hash(
            generateSecretKey('AES', 256) & createUUID() & now(),
            this.algorithm,
            this.encoding,
            this.iterations
        );

        setPersistCookie(persistCookie);

        if(application.cbController.getSetting('environment') != 'production') {
            cookie[this.cookieName] = persistCookie;
        }

        // Hash and store in database
        var hashedPersistCookie = hash(
            persistCookie & this.pepper,
            this.algorithm,
            this.encoding,
            this.iterations
        );

        return hashedPersistCookie;
    }

    /**
     * Use cfheader to set the cookie back to browser
     *
     * @persistCookie value to set
     * @maxAge        age in days
     */
    private void function setPersistCookie(required string persistCookie, numeric maxAge = getCookieDuration()) {
        // Set the cookie in the browser. HTTP Only and Secure. Expires in persistDuration days.
        // SameSite=strict browser will only send cookie in requests that originate from the same domain
        cfheader(
            name  = "Set-Cookie",
            value = "#getCookieName()#=#arguments.persistCookie#; Path=/; Max-Age=#arguments.maxAge * 24 * 60 * 60#; Secure; HttpOnly; SameSite=Strict"
        );
    }

    /**
     * Adds a persist cookie for a user logging in
     *
     * @trainer 
     */
    public void function addCookie(required component trainer) {
        var persistCookie = createCookie();
        var persist       = entityNew(
            'persist',
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
     * @persist 
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
     * @persistCookie 
     */
    public struct function login(required string persistCookie) {
        var result = {success: false, email: ''};

        var hashedPersistCookie = hash(
            persistCookie & this.pepper,
            this.algorithm,
            this.encoding,
            this.iterations
        );

        var persist = entityLoad(
            'persist',
            {cookie: hashedPersistCookie, agent: left(securityService.getUserAgent(), 512)},
            true
        );

        if(isNull(persist)) return result;

        // Found a persist entry, get the associated trainer
        // If the cookie was last used more than a day ago, rotate it
        if(dateDiff('d', persist.getLastRotated(), now()) >= 1) {
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
        return cookie.keyExists(this.cookieName);
    }

    public string function getCookie() {
        return cookie[this.cookieName];
    }

    public void function deleteCookie() {
        if(checkCookie()) {
            cookie.delete(this.cookieName);
        }
        // Set maxage to 0 will tell browser to delete cookie
        setPersistCookie(persistCookie = 'delete', maxAge = 0);
    }

    /**
     * Scheduled job to cleanup expired and unused
     */
    public void function cleanupCookies() {
        // Delete cookies that were created > cookieDuration days ago
        queryExecute(
            '
            delete from persist
            where created <= :dateCheck
        ',
            {dateCheck: {value: dateAdd('d', -1 * this.cookieDuration, now()), cfsqltype: 'timestamp'}}
        );

        // Delete cookies that have not been used in cookieUse days
        queryExecute(
            '
            delete from persist
            where lastused <= :dateCheck
        ',
            {dateCheck: {value: dateAdd('d', -1 * this.cookieUse, now()), cfsqltype: 'timestamp'}}
        );

        return;
    }

}
