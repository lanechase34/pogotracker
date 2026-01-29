component {

    function up(schema, qb) {
        schema.alter('stat', (table) => {
            table.addIndex('created');
            table.addIndex('trainerid');
        });

        schema.alter('pokedex', (table) => {
            table.addIndex('trainerid');
            table.addIndex('pokemonid');
        });

        schema.alter('custompokedex', (table) => {
            table.addIndex('pokemonid');
            table.addIndex('customid');
        });

        schema.alter('trainer', (table) => {
            table.addIndex('username');
        });

        schema.alter('custom', (table) => {
            table.addIndex('name');
        });
    }

    function down(schema, qb) {
        schema.alter('stat', (table) => {
            table.dropIndex(table.index('created'));
            table.dropIndex(table.index('trainerid'));
        });

        schema.alter('pokedex', (table) => {
            table.dropIndex(table.index('trainerid'));
            table.dropIndex(table.index('pokemonid'));
        });

        schema.alter('custompokedex', (table) => {
            table.dropIndex(table.index('pokemonid'));
            table.dropIndex(table.index('customid'));
        });

        schema.alter('trainer', (table) => {
            table.dropIndex(table.index('username'));
        });

        schema.alter('custom', (table) => {
            table.dropIndex(table.index('name'));
        });
    }

}
