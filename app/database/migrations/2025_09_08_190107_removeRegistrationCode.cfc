component {

    function up(schema, qb) {
        schema.alter('trainer', (table) => {
            table.dropColumn('registrationcode');
        });
    }

    function down(schema, qb) {
        schema.alter('trainer', (table) => {
            table.addColumn(table.string('registrationcode', 50).nullable());
        });
    }

}
