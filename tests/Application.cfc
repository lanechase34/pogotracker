component {

    this.name = 'POGO Tracker Testing';
    this.timezone = 'America/New_York';

    _testsRoot = replace(
        getDirectoryFromPath(getCurrentTemplatePath()),
        '\',
        '/',
        'all'
    );
    _root = reReplaceNoCase(_testsRoot, '(/|\\)tests', '');

    this.mappings['/tests']        = _testsRoot;
    this.mappings['/app']          = _root & 'app';
    this.mappings['/coldbox']      = this.mappings['/app'] & '/coldbox';
    this.mappings['/interceptors'] = this.mappings['/app'] & '/interceptors';
    this.mappings['/models']       = this.mappings['/app'] & '/models';
    this.mappings['/modules']      = this.mappings['/app'] & '/modules';
    this.mappings['/interceptors'] = this.mappings['/app'] & '/interceptors';
    this.mappings['/layouts']      = this.mappings['/app'] & '/layouts';
    this.mappings['/views']        = this.mappings['/app'] & '/views';
    this.mappings['/testbox']      = this.mappings['/modules'] & '/testbox';

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

    public boolean function onRequestStart(targetPage) {
        setting requestTimeout="9999";

        request.coldBoxVirtualApp = new coldbox.system.testing.VirtualApp(appMapping = '/app');
        request.coldBoxVirtualApp.startup(true);

        if(url.keyExists('fwreinit')) {
            ormReload();
        }

        return true;
    }

    public void function onRequestEnd(targetPage) {
        request.coldBoxVirtualApp.shutdown();
    }

}
