component singleton accessors="true" {

    property name="pagination"  inject="services.pagination";
    property name="utilService" inject="services.util";

    property name="datatableCols"        type="array";
    property name="requestDatatableCols" type="array";

    public void function init() {
        setDatatableCols([
            "audit.id",
            "audit.created",
            "audit.ip",
            "audit.event",
            "audit.referer",
            "audit.detail",
            "audit.agent",
            "trainer.username"
        ]);

        setRequestDatatableCols([
            "requestlog.created",
            "requestlog.ip",
            "requestlog.urlpath",
            "requestlog.method",
            "requestlog.agent",
            "requestlog.response",
            "requestlog.statuscode",
            "requestlog.referer",
            "trainer.username"
        ]);
    }

    /**
     * Insert a new audit record
     * Values are cut to their column widths here
     * Fire and forget - the insert runs in the background and a failure is only logged
     *
     * @wait insert on this thread instead, for callers that read the audit table straight after
     */
    public void function audit(
        required string ip,
        required string event,
        required string referer,
        required string detail,
        required string agent,
        numeric trainerid = -1,
        boolean wait      = false
    ) {
        var params = {
            ip       : {value: left(arguments.ip, 45), cfsqltype: "varchar"},
            event    : {value: left(arguments.event, 250), cfsqltype: "varchar"},
            referer  : {value: left(arguments.referer, 250), cfsqltype: "varchar"},
            detail   : {value: left(arguments.detail, 10000), cfsqltype: "varchar"},
            agent    : {value: left(arguments.agent, 250), cfsqltype: "varchar"},
            trainerid: {
                value    : arguments.trainerid,
                cfsqltype: "integer",
                null     : arguments.trainerid <= 0
            }
        };

        var insertAudit = () => {
            queryExecute(
                "
                INSERT INTO audit (ip, event, referer, detail, agent, trainerid)
                VALUES (:ip, :event, :referer, :detail, :agent, (SELECT id FROM trainer WHERE id = :trainerid))
                ",
                params
            );
        };

        if(arguments.wait) {
            insertAudit();
            return;
        }

        utilService.runInBackground(task = insertAudit, failure = "Failed to audit #params.event.value#");
        return;
    }

    /**
     * Audit work the app does itself (scraper, admin jobs) - there is no request, so no ip, referer or agent to record
     *
     * @event  where it happened, e.g. scraperService.getData
     * @detail what happened
     */
    public void function auditSystem(required string event, required string detail) {
        audit(
            ip      = "localhost",
            event   = arguments.event,
            referer = "",
            detail  = arguments.detail,
            agent   = ""
        );
        return;
    }

    /**
     * Datatable GET for audit table
     */
    public struct function getTable(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = "",
        string range             = "all"
    ) {
        var fromSQL = "FROM audit LEFT JOIN trainer ON trainer.id = audit.trainerid";
        var filters = pagination.buildFilters(
            searchColumns = [
                "audit.event",
                "audit.referer",
                "audit.detail",
                "audit.agent",
                "trainer.username"
            ],
            search     = search,
            dateColumn = "audit.created",
            range      = range
        );
        var whereSQL = filters.whereSQL;

        var orderBy = pagination.orderBy(
            columns     = getDatatableCols(),
            orders      = [{column: orderCol, dir: orderDir}],
            defaultSort = "audit.id ASC",
            tiebreak    = "audit.id ASC"
        );

        var page = pagination.paginate(
            records       = records,
            offset        = offset,
            fromSQL       = fromSQL,
            baseWhere     = filters.baseWhere,
            whereSQL      = whereSQL,
            baseParams    = filters.baseParams,
            whereParams   = filters.whereParams,
            totalCacheKey = pagination.rangeCacheKey("audit.totalRecords", range),
            cacheMinutes  = 5,
            fetchRows     = (pageParams) => queryExecute(
                "
                SELECT audit.created, COALESCE(audit.ip, '') AS ip, COALESCE(audit.event, '') AS event,
                    COALESCE(audit.referer, '') AS referer, COALESCE(audit.detail, '') AS detail,
                    COALESCE(audit.agent, '') AS agent, COALESCE(trainer.username, '') AS username
                #fromSQL#
                #whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returnType: "array"}
            )
        );

        return {
            data: page.rows.map((row) => {
                return {
                    "timestamp": dateTimeFormat(row.created, "short"),
                    "ip"       : row.ip,
                    "event"    : row.event,
                    "referer"  : row.referer,
                    "detail"   : row.detail,
                    "agent"    : row.agent,
                    "username" : row.username
                };
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
    }

    /**
     * Insert a new record detailing a request's information
     * Values are cut to their column widths here
     * Fire and forget - the insert runs in the background and a failure is only logged
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
        var params = {
            ip        : {value: left(arguments.ip, 100), cfsqltype: "varchar"},
            urlpath   : {value: left(arguments.urlpath, 500), cfsqltype: "varchar"},
            method    : {value: left(arguments.method, 10), cfsqltype: "varchar"},
            agent     : {value: left(arguments.agent, 250), cfsqltype: "varchar"},
            referer   : {value: left(arguments.referer, 250), cfsqltype: "varchar"},
            response  : {value: arguments.response, cfsqltype: "varchar"},
            statuscode: {
                value    : arguments.statuscode,
                cfsqltype: "decimal",
                scale    : 0
            },
            delta    : {value: arguments.delta, cfsqltype: "integer"},
            trainerid: {
                value    : arguments.trainerid,
                cfsqltype: "integer",
                null     : arguments.trainerid <= 0
            }
        };

        utilService.runInBackground(
            task = () => {
                queryExecute(
                    "
                    INSERT INTO request_log (ip, urlpath, method, agent, referer, response, statuscode, delta, trainerid)
                    VALUES (:ip, :urlpath, :method, :agent, :referer, :response, :statuscode, :delta, (SELECT id FROM trainer WHERE id = :trainerid))
                    ",
                    params
                );
            },
            failure = "Failed to log request #params.urlpath.value#"
        );
        return;
    }

    /**
     * Datatable GET for request_log table
     */
    public struct function getRequests(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = "",
        string range             = "all"
    ) {
        var fromSQL = "FROM request_log AS requestlog LEFT JOIN trainer ON trainer.id = requestlog.trainerid";
        var filters = pagination.buildFilters(
            searchColumns = [
                "requestlog.ip",
                "requestlog.urlpath",
                "requestlog.method",
                "requestlog.agent",
                "requestlog.response",
                "requestlog.referer",
                "CAST(requestlog.statuscode AS varchar)",
                "trainer.username"
            ],
            search     = search,
            dateColumn = "requestlog.created",
            range      = range
        );
        var whereSQL = filters.whereSQL;

        var orderBy = pagination.orderBy(
            columns     = getRequestDatatableCols(),
            orders      = [{column: orderCol, dir: orderDir}],
            defaultSort = "requestlog.id ASC",
            tiebreak    = "requestlog.id ASC"
        );

        var page = pagination.paginate(
            records       = records,
            offset        = offset,
            fromSQL       = fromSQL,
            baseWhere     = filters.baseWhere,
            whereSQL      = whereSQL,
            baseParams    = filters.baseParams,
            whereParams   = filters.whereParams,
            totalCacheKey = pagination.rangeCacheKey("audit.totalRequestRecords", range),
            cacheMinutes  = 5,
            fetchRows     = (pageParams) => queryExecute(
                "
                SELECT requestlog.created, COALESCE(requestlog.ip, '') AS ip, COALESCE(requestlog.urlpath, '') AS urlpath,
                    COALESCE(requestlog.method, '') AS method, COALESCE(requestlog.agent, '') AS agent,
                    COALESCE(requestlog.response, '') AS response, requestlog.statuscode,
                    COALESCE(requestlog.referer, '') AS referer, COALESCE(trainer.username, '') AS username
                #fromSQL#
                #whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returnType: "array"}
            )
        );

        return {
            data: page.rows.map((row) => {
                return [
                    dateTimeFormat(row.created, "short"),
                    row.ip,
                    "#left(row.urlpath, 150)##row.urlpath.len() > 150 ? "..." : ""#",
                    row.method,
                    row.agent,
                    "#left(row.response, 150)##row.response.len() > 150 ? "..." : ""#",
                    row.statuscode,
                    row.referer,
                    row.username
                ];
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
    }

    /**
     * Returns skeleton audit struct
     */
    public struct function getAuditObj(
        required numeric trainerid,
        string referer,
        string event = ""
    ) {
        return {
            ip       : utilService.getRequestIP(),
            event    : event,
            referer  : arguments?.referer ?: utilService.getReferer(),
            detail   : "",
            agent    : utilService.getUserAgent(),
            trainerid: trainerid
        }
    }

}
