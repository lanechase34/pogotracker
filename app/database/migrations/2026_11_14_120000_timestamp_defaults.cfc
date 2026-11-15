component {

    /**
     * created/updated insert defaults use the same millisecond clock as the set_updated() trigger
     */
    function up(schema, qb) {
        getTimestampColumns().each((col) => {
            queryExecute(
                "ALTER TABLE ""#col.table_schema#"".""#col.table_name#"" ALTER COLUMN ""#col.column_name#"" SET DEFAULT #getDefault(col.data_type)#"
            );
        });
    }

    /**
     * Back to the plain CURRENT_TIMESTAMP default
     */
    function down(schema, qb) {
        getTimestampColumns().each((col) => {
            queryExecute(
                "ALTER TABLE ""#col.table_schema#"".""#col.table_name#"" ALTER COLUMN ""#col.column_name#"" SET DEFAULT CURRENT_TIMESTAMP"
            );
        });
    }

    /**
     * Every created/updated column on a table in the connection's schema
     */
    private array function getTimestampColumns() {
        return queryExecute(
            "
            SELECT columns.table_schema, columns.table_name, columns.column_name, columns.data_type
            FROM information_schema.columns
            INNER JOIN information_schema.tables
                ON tables.table_schema = columns.table_schema
                AND tables.table_name = columns.table_name
                AND tables.table_type = 'BASE TABLE'
            WHERE columns.table_schema = CURRENT_SCHEMA()
                AND columns.column_name IN ('created', 'updated')
            ORDER BY columns.table_name ASC, columns.column_name ASC
            ",
            {},
            {returnType: "array"}
        );
    }

    /**
     * Millisecond precision now() for the column's type
     */
    private string function getDefault(required string dataType) {
        return arguments.dataType == "timestamp with time zone"
         ? "DATE_TRUNC('milliseconds', CURRENT_TIMESTAMP)"
         : "DATE_TRUNC('milliseconds', LOCALTIMESTAMP)";
    }

}
