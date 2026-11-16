component {

    /**
     * audit.detail - increase detail size
     */
    function up(schema, qb) {
        queryExecute("ALTER TABLE audit ALTER COLUMN detail TYPE varchar(10000)");
    }

    function down(schema, qb) {
        queryExecute("ALTER TABLE audit ALTER COLUMN detail TYPE varchar(250) USING LEFT(detail, 250)");
    }

}
