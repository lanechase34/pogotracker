component singleton accessors="true" {

    property name="pagination"     inject="services.pagination";
    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

    property name="datatableCols"        type="array";
    property name="requestDatatableCols" type="array";

    public void function init() {
        setDatatableCols([
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
            "audit",
            {
                "ip"     : arguments.ip,
                "event"  : arguments.event,
                "referer": arguments.referer,
                "detail" : arguments.detail,
                "agent"  : arguments.agent
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
        required string search   = "",
        required string orderCol = "",
        required string orderDir = ""
    ) {
        var fromSQL     = "FROM audit LEFT JOIN trainer ON trainer.id = audit.trainerid";
        var whereSQL    = "";
        var whereParams = {};
        if(search.len()) {
            whereSQL = "WHERE #pagination.searchSQL([
                "audit.event",
                "audit.referer",
                "audit.detail",
                "audit.agent",
                "trainer.username"
            ])#";
            whereParams.search = {value: utilService.likeContains(search), cfsqltype: "varchar"};
        }

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
            baseWhere     = "",
            whereSQL      = whereSQL,
            whereParams   = whereParams,
            totalCacheKey = "audit.totalRecords",
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
                {returntype: "array"}
            )
        );

        return {
            data: page.rows.map((row) => {
                return [
                    dateTimeFormat(row.created, "short"),
                    row.ip,
                    row.event,
                    row.referer,
                    row.detail,
                    row.agent,
                    row.username
                ];
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
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
            "requestlog",
            {
                "ip"        : ip,
                "urlpath"   : urlpath,
                "method"    : method,
                "agent"     : agent,
                "referer"   : referer,
                "response"  : response,
                "statuscode": statuscode,
                "delta"     : delta
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
        required string search   = "",
        required string orderCol = "",
        required string orderDir = ""
    ) {
        var fromSQL     = "FROM request_log AS requestlog LEFT JOIN trainer ON trainer.id = requestlog.trainerid";
        var whereSQL    = "";
        var whereParams = {};
        if(search.len()) {
            whereSQL = "WHERE #pagination.searchSQL([
                "requestlog.ip",
                "requestlog.urlpath",
                "requestlog.method",
                "requestlog.agent",
                "requestlog.response",
                "requestlog.referer",
                "CAST(requestlog.statuscode AS varchar)",
                "trainer.username"
            ])#";
            whereParams.search = {value: utilService.likeContains(search), cfsqltype: "varchar"};
        }

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
            baseWhere     = "",
            whereSQL      = whereSQL,
            whereParams   = whereParams,
            totalCacheKey = "audit.totalRequestRecords",
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
                {returntype: "array"}
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
            event    : left(event, 250),
            referer  : left(arguments?.referer ?: utilService.getReferer(), 250),
            detail   : "",
            agent    : left(utilService.getUserAgent(), 250),
            trainerid: trainerid
        }
    }

}
