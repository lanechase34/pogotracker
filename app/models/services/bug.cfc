component singleton accessors="true" {

    property name="pagination"  inject="services.pagination";
    property name="utilService" inject="services.util";

    property name="datatableCols" type="array";

    public void function init() {
        setDatatableCols([
            "bug.created",
            "bug.ip",
            "bug.event",
            "bug.message",
            "trainer.username",
            "bug.stack"
        ]);
    }

    /**
     * Log a new bug including exception stack trace
     * Values are cut to their column widths here
     * Fire and forget - the insert runs in the background and a failure is only logged
     */
    public void function logBug(
        required string ip,
        required string event,
        required string message,
        required string stack,
        numeric trainerid = -1
    ) {
        var params = {
            ip       : {value: left(arguments.ip, 128), cfsqltype: "varchar"},
            event    : {value: left(arguments.event, 250), cfsqltype: "varchar"},
            message  : {value: left(arguments.message, 256), cfsqltype: "varchar"},
            stack    : {value: arguments.stack, cfsqltype: "varchar"},
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
                    INSERT INTO bug (ip, event, message, stack, trainerid)
                    VALUES (:ip, :event, :message, :stack, (SELECT id FROM trainer WHERE id = :trainerid))
                    ",
                    params
                );
            },
            failure = "Failed to log bug #params.event.value#"
        );
        return;
    }

    /**
     * Datatable GET for bug log table
     */
    public struct function getTable(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = "",
        string range             = "all"
    ) {
        var fromSQL = "FROM bug LEFT JOIN trainer ON trainer.id = bug.trainerid";
        var filters = pagination.buildFilters(
            searchColumns = ["bug.event", "bug.message", "trainer.username"],
            search        = search,
            dateColumn    = "bug.created",
            range         = range
        );
        var whereSQL = filters.whereSQL;

        var orderBy = pagination.orderBy(
            columns     = getDatatableCols(),
            orders      = [{column: orderCol, dir: orderDir}],
            defaultSort = "bug.id ASC",
            tiebreak    = "bug.id ASC"
        );

        var page = pagination.paginate(
            records       = records,
            offset        = offset,
            fromSQL       = fromSQL,
            baseWhere     = filters.baseWhere,
            whereSQL      = whereSQL,
            baseParams    = filters.baseParams,
            whereParams   = filters.whereParams,
            totalCacheKey = pagination.rangeCacheKey("bug.totalRecords", range),
            cacheMinutes  = 5,
            fetchRows     = (pageParams) => queryExecute(
                "
                SELECT bug.id, bug.created, COALESCE(bug.ip, '') AS ip, COALESCE(bug.event, '') AS event,
                    COALESCE(bug.message, '') AS message, COALESCE(bug.stack, '') AS stack,
                    COALESCE(trainer.username, '') AS username
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
                    "id"       : row.id,
                    "timestamp": dateTimeFormat(row.created, "short"),
                    "ip"       : row.ip,
                    "event"    : row.event,
                    "message"  : row.message,
                    "username" : row.username,
                    "stack"    : row.stack
                };
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
    }

}
