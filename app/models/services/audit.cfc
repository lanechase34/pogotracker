component singleton accessors="true" {

    property name="cacheService"    inject="services.cache";
    property name="trainerService"  inject="services.trainer";
    property name="securityService" inject="services.security";

    property name="datatableCols"        type="array";
    property name="requestDatatableCols" type="array";

    public void function init() {
        setDatatableCols([
            'audit.created',
            'audit.ip',
            'audit.event',
            'audit.referer',
            'audit.detail',
            'audit.agent',
            'trainer.username'
        ]);

        setRequestDatatableCols([
            'requestlog.created',
            'requestlog.ip',
            'requestlog.urlpath',
            'requestlog.method',
            'requestlog.agent',
            'requestlog.response',
            'requestlog.statuscode',
            'requestlog.referer',
            'trainer.username'
        ]);
    }

    /**
     * Insert a new audit record
     */
    public void function audit(
        required string ip,
        required string event,
        required string referer,
        required string detail,
        required string agent,
        numeric trainerid = -1
    ) {
        var audit = entityNew(
            'audit',
            {
                'ip'     : arguments.ip,
                'event'  : arguments.event,
                'referer': arguments.referer,
                'detail' : arguments.detail,
                'agent'  : arguments.agent
            }
        );

        if(arguments.trainerid > 0) {
            var trainer = trainerService.getFromId(arguments.trainerid);
            audit.setTrainer(trainer);
        }

        entitySave(audit);
        ormFlush();
        return;
    }

    /**
     * Datatable GET for audit table
     */
    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = '',
        required string orderCol = '',
        required string orderDir = ''
    ) {
        var orderBy = '';
        if(arguments.orderCol.len() && arguments.orderDir.len()) {
            orderBy = 'order by #getDatatableCols()[arguments.orderCol + 1]# #arguments.orderDir#';
        }

        var audits = ormExecuteQuery(
            '
            select audit
            from audit as audit
            left outer join audit.trainer as trainer
            where upper(audit.event) like :search
                or upper(audit.referer) like :search
                or upper(audit.detail) like :search
                or upper(audit.agent) like :search
                or upper(trainer.username) like :search
            #orderBy#
            ',
            {search: '%#uCase(arguments.search)#%'},
            {
                offset    : arguments.offset,
                maxResults: arguments.records,
                cacheable : true,
                cachename : 'defaultCache'
            }
        );

        var filteredCount = ormExecuteQuery(
            '
            select count(audit.id)
            from audit as audit
            left outer join audit.trainer as trainer
            where upper(audit.event) like :search
                or upper(audit.referer) like :search
                or upper(audit.detail) like :search
                or upper(audit.agent) like :search
                or upper(trainer.username) like :search
            ',
            {search: '%#uCase(arguments.search)#%'}
        );

        var data = [];
        audits.each((audit) => {
            data.append([
                audit.getTimestamp(),
                audit.getIP(),
                audit.getEvent(),
                audit.getReferer(),
                audit.getDetail(),
                audit.getAgent(),
                audit.getUsername()
            ]);
        });

        return {
            data           : data,
            recordsTotal   : getTotalRecords(),
            recordsFiltered: filteredCount
        };
    }

    /**
     * Get total count of records in audit table
     */
    private numeric function getTotalRecords() {
        var cacheKey = 'audit.getTotalRecords';
        var count    = cacheService.get(cacheKey);
        if(isNull(count)) {
            count = ormExecuteQuery('select count(id) from audit')[1];
            cacheService.put(cacheKey, count, 5, 5);
        }
        return count;
    }

    /**
     * Insert a new record detailing a request's information
     */
    public void function logRequest(
        required string ip,
        required string urlpath,
        required string method,
        required string agent,
        required string referer,
        required string response,
        numeric statuscode = -1,
        numeric trainerid  = -1,
        numeric delta      = -1
    ) {
        var requestLog = entityNew(
            'requestlog',
            {
                'ip'        : ip,
                'urlpath'   : urlpath,
                'method'    : method,
                'agent'     : agent,
                'referer'   : referer,
                'response'  : response,
                'statuscode': statuscode,
                'delta'     : delta
            }
        );

        if(trainerid > 0) {
            requestLog.setTrainer(trainerService.getFromId(trainerid));
        }

        entitySave(requestLog);
        ormFlush();
        return;
    }

    /**
     * Datatable GET for request_log table
     */
    public struct function getRequests(
        required numeric records,
        required numeric offset,
        required string search   = '',
        required string orderCol = '',
        required string orderDir = ''
    ) {
        var orderBy = '';
        if(arguments.orderCol.len() && arguments.orderDir.len()) {
            orderBy = 'order by #getRequestDatatableCols()[arguments.orderCol + 1]# #arguments.orderDir#';
        }

        var requests = ormExecuteQuery(
            '
            select requestlog
            from requestlog as requestlog
            left outer join requestlog.trainer as trainer
            where upper(requestlog.ip) like :search
                or upper(requestlog.urlpath) like :search
                or upper(requestlog.method) like :search
                or upper(requestlog.agent) like :search
                or upper(requestlog.response) like :search
                or upper(requestlog.referer) like :search
                 or upper(cast(requestlog.statuscode as string)) like :search
                or upper(trainer.username) like :search
            #orderBy#
            ',
            {search: '%#uCase(arguments.search)#%'},
            {
                offset    : arguments.offset,
                maxResults: arguments.records,
                cacheable : true,
                cachename : 'defaultCache'
            }
        );

        var filteredCount = ormExecuteQuery(
            '
            select count(requestlog.id)
            from requestlog as requestlog
            left outer join requestlog.trainer as trainer
            where upper(requestlog.ip) like :search
                or upper(requestlog.urlpath) like :search
                or upper(requestlog.method) like :search
                or upper(requestlog.agent) like :search
                or upper(requestlog.response) like :search
                or upper(requestlog.referer) like :search
                or cast(requestlog.statuscode as string) like :search
                or upper(trainer.username) like :search
            ',
            {search: '%#uCase(arguments.search)#%'}
        );

        var data = [];
        requests.each((requestObj) => {
            data.append([
                requestObj.getTimestamp(),
                requestObj.getIP(),
                '#left(requestObj.getUrlPath(), 150)##requestObj.getUrlPath().len() > 150 ? '...' : ''#',
                requestObj.getMethod(),
                requestObj.getAgent(),
                '#left(requestObj.getResponse(), 150)##requestObj.getResponse().len() > 150 ? '...' : ''#',
                requestObj.getStatusCode(),
                requestObj.getReferer(),
                requestObj.getUsername()
            ]);
        });

        return {
            data           : data,
            recordsTotal   : getTotalRequestRecords(),
            recordsFiltered: filteredCount
        };
    }

    /**
     * Get total count of records in request_log table
     */
    private numeric function getTotalRequestRecords() {
        var cacheKey = 'audit.getTotalRequestRecords';
        var count    = cacheService.get(cacheKey);
        if(isNull(count)) {
            count = ormExecuteQuery('select count(id) from requestlog')[1];
            cacheService.put(cacheKey, count, 5, 5);
        }
        return count;
    }

    /**
     * Returns skeleton audit struct
     */
    public struct function getAuditObj(
        required numeric trainerid,
        string referer,
        string event = ''
    ) {
        return {
            ip       : securityService.getRequestIP(),
            event    : left(event, 250),
            referer  : left(arguments?.referer ?: securityService.getReferer(), 250),
            detail   : '',
            agent    : left(securityService.getUserAgent(), 250),
            trainerid: trainerid
        }
    }

}
