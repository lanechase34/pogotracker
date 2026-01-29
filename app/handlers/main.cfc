component extends="base" {

    property name="async"             inject="asyncManager@coldbox";
    property name="auditService"      inject="services.audit";
    property name="blogService"       inject="services.blog";
    property name="cacheService"      inject="services.cache";
    property name="generationService" inject="services.generation";
    property name="imageService"      inject="services.image";
    property name="persistService"    inject="services.persist";
    property name="pokemonService"    inject="services.pokemon";
    property name="trainerService"    inject="services.trainer";
    property name="securityService"   inject="services.security";
    property name="sessionService"    inject="services.session";
    property name="statsService"      inject="services.stats";

    this.prehandler_only = 'warmup';

    /**
     * Clear the current orm session so we know the audit will work
     * Set up audit object
     */
    function preHandler(event, rc, prc, action, eventArguments) {
        prc.auditInfo = auditService.getAuditObj(
            trainerid = session?.trainerid ?: -1,
            referer   = rc?.referer ?: '',
            event     = rc?.event ?: 'NA'
        );
    }

    function warmup(event, rc, prc) {
        // Fires on server start
        if(
            !getSetting('warmedUp')
            && securityService.getRequestIP() == '127.0.0.1'
            && find('Java', securityService.getUserAgent() ?: '') > 0
        ) {
            cacheService.clearAll();
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
                        return pokemonService.getSearch();
                    },
                    () => {
                        return statsService.getLeaderboard(now(), 'xp');
                    }
                )
                .get();

            setSetting('warmedUp', true);
            prc.auditInfo.event  = 'main.warmup';
            prc.auditInfo.detail = 'Successfully warmed up server in #getTickCount() - start#ms.';
            async.newFuture(() => {
                auditService.audit(argumentCollection = prc.auditInfo);
            });
        }

        jsonOk(event = event, data = 'Ok!');
    }

    function healthCheck(event, rc, prc) {
        if(!getSetting('healthCheck')) throw('Failed health check');
        jsonOk(event = event, data = 'Ok!');
    }

    function onRequestStart(event, rc, prc) {
        // Handle session creation
        if(!session.keyExists('trainerid')) {
            onSessionStart();
        }

        // Handle alerts
        if(session.keyExists('alert')) {
            request.alert = session.alert;
            sessionService.clearAlert();
        }

        // Request variables
        prc.currHandler = lCase(event.getCurrentHandler());
        prc.currAction  = lCase(event.getCurrentAction());
        prc.currEvent   = lCase(event.getCurrentEvent());

        prc.title           = '';
        prc.metaDescription = '';
        prc.metaKeywords    = '';

        // If this user has the persist cookie and not authenticated
        if(
            (prc.currHandler != 'login' || prc.currEvent == 'login.loginform') && !session.authenticated && persistService.checkCookie()
        ) {
            // Override event with the persistLogin page
            rc.persistCookie                 = persistService.getCookie();
            rc[getSetting('csrfTokenField')] = csrfGenerateToken(forceNew = true);
            event.overrideEvent('login.persistLogin');
            return;
        }

        // Check whether this user is allowed to view this handler->action
        if(
            !securityService.checkUserSecurity(
                session.securityLevel,
                prc.currHandler,
                prc.currAction
            )
        ) {
            // If the user is not authenticated, lead them to the login page
            if(!session.authenticated) {
                // Clicked on of the links available on sidebar
                if('mypokedex,myshadowpokedex,custompokedexlist,buildtradeplan,overview'.contains(prc.currAction)) {
                    session.linkedEvent = '/#prc.currAction#';
                }
                relocate(uri = '/login', persistStruct = {statusCode: 401});
            }
            // If the user is authenticated but not verified, lead them to verification page
            else if(!session.verified) {
                relocate(uri = '/verify');
            }
            // Immediately stop the current event and process the unauthorized page
            else {
                prc.unauthorizedEvent = event.getCurrentEvent();
                prc.referer           = securityService.getReferer();
                event.overrideEvent('error.unauthorized');
                return;
            }
        }
    }

    function onRequestEnd(event, rc, prc) {
        request.delete('alert');
    }

    function onSessionStart() {
        session.trainerid     = -1;
        session.securityLevel = 0;
        session.authenticated = false;
        session.verified      = false;
        session.recaptcha     = {
            token    : '',
            valid    : false,
            timestamp: now(),
            action   : ''
        };
    }

}
