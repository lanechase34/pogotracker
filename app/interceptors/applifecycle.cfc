component extends="coldbox.system.Interceptor" {

    property name="concurrency" inject="coldbox:setting:concurrency";
    property name="environment" inject="coldbox:setting:environment";
    property name="uploadPath"  inject="coldbox:setting:uploadPath";

    /**
     * Runs after Coldbox configuration loads - similar to onApplicationStart
     * Will verify dependencies on prod
     */
    function afterAspectsLoad(event, data, buffer, rc, prc) {
        if(!directoryExists(uploadPath)) {
            directoryCreate(uploadPath);
        }

        if(!directoryExists('#uploadPath#/cards')) {
            directoryCreate('#uploadPath#/cards');
        }

        if(!directoryExists('#uploadPath#/full')) {
            directoryCreate('#uploadPath#/full');
        }

        if(!directoryExists('#uploadPath#/extra')) {
            directoryCreate('#uploadPath#/extra');
        }

        // Check DB
        try {
            queryExecute('SELECT 1', []);
        }
        catch(any e) {
            throw('Cannot connect to database');
        }

        // Check imagemagick
        if(environment == 'production' && !getInstance('services.image').verifyImageMagick()) {
            throw('Imagemagick is not running');
        }

        // Check email
        if(environment == 'production' && !getInstance('services.email').verifyConnection()) {
            throw('Cannot connect to email server');
        }
    }

    /**
     * Track number of active requests
     */
    function preProcess(event, data, buffer, rc, prc) {
        lock name="concurrencyLock" timeout="5" type="exclusive" throwOnTimeout=false {
            concurrency.activeRequests += 1;
            concurrency.maxRequests = max(concurrency.maxRequests, concurrency.activeRequests);
        }
    }

}
