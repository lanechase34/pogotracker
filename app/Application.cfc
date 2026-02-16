component extends="coldbox.system.Bootstrap" {

    this.name = 'POGO Tracker';

    COLDBOX_APP_ROOT_PATH = getDirectoryFromPath(getCurrentTemplatePath());
    COLDBOX_APP_MAPPING   = '';
    COLDBOX_CONFIG_FILE   = '';
    COLDBOX_APP_KEY       = '';
    COLDBOX_FAIL_FAST     = true;

    this.mappings['/']             = COLDBOX_APP_ROOT_PATH;
    this.mappings['/coldbox']      = COLDBOX_APP_ROOT_PATH & 'coldbox';
    this.mappings['/includes']     = COLDBOX_APP_ROOT_PATH & 'includes';
    this.mappings['/interceptors'] = COLDBOX_APP_ROOT_PATH & 'interceptors';
    this.mappings['/models']       = COLDBOX_APP_ROOT_PATH & 'models';
    this.mappings['/services']     = this.mappings['/models'] & '/services';
    this.mappings['/layouts']      = COLDBOX_APP_ROOT_PATH & 'layouts';
    this.mappings['/views']        = COLDBOX_APP_ROOT_PATH & 'views';

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

    function onError(struct exception, string eventName) {
        writeOutput('Oops. Please try again later.');
    }

}
