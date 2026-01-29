component {

    function up(schema, qb) {
        schema.alter('audit', (table) => {
            table.modifyColumn('event', table.string('event', 250).nullable());
            table.modifyColumn('agent', table.string('agent', 250).nullable());
            table.modifyColumn('detail', table.string('detail', 250).nullable());
        });

        schema.alter('bug', (table) => {
            table.modifycolumn('event', table.string('event', 250).nullable());
        });
    }

    function down(schema, qb) {
    }

}
