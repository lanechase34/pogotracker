component {

    function configure() {
        return {
            /**
             * --------------------------------------------------------------------------
             * Authentication Services
             * --------------------------------------------------------------------------
             * cbauth handles login/logout and holds the logged in trainer id in the session.
             * services.user tells cbauth how to find trainers and check passwords.
             * cbauth itself is configured in config/modules/cbauth.cfc
             */
            authentication: {
                provider       : "authenticationService@cbauth",
                userService    : "services.user",
                prcUserVariable: "oCurrentUser" // prc.oCurrentUser holds the logged in trainer on every request
            },
            /**
             * --------------------------------------------------------------------------
             * CSRF
             * --------------------------------------------------------------------------
             * Applied to the bundled cbcsrf module - cbsecurity copies these over in its onLoad, and ColdBox activates
             * child modules (cbcsrf) right after their parent's onLoad, so they're in place before cbcsrf reads them
             */
            csrf: {
                // Every non GET/HEAD/OPTIONS request must send a token as the `csrf` form field or the `x-csrf-token` header
                // Skipped automatically during integration tests
                enableAutoVerifier    : true,
                // error.* only renders error pages
                verifyExcludes        : ["^error\."],
                // Tokens live as long as the session so a page left open doesn't start failing its posts
                // Rotated on every login (interceptors/security.cfc) and thrown away with the session on logout
                rotationTimeout       : 0,
                cacheStorage          : "SessionStorage@cbstorages",
                enableEndpoint        : false,
                // Only listens to cbauth's postAuthentication, which registration and remember me logins skip - interceptors/security.cfc rotates on postLogin instead
                enableAuthTokenRotator: false
            },
            /**
             * --------------------------------------------------------------------------
             * Firewall
             * --------------------------------------------------------------------------
             * Access is declared on the handlers with the `secured` annotation:
             *  component secured="user"                      every action needs the permission
             *  function edit(event, rc, prc) secured="admin" this action needs the permission
             * The handler annotation is checked first, then the action's - both must pass.
             * No annotation means public.
             *
             * Permissions are named security levels (settings.permissions in config/Coldbox.cfc, trainer.hasPermission)
             *  user      : 10 verified trainer
             *  trusted   : 20
             *  admin     : 50
             *  developer : 60
             *
             * Failed checks are handled by interceptors/security.cfc (login redirect / 401 json, unverified -> /verify)
             * and otherwise fall through to the defaults below.
             */
            firewall: {
                autoLoadFirewall           : true,
                validator                  : "AuthValidator@cbsecurity",
                handlerAnnotationSecurity  : true,
                invalidAuthenticationEvent : "login.loginForm",
                defaultAuthenticationAction: "redirect",
                invalidAuthorizationEvent  : "error.unauthorized",
                defaultAuthorizationAction : "override",
                logs                       : {enabled: false}, // unauthorized access is already audited by error.unauthorized
                rules                      : {
                    useRegex: true,
                    useSSL  : false,
                    defaults: {},
                    inline  : [], // no url/event rules - see the handler annotations
                    provider: {"source": "", "properties": {}}
                }
            },
            /**
             * --------------------------------------------------------------------------
             * Security Visualizer
             * --------------------------------------------------------------------------
             * Off - when enabled, /cbsecurity shows the loaded rules and settings
             */
            visualizer: {
                enabled     : false,
                secured     : false,
                securityRule: {}
            },
            /**
             * --------------------------------------------------------------------------
             * Security Headers
             * --------------------------------------------------------------------------
             * nginx sets these (config/security_headers.conf)
             */
            securityHeaders: {enabled: false}
        }
    }

}
