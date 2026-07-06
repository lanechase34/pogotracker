component {

    // Create table to store overrides instead of json files
    function up(schema, qb) {
        schema.create('overrides', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('name', 50);
            table.jsonb('override').default('''{}''');
        });
    }

    function down(schema, qb) {
        schema.drop('overrides');
    }

}
