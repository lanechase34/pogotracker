component {

    function up(schema, qb) {
        schema.create('request_log', (table) => {
            // Base
            table.increments('id');
            table.timestampTz('created').withCurrent();
            table.timestampTz('updated').withCurrent();

            // Cols
            table.string('ip', 100);
            table.string('urlpath', 500);
            table.string('method', 10);
            table.string('agent', 250);
            table.text('response');
            table.decimal(name = 'statuscode', length = 3, precision = 0);
            table.integer('delta');

            // FK
            table.unsignedInteger('trainerid').nullable();

            // Index
            table.index('id');
            table.index('created');
        });

        schema.alter('request_log', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });
    }

    function down(schema, qb) {
        schema.drop('request_log');
    }

}
