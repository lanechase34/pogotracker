component {

    function up(schema, qb) {
        // Add columns to pokemon to specify what exactly the form is
        // And a composite key for ses from number, form, gender / whatever
        schema.alter('pokemon', (table) => {
            table.addColumn(table.string('ses', 150).nullable());
            table.addColumn(table.string('formtype', 50).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter('pokemon', (table) => {
            table.dropColumn('ses');
            table.dropColumn('formtype');
        });
    }

}
