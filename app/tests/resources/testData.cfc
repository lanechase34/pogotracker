component singleton {

    variables.columnTypes = {};

    variables.sqlTypes = {
        "bigint"                     : "bigint",
        "boolean"                    : "boolean",
        "character varying"          : "varchar",
        "character"                  : "varchar",
        "date"                       : "date",
        "double precision"           : "double",
        "integer"                    : "integer",
        "numeric"                    : "decimal",
        "real"                       : "real",
        "smallint"                   : "smallint",
        "text"                       : "varchar",
        "timestamp without time zone": "timestamp",
        "timestamp with time zone"   : "timestamp"
    };

    /**
     * One row by primary key as a struct, empty struct when there is none
     *
     * @table table name
     * @id    primary key
     */
    public struct function getRowById(required string table, required numeric id) {
        return findRow(arguments.table, {id: arguments.id});
    }

    /**
     * Rows matching every column = value pair in where, as an array of structs
     *
     * @table   table name
     * @where   column -> value, all must match (a null value matches is null)
     * @orderBy order by clause, eg "id ASC"
     * @maxRows max rows to return, -1 for all
     */
    public array function findRows(
        required string table,
        struct where    = {},
        string orderBy  = "",
        numeric maxRows = -1
    ) {
        var params = {};
        var sql    = "SELECT * FROM #checkName(arguments.table)##whereClause(arguments.table, arguments.where, params)#";
        if(arguments.orderBy.len()) {
            if(!reFindNoCase("^[a-z0-9_]+( (asc|desc))?(, *[a-z0-9_]+( (asc|desc))?)*$", arguments.orderBy)) {
                throw(type = "testData.InvalidOrderBy", message = "Invalid order by: #arguments.orderBy#");
            }
            sql &= " ORDER BY #arguments.orderBy#";
        }
        if(arguments.maxRows > 0) {
            sql &= " LIMIT #int(arguments.maxRows)#";
        }
        return queryExecute(sql, params, {returnType: "array"});
    }

    /**
     * First row matching where as a struct, empty struct when there is none
     *
     * @table   table name
     * @where   column -> value, all must match
     * @orderBy order by clause, eg "id ASC"
     */
    public struct function findRow(
        required string table,
        struct where   = {},
        string orderBy = ""
    ) {
        var rows = findRows(
            table   = arguments.table,
            where   = arguments.where,
            orderBy = arguments.orderBy,
            maxRows = 1
        );
        return rows.len() ? rows[1] : {};
    }

    /**
     * Number of rows matching where
     *
     * @table table name
     * @where column -> value, all must match
     */
    public numeric function countRows(required string table, struct where = {}) {
        var params = {};
        return queryExecute(
            "SELECT COUNT(*) AS total FROM #checkName(arguments.table)##whereClause(arguments.table, arguments.where, params)#",
            params
        ).total;
    }

    /**
     * Insert a row and return its new id
     * Leave out created/updated and the database stamps them (column defaults)
     *
     * @table table name
     * @data  column -> value
     */
    public numeric function insertRow(required string table, required struct data) {
        var params  = {};
        var columns = [];
        var holders = [];
        for(var column in arguments.data) {
            columns.append(checkName(column));
            holders.append(":#column#");
            params[column] = sqlParam(
                arguments.table,
                column,
                arguments.data[column] ?: javacast("null", "")
            );
        }

        var sql = columns.len()
         ? "INSERT INTO #checkName(arguments.table)# (#columns.toList(", ")#) VALUES (#holders.toList(", ")#) RETURNING id"
         : "INSERT INTO #checkName(arguments.table)# DEFAULT VALUES RETURNING id";
        return queryExecute(sql, params).id;
    }

    /**
     * Update a row by primary key
     * Leave out updated and the database stamps it (set_updated trigger)
     *
     * @table table name
     * @id    primary key
     * @data  column -> value, at least one
     */
    public void function updateRow(
        required string table,
        required numeric id,
        required struct data
    ) {
        var params = {"__id": {value: arguments.id, cfsqltype: "integer"}};
        var sets   = [];
        for(var column in arguments.data) {
            sets.append("#checkName(column)# = :#column#");
            params[column] = sqlParam(
                arguments.table,
                column,
                arguments.data[column] ?: javacast("null", "")
            );
        }

        queryExecute("UPDATE #checkName(arguments.table)# SET #sets.toList(", ")# WHERE id = :__id", params);
        return;
    }

    /**
     * Delete rows matching where - refuses an empty where so a table is never wiped by mistake
     *
     * @table table name
     * @where column -> value, all must match
     */
    public void function deleteRows(required string table, required struct where) {
        if(arguments.where.isEmpty()) {
            throw(type = "testData.UnsafeDelete", message = "Refusing to delete from #arguments.table# without a where");
        }
        var params = {};
        queryExecute(
            "DELETE FROM #checkName(arguments.table)##whereClause(arguments.table, arguments.where, params)#",
            params
        );
        return;
    }

    /**
     * Build " WHERE a = :w_a AND b IS NULL" for the where struct, filling params
     */
    private string function whereClause(
        required string table,
        required struct where,
        required struct params
    ) {
        var clauses = [];
        for(var column in arguments.where) {
            if(isNull(arguments.where[column])) {
                clauses.append("#checkName(column)# IS NULL");
            }
            else {
                clauses.append("#checkName(column)# = :w_#column#");
                arguments.params["w_#column#"] = sqlParam(arguments.table, column, arguments.where[column]);
            }
        }
        return clauses.len() ? " WHERE #clauses.toList(" AND ")#" : "";
    }

    /**
     * Typed query param for a column, using the column's type from the database
     */
    private struct function sqlParam(
        required string table,
        required string column,
        any value
    ) {
        var types = getColumnTypes(arguments.table);
        if(!types.keyExists(arguments.column)) {
            throw(type = "testData.UnknownColumn", message = "#arguments.table# has no column #arguments.column#");
        }
        var queryParam = duplicate(types[arguments.column]);
        if(isNull(arguments.value)) {
            queryParam.value = "";
            queryParam.null  = true;
        }
        else {
            queryParam.value = arguments.value;
        }
        return queryParam;
    }

    /**
     * column -> {cfsqltype, scale for numeric columns} for a table, read from information_schema once
     */
    private struct function getColumnTypes(required string table) {
        var tableName = lCase(checkName(arguments.table));
        if(!variables.columnTypes.keyExists(tableName)) {
            var columns = queryExecute(
                "
                SELECT column_name, data_type, numeric_scale
                FROM information_schema.columns
                WHERE table_schema = CURRENT_SCHEMA()
                    AND table_name = :tableName
                ",
                {tableName: {value: tableName, cfsqltype: "varchar"}}
            );
            if(!columns.recordCount) {
                throw(type = "testData.UnknownTable", message = "No table named #tableName#");
            }
            var types = {};
            for(var col in columns) {
                types[col.column_name] = {cfsqltype: variables.sqlTypes[col.data_type] ?: "other"};
                // numeric(p, s) binds as decimal with the column's scale, so the value isn't rounded to a whole number
                if(col.data_type == "numeric") {
                    types[col.column_name].scale = val(col.numeric_scale);
                }
            }
            variables.columnTypes[tableName] = types;
        }
        return variables.columnTypes[tableName];
    }

    /**
     * Table and column names go into the sql directly - only allow plain identifiers
     */
    private string function checkName(required string name) {
        if(!reFindNoCase("^[a-z_][a-z0-9_]*$", arguments.name)) {
            throw(type = "testData.InvalidName", message = "Invalid table or column name: #arguments.name#");
        }
        return arguments.name;
    }

}
