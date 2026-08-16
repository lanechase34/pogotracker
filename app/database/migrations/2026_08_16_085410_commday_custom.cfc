component {

    function up(schema, qb) {
        schema.alter('custom', (table) => {
            table.addColumn(table.boolean('commday').default(false));
        });
    }

    function down(schema, qb) {
        schema.alter('custom', (table) => {
            table.dropColumn('commday');
        });
    }

}
