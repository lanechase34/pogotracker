component singleton accessors="true" {

    property name="utilService"       inject="services.util";
    property name="persistCookieName" inject="coldbox:setting:persistCookieName";
    property name="persistDuration"   inject="coldbox:setting:persistDuration";
    property name="persistUse"        inject="coldbox:setting:persistUse";

    property name="hashing" inject="coldbox:setting:hashing" getter="false" setter="false";

    // Seconds the cookie a row was rotated from keeps working - the browser's other in flight requests still carry it
    variables.ROTATION_GRACE = 60;

    // Request scope key holding the persist cookie value set during this request
    variables.REQUEST_COOKIE_KEY = "persistCookieValue";

    /**
     * A new random, unhashed persist cookie value
     */
    private string function generateCookie() {
        return left(
            hash(
                generateSecretKey("AES", 256) & createUUID() & now(),
                variables.hashing.algorithm,
                variables.hashing.encoding,
                variables.hashing.iterations
            ),
            128
        );
    }

    /**
     * Send the persist cookie to the browser with a raw Set-Cookie header
     * SameSite=strict - the browser only sends the cookie on requests that originate from our domain
     *
     * @persistCookie value to set
     * @maxAge        days until it expires, 0 to delete it
     */
    private void function setBrowserCookie(required string persistCookie, required numeric maxAge) {
        var duration = arguments.maxAge * 24 * 60 * 60;
        cfheader(
            name  = "Set-Cookie",
            value = "#getPersistCookieName()#=#arguments.persistCookie#; Path=/; Max-Age=#duration#; Secure; HttpOnly; SameSite=Strict"
        );

        // cfheader doesn't touch the cookie scope - track the value for the rest of this request ("" = deleted)
        request[variables.REQUEST_COOKIE_KEY] = arguments.maxAge > 0 ? arguments.persistCookie : "";
    }

    /**
     * Adds a persist cookie for a user logging in
     *
     * @trainer The trainer entity to add cookie to
     */
    public void function addCookie(required component trainer) {
        var persistCookie = generateCookie();
        setBrowserCookie(persistCookie, getPersistDuration());

        var persist = entityNew(
            "persist",
            {
                cookie     : hashCookie(persistCookie),
                agent      : left(utilService.getUserAgent(), 512),
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
     * Rotates the existing persist cookie - the old cookie keeps working for ROTATION_GRACE seconds
     * Only rotates if the row still holds the cookie it was loaded with - when concurrent requests race,
     * one rotates and sets the new cookie, the rest leave the browser's cookie alone
     *
     * @persist The persist entity to rotate
     *
     * @return true if this request rotated the cookie
     */
    public boolean function rotateCookie(required component persist) {
        var newPersistCookie = generateCookie();
        var rightNow         = now();

        var rotated = queryExecute(
            "
            update persist
            set previouscookie = cookie,
                cookie         = :newCookie,
                lastrotated    = :rightNow,
                lastused       = :rightNow,
                updated        = :rightNow
            where id = :id
                and cookie = :currentCookie
            returning id
            ",
            {
                newCookie    : {value: hashCookie(newPersistCookie), cfsqltype: "varchar"},
                rightNow     : {value: rightNow, cfsqltype: "timestamp"},
                id           : {value: arguments.persist.getId(), cfsqltype: "integer"},
                currentCookie: {value: arguments.persist.getCookie(), cfsqltype: "varchar"}
            },
            {returntype: "array"}
        );

        if(!rotated.len()) {
            return false;
        }

        setBrowserCookie(newPersistCookie, getPersistDuration());
        return true;
    }

    /**
     * Attempt to login a user with the incoming persist cookie
     *
     * @persistCookie The encoded persist cookie
     */
    public struct function login(required string persistCookie) {
        var result = {
            success  : false,
            email    : "",
            trainerid: -1
        };

        var hashedCookie = hashCookie(arguments.persistCookie);
        var persist      = ormExecuteQuery(
            "
            from persist
            where agent = :agent
                and (cookie = :cookie or previouscookie = :cookie)
            ",
            {cookie: hashedCookie, agent: left(utilService.getUserAgent(), 512)},
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

        if(persist.getCookie() != hashedCookie) {
            // The cookie this row was rotated from - only good right after the rotation
            if(dateDiff("s", persist.getLastRotated(), now()) > variables.ROTATION_GRACE) {
                // Reused after the grace window - one of the two holders is not the trainer, so revoke it for both
                entityDelete(persist);
                ormFlush();
                return result;
            }
        }
        else if(dateDiff("d", persist.getLastRotated(), now()) >= 1) {
            // Rotate the cookie once a day
            rotateCookie(persist);
        }
        else {
            persist.setLastUsed(now());
            entitySave(persist);
            ormFlush();
        }

        result.success   = true;
        result.email     = persist.getTrainer().getEmail();
        result.trainerid = persist.getTrainer().getId();
        return result;
    }

    /**
     * Check if the user has the persist cookie
     */
    public boolean function checkCookie() {
        if(request.keyExists(variables.REQUEST_COOKIE_KEY)) {
            return len(request[variables.REQUEST_COOKIE_KEY]) > 0;
        }
        return cookie.keyExists(getPersistCookieName());
    }

    /**
     * Get the cookie - the value set earlier in this request if any, otherwise the incoming cookie scope
     */
    public string function getCookie() {
        if(request.keyExists(variables.REQUEST_COOKIE_KEY)) {
            return request[variables.REQUEST_COOKIE_KEY];
        }
        return cookie[getPersistCookieName()];
    }

    /**
     * Delete the cookie by telling the browser cookie has expired
     */
    public void function deleteCookie() {
        if(checkCookie()) {
            // Revoke server side so a copied cookie can't be replayed after logout
            // The browser may still hold the cookie the row was rotated from (the rotating response never reached it)
            queryExecute(
                "delete from persist where cookie = :cookie or previouscookie = :cookie",
                {cookie: {value: hashCookie(getCookie()), cfsqltype: "varchar"}}
            );
        }

        setBrowserCookie("", 0);
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
            arguments.persistCookie & variables.hashing.pepper,
            variables.hashing.algorithm,
            variables.hashing.encoding,
            variables.hashing.iterations
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
