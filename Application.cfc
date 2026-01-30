component {

    this.name     = 'POGO Tracker';
    this.timezone = 'America/New_York';

    _root = replace(
        getDirectoryFromPath(getCurrentTemplatePath()),
        '\',
        '/',
        'all'
    );

    this.mappings['/app']          = _root & 'app';
    this.mappings['/coldbox']      = this.mappings['/app'] & '/coldbox';
    this.mappings['/interceptors'] = this.mappings['/app'] & '/interceptors';
    this.mappings['/models']       = this.mappings['/app'] & '/models';
    this.mappings['/modules']      = this.mappings['/app'] & '/modules';
    this.mappings['/interceptors'] = this.mappings['/app'] & '/interceptors';
    this.mappings['/layouts']      = this.mappings['/app'] & '/layouts';
    this.mappings['/views']        = this.mappings['/app'] & '/views';

    COLDBOX_APP_ROOT_PATH = this.mappings['/app'];
    COLDBOX_APP_MAPPING   = '/app';
    COLDBOX_WEB_MAPPING   = '/';
    COLDBOX_CONFIG_FILE   = '';
    COLDBOX_APP_KEY       = '';
    COLDBOX_FAIL_FAST     = true;

    this.datasource  = 'pogotracker';
    this.ormEnabled  = true;
    this.ormSettings = {
        autoGenMap           : true,
        autoManageSession    : false,
        cacheProvider        : 'ehcache',
        cfclocation          : '/models/orm',
        datasource           : 'pogotracker',
        dbcreate             : 'none',
        dialect              : 'PostgreSQL',
        eventHandling        : true,
        eventHandler         : 'models.orm.handler',
        flushAtRequestEnd    : false,
        logSQL               : false,
        secondaryCacheEnabled: true,
        useDBForMapping      : true
    };

    /**
	 * Fires when the application starts
	 */
    public boolean function onApplicationStart() {
        application.cbBootstrap = new coldbox.system.Bootstrap(
            COLDBOX_CONFIG_FILE,
            COLDBOX_APP_ROOT_PATH,
            COLDBOX_APP_KEY,
            COLDBOX_APP_MAPPING,
            COLDBOX_FAIL_FAST,
            COLDBOX_WEB_MAPPING
        );
        application.cbBootstrap.loadColdbox();
        return true;
    }

    /**
	 * Fires when the application ends
	 *
	 * @appScope The app scope
	 */
    public void function onApplicationEnd(struct appScope) {
        arguments.appScope.cbBootstrap.onApplicationEnd(arguments.appScope);
    }

    /**
	 * Process a ColdBox Request
	 *
	 * @targetPage The requested page
	 */
    public boolean function onRequestStart(string targetPage) {
        if(!application.keyExists('cbBootstrap')) onApplicationStart();
        return application.cbBootstrap.onRequestStart(arguments.targetPage);
    }

    /**
	 * Fires on every session start
	 */
    public void function onSessionStart() {
        if(!isNull(application.cbBootstrap)) {
            application.cbBootStrap.onSessionStart()
        }
    }

    /**
	 * Fires on session end
	 *
	 * @sessionScope The session scope
	 * @appScope     The app scope
	 */
    public void function onSessionEnd(struct sessionScope, struct appScope) {
        arguments.appScope.cbBootStrap.onSessionEnd(argumentCollection = arguments);
    }

    /**
	 * On missing template handler
	 *
	 * @template
	 */
    public boolean function onMissingTemplate(template) {
        return application.cbBootstrap.onMissingTemplate(argumentCollection = arguments);
    }

    /**
     * Application error
     */
    function onError(struct exception, string eventName) {
        writeOutput('Oops. Please try again later.');
    }

}
