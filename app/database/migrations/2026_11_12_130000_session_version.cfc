component {

    // Add sessionversion to trainer - bumped whenever a trainer's password changes, which signs out
    // every session started before it (interceptors.sessionVersion)
    function up(schema, qb) {
        schema.alter("trainer", (table) => {
            table.addColumn(table.integer("sessionversion").default(0));
        });
    }

    function down(schema, qb) {
        schema.alter("trainer", (table) => {
            table.dropColumn("sessionversion");
        });
    }

}
