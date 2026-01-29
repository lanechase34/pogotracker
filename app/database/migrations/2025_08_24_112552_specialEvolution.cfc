component {

    function up(schema, qb) {
        schema.alter('evolution', (table) => {
            table.addColumn(table.boolean('special').default(false));
        });
    }

    function down(schema, qb) {
        schema.alter('evolution', (table) => {
            table.dropColumn('special');
        });
    }

}
