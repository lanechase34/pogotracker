component singleton accessors="true" {

    property name="pagination"     inject="services.pagination";
    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

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
     */
    public void function logBug(
        required string ip,
        required string event,
        required string message,
        required string stack,
        numeric trainerid = -1
    ) {
        var bug = entityNew(
            "bug",
            {
                "ip"     : arguments.ip,
                "event"  : arguments.event,
                "message": arguments.message,
                "stack"  : arguments.stack
            }
        );

        if(arguments.trainerid > 0) {
            var trainer = trainerService.getFromId(arguments.trainerid);
            bug.setTrainer(trainer);
        }

        entitySave(bug);
        ormFlush();
        return;
    }

    /**
     * Datatable GET for bug log table
     */
    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = ""
    ) {
        var fromSQL     = "FROM bug LEFT JOIN trainer ON trainer.id = bug.trainerid";
        var whereSQL    = "";
        var whereParams = {};
        if(search.len()) {
            whereSQL           = "WHERE #pagination.searchSQL(["bug.event", "bug.message", "trainer.username"])#";
            whereParams.search = {value: utilService.likeContains(search), cfsqltype: "varchar"};
        }

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
            baseWhere     = "",
            whereSQL      = whereSQL,
            whereParams   = whereParams,
            totalCacheKey = "bug.totalRecords",
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
                {returntype: "array"}
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
