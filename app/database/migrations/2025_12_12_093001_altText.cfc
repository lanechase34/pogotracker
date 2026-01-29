component {

    function up(schema, qb) {
        schema.alter('blog', (table) => {
            table.addColumn(table.string('alttext', 100).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter('blog', (table) => {
            table.dropColumn('alttext');
        });
    }

}
