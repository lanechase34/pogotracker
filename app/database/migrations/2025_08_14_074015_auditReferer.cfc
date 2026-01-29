component {

    // Add referer column to audit
    function up(schema, qb) {
        schema.alter('audit', (table) => {
            table.addColumn(table.string('referer', 250).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter('audit', (table) => {
            table.dropColumn('referer');
        });
    }

}
