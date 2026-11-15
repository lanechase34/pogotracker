component extends="base" {

    property name="async"             inject="asyncManager@coldbox";
    property name="blogService"       inject="services.blog";
    property name="cache"             inject="cachebox:appCache";
    property name="generationService" inject="services.generation";
    property name="pokemonService"    inject="services.pokemon";
    property name="statsService"      inject="services.stats";
    property name="utilService"       inject="services.util";

    this.prehandler_only = "warmup";

    /**
     * Set up audit object
     */
    function preHandler(event, rc, prc, action, eventArguments) {
        setRequestAuditInfo(rc = rc, prc = prc);
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
                    // Blog pages as the app requests them
                    () => {
                        // Home server render, and the blog sidebar on mobile
                        return blogService.getBlogs(pageSize = 6, offset = 0);
                    },
                    () => {
                        // Blog sidebar on desktop
                        return blogService.getBlogs(pageSize = 8, offset = 0);
                    },
                    () => {
                        // Home desktop scroll fill, up to the max of 8
                        return blogService.getBlogs(pageSize = 2, offset = 6);
                    },
                    () => {
                        // First Load More click, mobile
                        return blogService.getBlogs(pageSize = 6, offset = 6);
                    },
                    () => {
                        // First Load More click, desktop
                        return blogService.getBlogs(pageSize = 6, offset = 8);
                    },
                    () => {
                        // Prime the cached Pokedex index body
                        var indexContentCacheTimeout = pokemonService.getCacheTime() * 15;
                        return runEvent(
                            event                  = "pokemon.indexContent",
                            private                = true,
                            prePostExempt          = true,
                            cache                  = true,
                            cacheTimeout           = indexContentCacheTimeout,
                            cacheLastAccessTimeout = indexContentCacheTimeout
                        );
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
                        return statsService.getLeaderboard(date = now(), stat = "xp");
                    }
                )
                .get();

            setSetting("warmedUp", true);
            prc.auditInfo.event  = "main.warmup";
            prc.auditInfo.detail = "Successfully warmed up server in #getTickCount() - start#ms.";
            auditService.audit(argumentCollection = prc.auditInfo);
        }

        jsonOk(event = event, data = "Ok!");
    }

    function healthCheck(event, rc, prc) {
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
