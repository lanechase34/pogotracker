component {

    // Log the entire stacktrace
    function up(schema, qb) {
        schema.alter('bug', (table) => {
            table.modifyColumn('stack', table.text('stack'));
        });
    }

    function down(schema, qb) {
        schema.alter('bug', (table) => {
            table.modifyColumn('stack', table.text('stack'));
        });
    }

}
