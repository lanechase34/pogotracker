component singleton {

    property name="cacheStorage"   inject="cachebox:rateLimitStorage";
    property name="rateLimits"     inject="coldbox:setting:rateLimits";
    property name="useRateLimiter" inject="coldbox:setting:useRateLimiter";

    /**
     * Count a hit against every rule of a rateLimits entry
     * Every rule is counted, even after one is over, so each window keeps an accurate total
     *
     * @name    rateLimits entry - a handler.action, or a non event key like persist.login
     * @ip      the user's ip
     * @context values for rules scoped by fields other than ip (the rc)
     *
     * @return false when any rule is over its limit
     */
    public boolean function allow(
        required string name,
        required string ip,
        struct context = {}
    ) {
        if(!useRateLimiter || !rateLimits.keyExists(name)) {
            return true;
        }

        var allowed = true;
        for(var rule in rateLimits[name].rules) {
            var key = buildKey(
                currentEvent = name,
                by           = listToArray(rule.by),
                ip           = ip,
                context      = context
            );

            if(
                key.len() && !hit(
                    key    = key,
                    limit  = rule.limit,
                    window = rule.window
                )
            ) {
                allowed = false;
            }
        }

        return allowed;
    }

    /**
     * Clear the counters of a rateLimits entry's rules marked resetOnSuccess
     *
     * @name    rateLimits entry
     * @ip      the user's ip
     * @context values for rules scoped by fields other than ip (the rc)
     */
    public void function reset(
        required string name,
        required string ip,
        struct context = {}
    ) {
        if(!useRateLimiter || !rateLimits.keyExists(name)) {
            return;
        }

        for(var rule in rateLimits[name].rules) {
            if(!(rule.resetOnSuccess ?: false)) {
                continue;
            }

            var key = buildKey(
                currentEvent = name,
                by           = listToArray(rule.by),
                ip           = ip,
                context      = context
            );

            if(key.len()) {
                clear(key = key);
            }
        }
    }

    /**
     * Record a hit against a fixed-window counter
     * Returns whether the hit is allowed
     *
     * @key    cache key
     * @limit  number of hits allowed in the window
     * @window window length in minutes
     */
    public boolean function hit(
        required string key,
        required numeric limit,
        required numeric window
    ) {
        lock name="ratelimit:#key#" type="exclusive" timeout="5" {
            var nowMs   = getTickCount();
            var counter = cacheStorage.get(key);

            // Start a new window when there's no counter or the old window has passed
            if(isNull(counter) || nowMs >= counter.expiresAt) {
                counter = {count: 0, expiresAt: nowMs + window * 60000};
            }

            if(counter.count >= limit) {
                return false;
            }

            counter.count++;

            // Timeout is a backstop for cleanup only - expiresAt above is what ends the window
            cacheStorage.set(key, counter, window + 1);

            return true;
        }
    }

    /**
     * Remove a counter, starting it fresh on the next hit
     *
     * @key cache key
     */
    public void function clear(required string key) {
        lock name="ratelimit:#key#" type="exclusive" timeout="5" {
            cacheStorage.clear(key);
        }
    }

    /**
     * Build the cache key for a rule
     * Returns an empty string if any of the rule's fields are missing - the rule is skipped
     *
     * @currentEvent current event name
     * @by           ordered list of the fields the rule is scoped by
     * @ip           the user's ip
     * @context      the rc scope, contains values
     */
    public string function buildKey(
        required string currentEvent,
        required array by,
        required string ip,
        required struct context
    ) {
        var parts = [];

        for(var field in by) {
            // The ip is passed in - other values come from rc scope
            var value = field == "ip" ? ip : (context[field] ?: "");
            if(!isSimpleValue(value) || !len(trim(value))) {
                return "";
            }

            parts.append("#field#=#lCase(trim(value))#");
        }

        return "ratelimit:#currentEvent#:#by.toList("+")#:#hash(parts.toList("|"), "SHA-256")#";
    }

}
