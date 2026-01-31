component {

    /**
	 * Configure the ColdBox App For Production 
	 * https://coldbox.ortusbooks.com/getting-started/configuration
	 */
    function configure() {
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
            appName                 : 'POGO Tracker',
            eventName               : 'event',
            // Development Settings
            reinitPassword          : getSystemSetting('REINITKEY'),
            reinitKey               : 'fwreinit',
            handlersIndexAutoReload : false,
            // Implicit Events
            defaultEvent            : 'error.notFound',
            requestStartHandler     : 'main.onRequestStart',
            requestEndHandler       : '',
            applicationStartHandler : '',
            applicationEndHandler   : '',
            sessionStartHandler     : 'main.onSessionStart',
            sessionEndHandler       : '',
            missingTemplateHandler  : 'error.notFound',
            // Extension Points
            applicationHelper       : '',
            viewsHelper             : '',
            modulesExternalLocation : [],
            viewsExternalLocation   : '',
            layoutsExternalLocation : '',
            handlersExternalLocation: '',
            requestContextDecorator : '',
            controllerDecorator     : '',
            // Error/Exception Handling
            invalidHTTPMethodHandler: 'error.invalidHTTPMethod',
            exceptionHandler        : 'error.onException',
            invalidEventHandler     : 'error.notFound',
            customErrorTemplate     : '/views/fragment/exception.cfm',
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
            basePath        : replace(expandPath('/'), '\', '/', 'all') & '/app',
            rootPath        : replace(expandPath('/'), '\', '/', 'all'),
            cacheBuster     : '?v=#right(hash(createUUID()), 10)#',
            cacheIdleTimeout: 30,
            cacheTimeout    : 120,
            concurrency     : {
                activeRequests: 0,
                maxRequests   : 0,
                slowRequests  : []
            },
            contactEmail: 'chaselane@pogotracker.app',
            csrfChecks  : {
                // Validate the CSRF Token for these actions
                persistlogin  : true,
                dologin       : true,
                register      : true,
                verify        : true,
                forgotpassword: true,
                resetpassword : true
            },
            csrfTokenField: left(
                hash(
                    createGUID(),
                    getSystemSetting('ALGORITHM'),
                    'UTF-8',
                    getSystemSetting('ITERATIONS')
                ),
                25
            ),
            cssPath        : '/includes/build/css',
            debugging      : false,
            defaultSettings: {
                defaultView  : '',
                defaultRegion: 'Kanto',
                defaultPage  : '/'
            },
            domain         : 'https://pogotracker.app',
            eventDaysBefore: 3, // task pulls in events up to 3 days before they start before creating custom entries automatically
            favIcoVersion  : 3,
            fetchCount     : 7, // number of news/leekduck posts to fetch on home page
            fromEmail      : 'noreply@pogotracker.app',
            getShadowData  : false, // get shadow data from wikipedia
            healthCheck    : true,
            httpPort       : getSystemSetting('HTTP_PORT'),
            imageExtension : '.webp',
            imageMagickPath: getSystemSetting('IMAGEMAGICKPATH'),
            impersonation  : false,
            jsPath         : '/includes/build/js',
            logPath        : getPageContext().getServletContext().getRealPath('/WEB-INF/'),
            logRequests    : false,
            maxThreads     : 25,
            metaDescription: 'POGO Tracker offers in-depth analytics on your Pokémon collection, daily catches, walking distance, medal achievements, and much more',
            metaKeywords   : 'Pokémon GO, pogotracker, POGO Tracker, Pokémon GO Pokédex, Pokémon GO stats, Pokémon GO statistics, Pokémon GO daily XP, POGO xp tracker, Pokémon GO Track Pokédex, shiny Pokémon tracker',
            // Minified CSS, JS settings
            minifiedCSS    : '.min',
            minifiedJS     : '.min',
            // Ordered struct, maps value -> display
            pageMap        : [
                '/'                 : 'Home',
                '/mypokedex'        : 'Pokedex',
                '/myshadowpokedex'  : 'Shadow Pokedex',
                '/custompokedexlist': 'Custom Pokedex',
                '/buildtradeplan'   : 'Trade Plan',
                '/overview'         : 'Stats'
            ],
            persistCookieName: hash(
                createGUID(),
                getSystemSetting('ALGORITHM'),
                'UTF-8',
                getSystemSetting('ITERATIONS')
            ),
            persistDuration: 30, // Persist cookie last 30 days
            persistUse     : 7, // If not used in 7 days, automatically expire
            reCaptchaChecks: {
                // Validate a user's recaptcha session data for these actions
                dologin       : true,
                forgotpassword: true,
                register      : true
            },
            reCaptchaSiteKey  : getSystemSetting('RECAPTCHASITEKEY'),
            reCaptchaSecretKey: getSystemSetting('RECAPTCHASECRETKEY'),
            refererChecks     : {
                // Mapped action -> the referer
                dologin       : '/login',
                register      : '/register',
                verify        : '/verify',
                forgotpassword: '/forgot',
                resetpassword : '/reset'
            },
            requestLog: {
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
            sessionTimeout       : getSystemSetting('SESSIONTIMEOUT'),
            signups              : true, // whether signups are enabled
            sitemap              : 'sitemap.xml',
            testEmailPath        : '#replace(expandPath('/'), '\', '/', 'all')#/_testemails',
            uploadPath           : '#replace(expandPath('/'), '\', '/', 'all')#/includes/uploads',
            title                : 'POGO Tracker',
            useCache             : true,
            useRecaptcha         : true,
            verificationLifespan : 15, // time in minutes the verification link is valid for
            verificationCooldown : 900, // time in seconds to wait for a new verification code
            // Ordered struct, maps value -> display
            viewMap              : ['normal': 'Normal', 'shiny': 'Shiny'],
            warmedUp             : false, // updates to true after server has finished warming up
            writeJson            : false
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
		 * By Default we log to the console, but you can add many appenders or destinations to log to.
		 * You can also choose the logging level of the root logger, or even the actual appender.
		 */
        logBox = {
            // Define Appenders
            appenders: {coldboxTracer: {class: 'coldbox.system.logging.appenders.ConsoleAppender'}},
            // Root Logger
            root     : {levelmax: 'INFO', appenders: '*'},
            // Implicit Level Categories
            info     : ['coldbox.system']
        };

        /**
		 * --------------------------------------------------------------------------
		 * Layout Settings
		 * --------------------------------------------------------------------------
		 */
        layoutSettings = {defaultLayout: 'default.cfm', defaultView: 'fragment/blank.cfm'};

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
                class     : 'interceptors.applifecycle',
                name      : 'appLifeCycleInterceptor',
                properties: {}
            },
            {
                class     : 'interceptors.mail',
                name      : 'mailInterceptor',
                properties: {}
            },
            {
                class     : 'interceptors.response',
                name      : 'responseInterceptor',
                properties: {}
            },
            {
                class     : 'interceptors.flashalert',
                name      : 'flashAlertInterceptor',
                properties: {}
            },
            {
                class     : 'interceptors.logrequest',
                name      : 'logRequestInterceptor',
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
        moduleSettings = {};

        /**
		 * --------------------------------------------------------------------------
		 * Flash Scope Settings
		 * --------------------------------------------------------------------------
		 * The available scopes are : session, client, cluster, ColdBoxCache, or a full instantiation CFC path
		 */
        flash = {
            scope       : 'session',
            properties  : {}, // constructor properties for the flash scope implementation
            inflateToRC : true, // automatically inflate flash data into the RC scope
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
            handlersLocation: 'handlers',
            viewsLocation   : 'views',
            layoutsLocation : 'layouts',
            modelsLocation  : 'models',
            eventAction     : 'index'
        };
    }

    /**
	 * Development environment
	 */
    function development() {
        coldbox.handlersIndexAutoReload = true;
        coldbox.handlerCaching          = false;
        coldbox.eventCaching            = false;
        coldbox.viewCaching             = false;

        coldbox.reinitPassword      = '';
        coldbox.customErrorTemplate = '/coldbox/system/exceptions/Whoops.cfm';
        coldbox.debugMode           = true;

        // Development settings
        settings.title        = '[DEV #ucFirst(getSystemSetting('OS'))#] POGO Tracker';
        settings.useRecaptcha = false;
        settings.writeJson    = true;
        settings.logRequests  = false;

        // This allows the testing suite to test the login endpoints
        settings.impersonation = true;
        settings.refererChecks = {};

        // settings.debugging     = true;
        // settings.useCache      = false;
        settings.getShadowData = true;
        // settings.warmedup      = true;

        // Comment to use minified files
        settings.cssPath     = '/includes/css';
        settings.jsPath      = '/includes/js';
        settings.minifiedCSS = '';
        settings.minifiedJS  = '';
    }

    /**
     * Test environment
     */
    function test() {
        settings.useRecaptcha  = false;
        settings.title         = '[TEST #ucFirst(getSystemSetting('OS'))#] POGO Tracker';
        // This allows the testing suite to test the login endpoints
        settings.impersonation = true;
        settings.refererChecks = {};
        settings.logRequests   = false;
    }

}
