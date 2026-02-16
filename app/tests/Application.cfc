component {

    this.name = 'POGO Tracker Testing';

    this.mappings['/tests'] = getDirectoryFromPath(getCurrentTemplatePath());
    rootPath                = reReplaceNoCase(this.mappings['/tests'], 'tests(\\|/)', '');

    this.mappings['/root']         = rootPath;
    this.mappings['/coldbox']      = rootPath & 'coldbox';
    this.mappings['/interceptors'] = rootPath & 'interceptors';
    this.mappings['/testbox']      = rootPath & 'modules/testbox';
    this.mappings['/models']       = rootPath & 'models';
    this.mappings['/services']     = rootPath & '/services';

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

        request.coldBoxVirtualApp = new coldbox.system.testing.VirtualApp(appMapping = '/root');
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
