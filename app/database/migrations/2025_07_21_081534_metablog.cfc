component {

    function up(schema, qb) {
        schema.alter('blog', (table) => {
            table.addColumn(table.string('meta', 150).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter('blog', (table) => {
            table.dropColumn('meta');
        });
    }

}
