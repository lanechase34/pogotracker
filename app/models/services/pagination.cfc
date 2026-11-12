component singleton accessors="true" {

    property name="async" inject="asyncManager@coldbox";
    property name="cache" inject="cachebox:appCache";

    /**
     * How many rows a query matches
     *
     * @fromSQL      FROM clause, with any JOINs the WHERE clause needs
     * @whereSQL     WHERE clause
     * @params       Params struct for fromSQL/whereSQL
     * @countSQL     What's counted - e.g. COUNT(DISTINCT pokemon.id) when the joins repeat rows
     * @cacheKey     Cache the count under this key, and read it from there - only for an unfiltered total. "" to always count
     * @cacheMinutes How long the cached count lasts - "" for appCache's default
     */
    public numeric function countRecords(
        required string fromSQL,
        required string whereSQL,
        required struct params,
        string countSQL     = "COUNT(*)",
        string cacheKey     = "",
        string cacheMinutes = ""
    ) {
        if(len(cacheKey)) {
            var cached = cache.get(cacheKey);
            if(!isNull(cached)) {
                return cached;
            }
        }

        var total = queryExecute(
            "
            SELECT #countSQL# AS total
            #fromSQL#
            #whereSQL#
            ",
            params,
            {returntype: "array"}
        )[1].total;

        if(len(cacheKey)) {
            cache.set(cacheKey, total, cacheMinutes);
        }

        return total;
    }

    /**
     * One datatable page - the unfiltered total, the filtered total, and the page's rows, run in parallel
     * The filtered total is the unfiltered one when no filters were added (whereSQL is baseWhere), and shares its cache
     *
     * @records       Records per page (datatables length)
     * @offset        Rows to skip (datatables start)
     * @fromSQL       FROM clause, with any JOINs the WHERE clauses need
     * @baseWhere     The unfiltered table's WHERE clause
     * @whereSQL      baseWhere plus the filters
     * @fetchRows     Runs the page's query - given whereParams plus records and offset, bound as :records and :offset
     * @baseParams    Params struct for fromSQL/baseWhere
     * @whereParams   Params struct for fromSQL/whereSQL - baseParams plus the filters'
     * @countSQL      What's counted - e.g. COUNT(DISTINCT pokemon.id) when the joins repeat rows
     * @totalCacheKey Cache the unfiltered total under this key - see countRecords. "" to always count
     * @cacheMinutes  How long the cached total lasts - see countRecords
     *
     * @return {recordsTotal, recordsFiltered, rows: what fetchRows returned}
     */
    public struct function paginate(
        required numeric records,
        required numeric offset,
        required string fromSQL,
        required string baseWhere,
        required string whereSQL,
        required function fetchRows,
        struct baseParams    = {},
        struct whereParams   = {},
        string countSQL      = "COUNT(*)",
        string totalCacheKey = "",
        string cacheMinutes  = ""
    ) {
        var hasFilters = whereSQL != baseWhere;

        var pageParams     = duplicate(whereParams);
        pageParams.records = {value: records, cfsqltype: "integer"};
        pageParams.offset  = {value: offset, cfsqltype: "integer"};

        var results = async
            .all(
                () => countRecords(
                    fromSQL      = fromSQL,
                    whereSQL     = baseWhere,
                    params       = baseParams,
                    countSQL     = countSQL,
                    cacheKey     = totalCacheKey,
                    cacheMinutes = cacheMinutes
                ),
                () => {
                    if(!hasFilters) {
                        return -1; // same as the total - not counted twice
                    }
                    return countRecords(
                        fromSQL  = fromSQL,
                        whereSQL = whereSQL,
                        params   = whereParams,
                        countSQL = countSQL
                    );
                },
                () => fetchRows(pageParams)
            )
            .get();

        return {
            recordsTotal   : results[1],
            recordsFiltered: hasFilters ? results[2] : results[1],
            rows           : results[3]
        };
    }

    /**
     * SQL condition matching :search (from utilService.likeContains) anywhere in any of the columns, ignoring case
     *
     * @columns SQL expressions to search, e.g. ["bug.event", "trainer.username"]
     */
    public string function searchSQL(required array columns) {
        return "(" & columns.map((column) => "#column# ILIKE :search").toList(" OR ") & ")";
    }

    /**
     * ORDER BY clause from datatables' sort columns - only whitelisted columns and asc/desc get into the SQL
     *
     * @columns     SQL expression per datatable column index (0-based) - "" for unsortable columns
     * @orders      [{column, dir}] in priority order, as datatables sends them
     * @defaultSort Used when no valid order was given, e.g. "pokemon.generation ASC"
     * @tiebreak    Appended (unless it's already the sort) so paging is stable, e.g. "pokemon.id ASC"
     * @nullsLast   Sort nulls after the values, either direction
     */
    public string function orderBy(
        required array columns,
        required array orders,
        required string defaultSort,
        string tiebreak   = "",
        boolean nullsLast = false
    ) {
        var nulls = nullsLast ? " NULLS LAST" : "";
        var sorts = orders
            .filter((order) => {
                return isNumeric(order.column)
                && order.column >= 0
                && order.column < columns.len()
                && columns[order.column + 1].len()
                && ["asc", "desc"].containsNoCase(order.dir);
            })
            .map((order) => "#columns[order.column + 1]# #uCase(order.dir)##nulls#");

        if(!sorts.len()) {
            sorts.append(defaultSort);
        }
        if(tiebreak.len() && !sorts.containsNoCase(tiebreak)) {
            sorts.append(tiebreak);
        }

        return "ORDER BY #sorts.toList(", ")#";
    }

}
