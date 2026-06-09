component {

    function up(schema, qb) {
        // Add costume pokemon
        schema.alter('pokemon', (table) => {
            table.addColumn(table.boolean('costume').default(false));
            table.addColumn(table.string('costumetype', 150).default(''));
        });
    }

    function down(schema, qb) {
        schema.alter('pokemon', (table) => {
            table.dropColumn('costume');
            table.dropColumn('costumetype');
        });
    }

}
