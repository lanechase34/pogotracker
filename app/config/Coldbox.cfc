component {

    /**
	 * Configure the ColdBox App For Production 
	 * https://coldbox.ortusbooks.com/getting-started/configuration
	 */
    function configure() {
        var logPath = getPageContext().getServletContext().getRealPath("/WEB-INF/");

        /**
		 * --------------------------------------------------------------------------
		 * ColdBox Directives
		 * --------------------------------------------------------------------------
		 * Here you can configure ColdBox for operation. Remember tha these directives below
		 * are for PRODUCTION. If you want different settings for other environments make sure
		 * you create the appropriate functions and define the environment in your .env or
		 * in the `environments` struct.
		 */
        coldbox = {
            // Application Setup
            appName                 : "POGO Tracker",
            eventName               : "event",
            // Development Settings
            reinitPassword          : len(getSystemSetting("REINITKEY", "")) ? getSystemSetting("REINITKEY") : "disabled_#generateSecretKey("AES", 256)##generateSecretKey("AES", 256)#",
            reinitKey               : "fwreinit",
            handlersIndexAutoReload : false,
            implicitViews           : true,
            // Implicit Events
            defaultEvent            : "error.notFound",
            requestStartHandler     : "main.onRequestStart",
            requestEndHandler       : "",
            applicationStartHandler : "",
            applicationEndHandler   : "",
            sessionStartHandler     : "",
            sessionEndHandler       : "",
            missingTemplateHandler  : "error.notFound",
            // Extension Points
            applicationHelper       : "",
            viewsHelper             : "",
            modulesExternalLocation : [],
            viewsExternalLocation   : "",
            layoutsExternalLocation : "",
            handlersExternalLocation: "",
            requestContextDecorator : "",
            controllerDecorator     : "",
            // Error/Exception Handling
            invalidHTTPMethodHandler: "error.invalidHTTPMethod",
            exceptionHandler        : "error.onException",
            invalidEventHandler     : "error.notFound",
            customErrorTemplate     : "/views/fragment/errortemplate.cfm",
            // Application Aspects
            handlerCaching          : true,
            eventCaching            : true,
            viewCaching             : true,
            // Will automatically do a mapDirectory() on your `models` for you.
            autoMapModels           : true,
            // Auto converts a json body payload into the RC
            jsonPayloadToRC         : true
        };

        /**
		 * --------------------------------------------------------------------------
		 * Custom Settings
		 * --------------------------------------------------------------------------
		 */
        settings = {
            rootPath   : replace(expandPath("/"), "\", "/", "all"),
            cacheBuster: "?v=#getAssetVersion()#",
            concurrency: {
                activeRequests: 0,
                maxRequests   : 0,
                slowRequests  : []
            },
            contactEmail   : "chaselane@pogotracker.app",
            costumeData    : false, // get costume data from wiki
            cssPath        : "/includes/build/css",
            debugging      : false,
            defaultSettings: {
                defaultView  : "",
                defaultRegion: "Kanto",
                defaultPage  : "/"
            },
            domain         : "https://pogotracker.app",
            domainProd     : "https://pogotracker.app",
            eventDaysBefore: 3, // task pulls in events up to 3 days before they start before creating custom entries automatically
            favIcoVersion  : 5,
            fetchCount     : 7, // number of news/leekduck posts to fetch on home page
            fromEmail      : "noreply@pogotracker.app",
            // Events a logged in trainer can't reach
            guestOnlyEvents: [
                "login.loginForm",
                "login.doLogin",
                "login.registrationForm",
                "login.register",
                "login.forgotPasswordForm",
                "login.forgotPassword",
                "login.resetPasswordForm",
                "login.resetPassword",
                "login.verifyRecaptcha"
            ],
            // Password/code hashing
            hashing: {
                algorithm : getSystemSetting("ALGORITHM"),
                encoding  : "UTF-8",
                iterations: getSystemSetting("ITERATIONS"),
                pepper    : getSystemSetting("PEPPER")
            },
            healthCheck    : true,
            httpPort       : getSystemSetting("HTTP_PORT"),
            imageExtension : ".webp",
            imageMagickPath: getSystemSetting("IMAGEMAGICKPATH"),
            impersonation  : false,
            jsPath         : "/includes/build/js",
            logPath        : logPath,
            logRequests    : false,
            // Mail server credentials
            mailServer     : {
                adminPassword: getSystemSetting("CFCONFIG_ADMINPASSWORD"),
                hostname     : getSystemSetting("EMAIL_SERVER"),
                port         : getSystemSetting("EMAIL_PORT"),
                username     : getSystemSetting("EMAIL_USERNAME"),
                password     : getSystemSetting("EMAIL_PASSWORD")
            },
            maxThreads     : createObject("java", "java.lang.Runtime").getRuntime().availableProcessors(),
            metaDescription: "Track your Pokémon GO progress. Monitor XP, Pokédex completions, shiny collection, medals, and walking distance. Plan trades with friends and stay on top of events.",
            // Minified CSS, JS settings
            minifiedCSS    : ".min",
            minifiedJS     : ".min",
            osType         : getSystemSetting("OS"),
            // Ordered struct, maps value -> display
            pageMap        : [
                "/"                 : "Home",
                "/mypokedex"        : "Pokedex",
                "/myshadowpokedex"  : "Shadow Pokedex",
                "/custompokedexlist": "Custom Pokedex",
                "/buildtradeplan"   : "Trade Plan",
                "/overview"         : "Stats"
            ],
            // __Host- prefix - the browser only accepts it Secure, Path=/ and with no Domain, so a subdomain can't plant one
            persistCookieName: "__Host-" & hash(
                createGUID(),
                getSystemSetting("ALGORITHM"),
                "UTF-8",
                getSystemSetting("ITERATIONS")
            ),
            persistDuration: 30, // Persist cookie last 30 days
            persistUse     : 7, // If not used in 7 days, automatically expire
            // Permission name -> minimum trainer security level
            permissions    : {
                user     : 10,
                trusted  : 20,
                admin    : 50,
                developer: 60
            },
            // Intrinsic width/height (px) for .pokemonIcon imgs, reserves layout space before the sprite loads
            pokemonIconSize: 128,
            /**
             * Per event rate limits
             *
             * redirect       : form posts relocate here with an alert, empty -> json 429 (ajax endpoints)
             * by             : 'ip' and/or rc fields the counter is scoped by
             * limit          : hits allowed per window
             * window         : window length in minutes
             * resetOnSuccess : clear the counter when the request logs a trainer in, optional
             */
            rateLimits: {
                "login.dologin": {
                    redirect: "/login",
                    rules   : [
                        {by: "ip", limit: 20, window: 15},
                        // Reset on success so a few typos don't carry over to the trainer's next login
                        {
                            by            : "ip,email",
                            limit         : 5,
                            window        : 15,
                            resetOnSuccess: true
                        },
                        // Credential stuffing against one account from many ips
                        {by: "email", limit: 10, window: 15}
                    ]
                },
                "login.register": {
                    redirect: "/register",
                    rules   : [
                        {by: "ip", limit: 5, window: 60},
                        {by: "email", limit: 3, window: 60}
                    ]
                },
                "login.forgotpassword": {
                    redirect: "/forgot",
                    rules   : [
                        {by: "ip", limit: 5, window: 15},
                        // Stops flooding a user's inbox with resets
                        {by: "email", limit: 3, window: 60}
                    ]
                },
                "login.verify"         : {redirect: "/verify", rules: [{by: "ip", limit: 10, window: 15}]},
                "login.resetpassword"  : {redirect: "/forgot", rules: [{by: "ip", limit: 10, window: 15}]},
                "login.verifyrecaptcha": {redirect: "", rules: [{by: "ip", limit: 30, window: 15}]},
                "home.contact"         : {redirect: "", rules: [{by: "ip", limit: 5, window: 60}]},
                // Changing your own email/password checks your current password - stops guessing it from a stolen session
                "trainer.updateprofile": {redirect: "", rules: [{by: "ip", limit: 10, window: 15}]},
                // Not an event - remember me logins, over the limit carries on as a guest
                // High cap - a fresh page load fires several async requests that each carry the cookie
                "persist.login"        : {redirect: "", rules: [{by: "ip", limit: 50, window: 5}]}
            },
            reCaptchaChecks: {
                // Validate a user's recaptcha session data for these actions
                dologin       : true,
                forgotpassword: true,
                register      : true
            },
            reCaptchaSiteKey  : getSystemSetting("RECAPTCHASITEKEY"),
            reCaptchaSecretKey: getSystemSetting("RECAPTCHASECRETKEY"),
            requestLog        : {
                // Request Log settings
                urlpathLength       : 500,
                methodLength        : 10,
                agentLength         : 250,
                refererLength       : 250,
                slowRequestThreshold: 1000, // ms
                maxSlowRequests     : 25
            },
            resetPasswordCooldown: 900, // time in seconds to wait for a new reset code
            resetPasswordLifespan: 30, // time in minutes the reset link is valid for
            // Trainer security level -> display name
            securityLevels       : {
                "0" : "Unregistered User",
                "5" : "Unverified User",
                "10": "Regular User",
                "20": "Trusted User",
                "50": "Administrator",
                "60": "Developer"
            },
            // Hosts (and their subdomains) the scraper is allowed to fetch from
            scraperHosts: [
                "bulbagarden.net",
                "fandom.com",
                "leekduck.com",
                "nocookie.net",
                "pokemondb.net",
                "pokemongo.com",
                "pokemongolive.com",
                "pvpoke.com"
            ],
            sessionTimeout      : getSystemSetting("SESSIONTIMEOUT"),
            shadowData          : false, // get shadow data from wikipedia
            signups             : true, // whether signups are enabled
            siteName            : "POGO Tracker", // short brand name used as the page title suffix and in structured data
            systemTrainer       : "lanechase34@outlook.com",
            testEmailPath       : "#replace(expandPath("/"), "\", "/", "all")#/_testemails",
            uploadPath          : "#replace(expandPath("/"), "\", "/", "all")#/includes/uploads",
            title               : "POGO Tracker - Track Your Pokémon GO Progress",
            useRateLimiter      : true,
            useRecaptcha        : true,
            verificationLifespan: 15, // time in minutes the verification link is valid for
            verificationCooldown: 900, // time in seconds to wait for a new verification code
            // Ordered struct, maps value -> display
            viewMap             : ["normal": "Normal", "shiny": "Shiny"],
            warmedUp            : false, // updates to true after server has finished warming up
            writeJson           : false
        };

        /**
		 * --------------------------------------------------------------------------
		 * Module Loading Directives
		 * --------------------------------------------------------------------------
		 */
        modules = {
            // An array of modules names to load, empty means all of them
            include: [],
            // An array of modules names to NOT load, empty means none
            exclude: []
        };

        /**
		 * --------------------------------------------------------------------------
		 * Application Logging (https://logbox.ortusbooks.com)
		 * --------------------------------------------------------------------------
		 * Rolling log files in <server>/logs, outside the web root
		 */
        logBox = {
            // Define Appenders
            appenders: {
                appLog: {
                    class     : "coldbox.system.logging.appenders.RollingFileAppender",
                    properties: {
                        filePath       : "#logPath#/../logs",
                        filename       : "app",
                        autoExpand     : false,
                        fileMaxSize    : 10000,
                        fileMaxArchives: 10,
                        async          : true
                    }
                },
                // Changes made when rebuilding json asset files, one entry per write
                jsonDiffLog: {
                    class     : "coldbox.system.logging.appenders.RollingFileAppender",
                    layout    : "models.objects.PlainLayout",
                    properties: {
                        filePath       : "#logPath#/../logs",
                        filename       : "jsondiff",
                        autoExpand     : false,
                        fileMaxSize    : 10000,
                        fileMaxArchives: 10,
                        async          : true
                    }
                }
            },
            // Root Logger
            root: {
                levelMin : "FATAL",
                levelMax : "WARN",
                appenders: "appLog"
            },
            // Implicit Level Categories
            categories: {
                "coldbox.system": {
                    levelMin : "FATAL",
                    levelMax : "INFO",
                    appenders: "appLog"
                },
                "WebSocket": {
                    levelMin : "FATAL",
                    levelMax : "WARN",
                    appenders: "appLog"
                },
                "adminLog": {
                    levelMin : "FATAL",
                    levelMax : "WARN",
                    appenders: "appLog"
                },
                "jsonDiff": {
                    levelMin : "FATAL",
                    levelMax : "INFO",
                    appenders: "jsonDiffLog"
                }
            }
        };

        /**
		 * --------------------------------------------------------------------------
		 * Layout Settings
		 * --------------------------------------------------------------------------
		 */
        layoutSettings = {defaultLayout: "default.cfm", defaultView: "fragment/blank.cfm"};

        /**
		 * --------------------------------------------------------------------------
		 * Custom Interception Points
		 * --------------------------------------------------------------------------
		 */
        interceptorSettings = {customInterceptionPoints: []};

        /**
		 * --------------------------------------------------------------------------
		 * Application Interceptors
		 * --------------------------------------------------------------------------
		 * Remember that the order of declaration is the order they will be registered and fired
		 */
        interceptors = [
            {
                class     : "interceptors.applifecycle",
                name      : "appLifeCycleInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.mail",
                name      : "mailInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.response",
                name      : "responseInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.sessionVersion",
                name      : "sessionVersionInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.security",
                name      : "securityInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.guestonly",
                name      : "guestOnlyInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.logrequest",
                name      : "logRequestInterceptor",
                properties: {}
            },
            {
                class     : "interceptors.ratelimiter",
                name      : "rateLimiterInterceptor",
                properties: {}
            }
        ];

        /**
		 * --------------------------------------------------------------------------
		 * Module Settings
		 * --------------------------------------------------------------------------
		 * Each module has it's own configuration structures, so make sure you follow
		 * the module's instructions on settings.
		 *
		 * Each key is the name of the module:
		 *
		 * myModule = {
		 *
		 * }
		 */
        moduleSettings = {
            // Keep the module's log with the app's logs, outside the web root
            ImageMagickHelpers: {logDirectory: "#logPath#/../logs", expandLogDirectory: false}
        };

        /**
		 * --------------------------------------------------------------------------
		 * Flash Scope Settings
		 * --------------------------------------------------------------------------
		 * The available scopes are : session, client, cluster, ColdBoxCache, or a full instantiation CFC path
		 */
        flash = {
            scope       : "session",
            properties  : {}, // constructor properties for the flash scope implementation
            inflateToRC : false, // automatically inflate flash data into the RC scope
            inflateToPRC: true, // automatically inflate flash data into the PRC scope
            autoPurge   : true, // automatically purge flash data for you
            autoSave    : true // automatically save flash scopes at end of a request and on relocations.
        };

        /**
		 * --------------------------------------------------------------------------
		 * App Conventions
		 * --------------------------------------------------------------------------
		 */
        conventions = {
            handlersLocation: "handlers",
            viewsLocation   : "views",
            layoutsLocation : "layouts",
            modelsLocation  : "models",
            eventAction     : "index"
        };
    }

    /**
	 * Development environment
	 */
    function development() {
        coldbox.handlersIndexAutoReload = true;
        coldbox.handlerCaching          = false;
        coldbox.eventCaching            = false;

        coldbox.reinitPassword = "";
        coldbox.debugMode      = true;

        // Development settings
        settings.title          = "[DEV #ucFirst(getSystemSetting("OS"))#] POGO Tracker";
        settings.useRecaptcha   = false;
        settings.useRateLimiter = getSystemSetting("RATE_LIMITER", false);
        settings.scraperHosts.append("httpbin.io"); // dev.cfc user agent check
        settings.writeJson   = true;
        settings.logRequests = false;
        settings.domain      = "http://localhost:#getSystemSetting("HTTP_PORT")#";

        settings.impersonation = true;

        // settings.debugging     = true;
        settings.shadowData  = true;
        settings.costumeData = true;

        // Serve the unminified sources - comment out to test the minified build
        settings.cssPath     = "/includes/css";
        settings.jsPath      = "/includes/js";
        settings.minifiedCSS = "";
        settings.minifiedJS  = "";

        // Lower bcrypt workfactor for faster performance
        moduleSettings.bcrypt = {workFactor: 4};

        logBox.root.levelmax = "DEBUG";
    }

    /**
     * Test environment
     */
    function test() {
        settings.useRecaptcha   = false;
        settings.useRateLimiter = false;
        settings.scraperHosts.append("httpbin.io"); // dev.cfc user agent check
        settings.title         = "[TEST #ucFirst(getSystemSetting("OS"))#] POGO Tracker";
        settings.impersonation = true;
        settings.logRequests   = false;
        settings.domain        = "http://localhost:#getSystemSetting("HTTP_PORT")#";

        moduleSettings.bcrypt = {workFactor: 4};
    }

    /**
     * Cache buster built from the js/css contents so browsers keep their cached copies across restarts and only refetch once a file actually changes
     * Falls back to a random value if nothing is found
     */
    private string function getAssetVersion() {
        var root   = replace(expandPath("/"), "\", "/", "all");
        var digest = [];

        ["includes/build", "includes/js", "includes/css"].each((dir) => {
            if(!directoryExists(root & dir)) return;

            var files = directoryList(
                path     = root & dir,
                recurse  = true,
                listInfo = "path",
                filter   = "*.js|*.css",
                type     = "file"
            );
            files.sort("textnocase");
            files.each((file) => {
                var path = replace(file, "\", "/", "all");
                digest.append("#replace(path, root, "")#:#hash(fileRead(path, "utf-8"), "MD5")#");
            });
        });

        if(!digest.len()) return right(hash(createUUID()), 10);
        return lCase(right(hash(digest.toList(chr(10)), "MD5"), 10));
    }

}
