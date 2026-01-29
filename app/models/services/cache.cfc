component singleton accessors="true" {

    property name="defaultCache" type="component" getter="true";

    public void function init() {
        setDefaultCache(application.cbController.getCacheBox().getDefaultCache());
    }

    public void function put(
        required string key,
        required any item,
        numeric timeout     = application.cbController.getSetting('cacheTimeout'), // timeout in minutes
        numeric idleTimeout = application.cbController.getSetting('cacheIdleTimeout')
    ) {
        if(application.cbController.getSetting('useCache')) {
            getDefaultCache().set(
                arguments.key,
                arguments.item,
                arguments.timeout,
                arguments.idleTimeout
            );
        }
        return;
    }

    public any function get(required string key) {
        return getDefaultCache().get(arguments.key);
    }

    public void function remove(required string key) {
        getDefaultCache().clear(arguments.key);
        return;
    }

    public array function getAllKeys() {
        return getDefaultCache().getKeys();
    }

    public any function getStats() {
        return getDefaultCache().getStats();
    }

    /**
     * Filters all cache keys based on incoming filter and removes any matches
     *
     * @filter 
     */
    public void function clear(required string filter) {
        var cacheKeys    = getAllKeys();
        var filteredKeys = cacheKeys.filter(
            (key) => {
                return key.findNoCase(filter);
            },
            true,
            application.cbController.getSetting('maxThreads')
        );
        filteredKeys.each(
            (key) => {
                remove(key);
            },
            true,
            application.cbController.getSetting('maxThreads')
        );
    }

    public struct function getData() {
        return getDefaultCache().getCachedObjectMetadataMulti(getAllKeys().toList(','));
    }

    public void function clearAll() {
        getDefaultCache().clearAll();
    }

}
