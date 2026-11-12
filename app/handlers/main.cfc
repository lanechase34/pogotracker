component extends="base" {

    property name="async"             inject="asyncManager@coldbox";
    property name="auditService"      inject="services.audit";
    property name="blogService"       inject="services.blog";
    property name="cache"             inject="cachebox:appCache";
    property name="generationService" inject="services.generation";
    property name="pokemonService"    inject="services.pokemon";
    property name="statsService"      inject="services.stats";
    property name="utilService"       inject="services.util";

    this.prehandler_only = "warmup";

    /**
     * Clear the current orm session so we know the audit will work
     * Set up audit object
     */
    function preHandler(event, rc, prc, action, eventArguments) {
        prc.auditInfo = auditService.getAuditObj(
            trainerid = (prc?.oCurrentUser?.getId() ?: -1),
            referer   = rc?.referer ?: "",
            event     = rc?.event ?: "NA"
        );
    }

    function warmup(event, rc, prc) {
        // Skips warmup in test environment
        if(application.cbController.getSetting("environment") == "test") {
            setSetting("warmedUp", true);
        }

        // Fires on server start
        var trustedIPs = ["0:0:0:0:0:0:0:1", "127.0.0.1"];
        if(
            !getSetting("warmedUp")
            && trustedIPs.contains(utilService.getRequestIP())
            && findNoCase("Java", cgi.http_user_agent) > 0
        ) {
            setting requestTimeout=300;

            cache.clearAll();
            var start = getTickCount();

            // Warmup and load everything into cache
            var results = async
                .newFuture()
                .all(
                    () => {
                        return blogService.get(4, 0);
                    },
                    () => {
                        return blogService.get(4, 8);
                    },
                    () => {
                        return blogService.get(4, 12);
                    },
                    () => {
                        return blogService.get(4, 16);
                    },
                    () => {
                        return blogService.get(4, 4);
                    },
                    () => {
                        return blogService.getNews();
                    },
                    () => {
                        return blogService.getEvents();
                    },
                    () => {
                        return generationService.getAll();
                    },
                    () => {
                        return pokemonService.getAll();
                    },
                    () => {
                        return pokemonService.getMaxStats();
                    },
                    () => {
                        return pokemonService.getSearchArray();
                    },
                    () => {
                        return statsService.getLeaderboard(now(), "xp");
                    }
                )
                .get();

            // Prime the cached Pokedex index body (views/pokemon/index) - same event/args so the cache key matches
            var indexContentCacheTimeout = pokemonService.getCacheTime() * 15;
            runEvent(
                event                  = "pokemon.indexContent",
                private                = true,
                prePostExempt          = true,
                cache                  = true,
                cacheTimeout           = indexContentCacheTimeout,
                cacheLastAccessTimeout = indexContentCacheTimeout
            );

            setSetting("warmedUp", true);
            prc.auditInfo.event  = "main.warmup";
            prc.auditInfo.detail = "Successfully warmed up server in #getTickCount() - start#ms.";
            async.newFuture(() => {
                auditService.audit(argumentCollection = prc.auditInfo);
            });
        }

        jsonOk(event = event, data = "Ok!");
    }

    function healthCheck(event, rc, prc) {
        if(!getSetting("healthCheck")) throw("Failed health check");
        jsonOk(event = event, data = "Ok!");
    }

    /**
     * Request variables used
     */
    function onRequestStart(event, rc, prc) {
        prc.currHandler = lCase(event.getCurrentHandler());
        prc.currAction  = lCase(event.getCurrentAction());
        prc.currEvent   = lCase(event.getCurrentEvent());
        prc.currRoute   = reReplace(event.getCurrentRoutedURL(), "/$", "");

        prc.canonicalURL = "#getSetting("domain")##prc.currRoute.len() ? "/#prc.currRoute#" : "/"#";
        // The home page has a single canonical url regardless of how it was reached
        if(prc.currEvent == "home.home") {
            prc.canonicalURL = "#getSetting("domain")#/";
        }

        prc.title           = "";
        prc.metaDescription = "";
    }

}
