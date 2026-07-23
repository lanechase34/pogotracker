component {

    function up(schema, qb) {
        schema.alter('blog', (table) => {
            table.modifyColumn('image', table.string('image', 128));
        });
    }

    function down(schema, qb) {
        schema.alter('blog', (table) => {
            table.modifyColumn('image', table.string('image', 30));
        });
    }

}
