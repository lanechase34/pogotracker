component {

    function up(schema, qb) {
        // Create persist table
        schema.create('persist', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('cookie', 128);
            table.string('agent', 512);
            table.timestamp('lastused').withCurrent();
            table.timestamp('lastrotated').withCurrent();

            // FK
            table.unsignedInteger('trainerid');
        });

        // Remove persist cols from trainer
        schema.alter('trainer', (table) => {
            table.dropColumn('persistcookie');
            table.dropColumn('persisteddate');
        });

        // Add FK Constraint
        schema.alter('persist', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        })
    }

    function down(schema, qb) {
        schema.drop('persist');

        schema.alter('trainer', (table) => {
            table.addColumn(table.string('persistcookie', 100).nullable());
            table.addColumn(table.timestamp('persisteddate').nullable());
        });
    }

}
