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
     * SameSite=Lax - sent on top level navigations from other sites (links from other apps, home screen shortcuts),
     * held back on cross site posts and background requests
     *
     * @persistCookie value to set
     * @maxAge        days until it expires, 0 to delete it
     */
    private void function setBrowserCookie(required string persistCookie, required numeric maxAge) {
        var duration = arguments.maxAge * 24 * 60 * 60;
        cfheader(
            name  = "Set-Cookie",
            value = "#getPersistCookieName()#=#arguments.persistCookie#; Path=/; Max-Age=#duration#; Secure; HttpOnly; SameSite=Lax"
        );

        // cfheader doesn't touch the cookie scope - track the value for the rest of this request ("" = deleted)
        request[variables.REQUEST_COOKIE_KEY] = arguments.maxAge > 0 ? arguments.persistCookie : "";
    }

    /**
     * Adds a persist cookie for a user logging in
     *
     * @trainerid pk of the trainer to add the cookie for
     */
    public void function addCookie(required numeric trainerid) {
        var persistCookie = generateCookie();
        setBrowserCookie(persistCookie, getPersistDuration());

        var rightNow = now();
        queryExecute(
            "
            INSERT INTO persist (cookie, agent, lastused, lastrotated, trainerid)
            VALUES (:cookie, :agent, :rightNow, :rightNow, :trainerid)
            ",
            {
                cookie   : {value: hashCookie(persistCookie), cfsqltype: "varchar"},
                agent    : {value: left(utilService.getUserAgent(), 512), cfsqltype: "varchar"},
                rightNow : {value: rightNow, cfsqltype: "timestamp"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
            }
        );
        return;
    }

    /**
     * Rotates the existing persist cookie - the old cookie keeps working for ROTATION_GRACE seconds
     * Only rotates if the row still holds the cookie it was loaded with - when concurrent requests race,
     * one rotates and sets the new cookie, the rest leave the browser's cookie alone
     *
     * @persist The persist row to rotate (needs its id and cookie)
     *
     * @return true if this request rotated the cookie
     */
    public boolean function rotateCookie(required struct persist) {
        var newPersistCookie = generateCookie();
        var rightNow         = now();

        var rotated = queryExecute(
            "
            UPDATE persist
            SET previouscookie = cookie,
                cookie         = :newCookie,
                lastrotated    = :rightNow,
                lastused       = :rightNow
            WHERE id = :id
                AND cookie = :currentCookie
            RETURNING id
            ",
            {
                newCookie    : {value: hashCookie(newPersistCookie), cfsqltype: "varchar"},
                rightNow     : {value: rightNow, cfsqltype: "timestamp"},
                id           : {value: arguments.persist.id, cfsqltype: "integer"},
                currentCookie: {value: arguments.persist.cookie, cfsqltype: "varchar"}
            },
            {returnType: "array"}
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
        var rows         = queryExecute(
            "
            SELECT persist.id, persist.created, persist.updated, persist.cookie, persist.agent, persist.lastused,
                persist.lastrotated, persist.previouscookie, persist.trainerid, trainer.email
            FROM persist
            INNER JOIN trainer ON trainer.id = persist.trainerid
            WHERE persist.agent = :agent
                AND (persist.cookie = :cookie OR persist.previouscookie = :cookie)
            LIMIT 1
            ",
            {
                cookie: {value: hashedCookie, cfsqltype: "varchar"},
                agent : {value: left(utilService.getUserAgent(), 512), cfsqltype: "varchar"}
            },
            {returnType: "array"}
        );

        if(!rows.len()) return result;
        var persist = rows[1];

        // Enforce expiry here too - the cleanup task only runs hourly
        if(
            (!isNull(persist.created) && dateDiff("d", persist.created, now()) >= getPersistDuration()) ||
            (!isNull(persist.lastused) && dateDiff("d", persist.lastused, now()) >= getPersistUse())
        ) {
            deletePersist(persist.id);
            return result;
        }

        if(persist.cookie != hashedCookie) {
            // The cookie this row was rotated from - only good right after the rotation
            if(dateDiff("s", persist.lastrotated, now()) > variables.ROTATION_GRACE) {
                // Reused after the grace window - one of the two holders is not the trainer, so revoke it for both
                deletePersist(persist.id);
                return result;
            }
        }
        else if(dateDiff("d", persist.lastrotated, now()) >= 1) {
            // Rotate the cookie once a day
            rotateCookie(persist);
        }
        else {
            queryExecute(
                "UPDATE persist SET lastused = :rightNow WHERE id = :id",
                {rightNow: {value: now(), cfsqltype: "timestamp"}, id: {value: persist.id, cfsqltype: "integer"}}
            );
        }

        result.success   = true;
        result.email     = persist.email;
        result.trainerid = persist.trainerid;
        return result;
    }

    /**
     * Delete one persist row
     *
     * @persistid persist pk
     */
    private void function deletePersist(required numeric persistid) {
        queryExecute("DELETE FROM persist WHERE id = :id", {id: {value: arguments.persistid, cfsqltype: "integer"}});
        return;
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
                "DELETE FROM persist WHERE cookie = :cookie OR previouscookie = :cookie",
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
            "DELETE FROM persist WHERE trainerid = :trainerid",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
        );
        return;
    }

    /**
     * Hash the raw browser cookie the same way it is stored
     */
    private string function hashCookie(required string persistCookie) {
        return utilService.pepperedHash(arguments.persistCookie);
    }

    /**
     * Scheduled job to cleanup expired and unused
     */
    public void function cleanupCookies() {
        // Delete cookies created more than persistDuration days ago, or not used in persistUse days
        var rightNow = now();
        queryExecute(
            "
            DELETE FROM persist
            WHERE created <= :createdBefore
                OR lastused <= :usedBefore
            ",
            {
                createdBefore: {value: dateAdd("d", -1 * getPersistDuration(), rightNow), cfsqltype: "timestamp"},
                usedBefore   : {value: dateAdd("d", -1 * getPersistUse(), rightNow), cfsqltype: "timestamp"}
            }
        );

        return;
    }

}
