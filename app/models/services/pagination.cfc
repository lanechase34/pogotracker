component singleton accessors="true" {

    property name="async"       inject="asyncManager@coldbox";
    property name="cache"       inject="cachebox:appCache";
    property name="utilService" inject="services.util";

    property name="ranges" type="struct";

    public void function init() {
        // Time ranges a log table can be limited to - key: {label, unit and amount for dateAdd}
        setRanges([
            "1d": {
                label : "Last 24 hours",
                unit  : "h",
                amount: 24
            },
            "7d": {
                label : "Last 7 days",
                unit  : "d",
                amount: 7
            },
            "30d": {
                label : "Last 30 days",
                unit  : "d",
                amount: 30
            },
            "90d": {
                label : "Last 90 days",
                unit  : "d",
                amount: 90
            },
            "1y": {
                label : "Last year",
                unit  : "yyyy",
                amount: 1
            },
            "all": {label: "All time", unit: "", amount: 0}
        ]);
    }

    /**
     * WHERE clause and params limiting a table to one of getRanges' time ranges
     *
     * @column The timestamp column, e.g. audit.created
     * @range  A key of getRanges
     *
     * @return {where: "WHERE column >= :since" ("" for all time), params: {since} ({} for all time)}
     */
    public struct function rangeFilter(required string column, required string range) {
        var span = getRanges()[range];
        if(!span.amount) {
            return {where: "", params: {}};
        }
        return {
            where : "WHERE #column# >= :since",
            params: {since: {value: dateAdd(span.unit, -span.amount, now()), cfsqltype: "timestamp"}}
        };
    }

    /**
     * Cache key for a range limited table's unfiltered total - all time keeps the plain key
     *
     * @cacheKey The table's total cache key, e.g. audit.totalRecords
     * @range    A key of getRanges
     */
    public string function rangeCacheKey(required string cacheKey, required string range) {
        return range == "all" ? cacheKey : "#cacheKey#.#range#";
    }

    /**
     * Adds a condition to a WHERE clause, starting one if whereSQL is empty
     *
     * @whereSQL  An existing WHERE clause, or ""
     * @condition SQL condition to AND on
     */
    public string function appendWhere(required string whereSQL, required string condition) {
        return whereSQL.len() ? "#whereSQL# AND #condition#" : "WHERE #condition#";
    }

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
            {returnType: "array"}
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
     * WHERE clauses for a datatable, optionally limited to a time range, and filtered by the search text
     * The base clause (range only) counts the unfiltered total, the full clause adds the search
     *
     * @searchColumns  SQL expressions to search (searchSQL)
     * @search         user entered search text, "" for none
     * @dateColumn     timestamp column the range applies to, e.g. audit.created - "" when the table has no range
     * @range          a key of getRanges
     * @baseCondition  condition every row must meet, part of the unfiltered total too, e.g. pokemon.costume = :costume
     * @baseParams     params for baseCondition
     * @integerColumns integer columns the search matches exactly when it is a whole number, e.g. pokemon.number
     *
     * @return {baseWhere, baseParams, whereSQL, whereParams} - ready for paginate
     */
    public struct function buildFilters(
        required array searchColumns,
        required string search,
        string dateColumn    = "",
        string range         = "all",
        string baseCondition = "",
        struct baseParams    = {},
        array integerColumns = []
    ) {
        var rangeOnly = rangeFilter(arguments.dateColumn, arguments.range);
        var baseWhere = rangeOnly.where;
        if(arguments.baseCondition.len()) {
            baseWhere = appendWhere(baseWhere, arguments.baseCondition);
        }
        var mergedBaseParams = duplicate(rangeOnly.params);
        mergedBaseParams.append(arguments.baseParams);

        var filters = {
            baseWhere  : baseWhere,
            baseParams : mergedBaseParams,
            whereSQL   : baseWhere,
            whereParams: duplicate(mergedBaseParams)
        };

        if(arguments.search.len()) {
            var exactColumns           = isValid("integer", arguments.search) ? arguments.integerColumns : [];
            filters.whereSQL           = appendWhere(filters.whereSQL, searchSQL(arguments.searchColumns, exactColumns));
            filters.whereParams.search = {value: utilService.likeContains(arguments.search), cfsqltype: "varchar"};
            if(exactColumns.len()) {
                filters.whereParams.searchNumber = {value: arguments.search, cfsqltype: "integer"};
            }
        }
        return filters;
    }

    /**
     * SQL condition matching :search (from utilService.likeContains) anywhere in any of the columns, ignoring case
     * Integer columns match :searchNumber exactly instead
     *
     * @columns        SQL expressions to search, e.g. ["bug.event", "trainer.username"]
     * @integerColumns integer columns to match against :searchNumber, e.g. ["pokemon.number"]
     */
    public string function searchSQL(required array columns, array integerColumns = []) {
        var matches = columns.map((column) => "#column# ILIKE :search");
        matches.append(integerColumns.map((column) => "#column# = :searchNumber"), true);
        return "(" & matches.toList(" OR ") & ")";
    }

    /**
     * ORDER BY clause from datatables' sort columns - the column index picks its SQL from columns, so only those get into the SQL
     * The handler's constraint limits each column to a sortable index of columns and each dir to asc/desc
     *
     * @columns     SQL expression per datatable column index (0-based) - "" for unsortable columns
     * @orders      [{column, dir}] in priority order, as datatables sends them - blank ones are skipped
     * @defaultSort Used when no order was given, e.g. "pokemon.generation ASC"
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
            .filter((order) => len(order.column) && len(order.dir))
            .map((order) => "#columns[order.column + 1]# #uCase(order.dir)##nulls#");

        if(!sorts.len()) {
            sorts.append(defaultSort);
        }
        if(tiebreak.len() && !sorts.containsNoCase(tiebreak)) {
            sorts.append(tiebreak);
        }

        return "ORDER BY #sorts.toList(", ")#";
    }

    /**
     * LIMIT and OFFSET params for one select2 page - fetches one row past the page so toSelectPage can tell there is another
     *
     * @page     current page, 1-based
     * @pageSize rows per page
     *
     * @return {pageRows, offset} - for LIMIT :pageRows OFFSET :offset
     */
    public struct function selectPageParams(required numeric page, required numeric pageSize) {
        return {
            pageRows: {value: arguments.pageSize + 1, cfsqltype: "integer"},
            offset  : {value: (arguments.page - 1) * arguments.pageSize, cfsqltype: "integer"}
        };
    }

    /**
     * Select2 page from rows fetched with selectPageParams - the extra row past the page means there is another page
     *
     * @rows     up to pageSize + 1 rows, in display order
     * @pageSize rows per page
     * @toOption maps one row to its select2 option
     *
     * @return {results, pagination: {more}}
     */
    public struct function toSelectPage(
        required array rows,
        required numeric pageSize,
        required function toOption
    ) {
        var more = arguments.rows.len() > arguments.pageSize;
        if(more) {
            arguments.rows.deleteAt(arguments.rows.len());
        }
        return {results: arguments.rows.map(arguments.toOption), pagination: {more: more}};
    }

    /**
     * One page of an in-memory list - items offset+1 through offset+pageSize
     *
     * @items    the whole list
     * @offset   items before the page
     * @pageSize items per page
     */
    public array function slicePage(
        required array items,
        required numeric offset,
        required numeric pageSize
    ) {
        if(arguments.offset >= arguments.items.len() || arguments.pageSize <= 0) return [];
        return arguments.items.slice(
            arguments.offset + 1,
            min(arguments.pageSize, arguments.items.len() - arguments.offset)
        );
    }

}
