component {

    // Add settings column to trainer
    function up(schema, qb) {
        schema.alter('trainer', (table) => {
            table.addColumn(table.jsonb('settings').default('''{}'''));
        });
    }

    function down(schema, qb) {
        schema.alter('trainer', (table) => {
            table.dropColumn('settings');
        });
    }

}
