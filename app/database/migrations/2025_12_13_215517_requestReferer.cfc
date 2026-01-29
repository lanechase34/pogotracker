component {

    function up(schema, qb) {
        schema.alter('request_log', (table) => {
            table.addColumn(table.string('referer', 250).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter('request_log', (table) => {
            table.dropColumn('referer');
        });
    }

}
