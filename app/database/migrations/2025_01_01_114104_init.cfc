component {

    function up(schema, qb) {
        schema.create('audit', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('ip', 45);
            table.string('event', 250);
            table.string('agent', 250);
            table.string('detail', 250);

            // FK
            table.unsignedInteger('trainerid').nullable();
        });

        schema.create('blog', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('header', 100);
            table.string('image', 30);
            table.text('bodyjson').nullable();
            table.text('body');
            table.integer('upvote').nullable();

            // FK
            table.unsignedInteger('trainerid').nullable();
        });

        schema.create('bug', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('ip', 128);
            table.string('event', 250);
            table.string('message', 256);
            table.text('stack');

            // FK
            table.unsignedInteger('trainerid').nullable();
        });

        schema.create('comment', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('comment', 1000);

            // FK
            table.unsignedInteger('trainerid');
            table.unsignedInteger('blogid');
        });

        schema.create('custom', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('name', 100);
            table.string('link', 250).nullable();
            table.boolean('public').default(false);
            table.timestamp('begins').nullable();
            table.timestamp('ends').nullable();

            // FK
            table.unsignedInteger('trainerid');
        });

        schema.create('custompokedex', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // FK
            table.unsignedInteger('customid');
            table.unsignedInteger('pokemonid');
        });

        schema.create('evolution', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            // cfformat-ignore-start
            table.integer('cost').nullable().default(0);
            table.string('condition', 75);
            // cfformat-ignore-end

            // Foreign keys
            table.unsignedInteger('pokemonid');
            table.unsignedInteger('evolutionid');
        });

        schema.create('friend', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.boolean('accepted').default(false);

            // Foreign keys
            table.unsignedInteger('trainerid');
            table.unsignedInteger('friendid');
        });

        schema.create('generation', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.decimal(name = 'generation', length = 2, precision = 1).unique();
            table.string('region');
        });

        schema.create('level', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.integer('level').unique();
            table.bigInteger('requiredxp');
        });

        schema.create('medal', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('name', 50);
            table.string('description', 100);
            table.integer('bronze');
            table.integer('silver');
            table.integer('gold');
            table.integer('platinum');
            table.integer('displayorder');
        });

        schema.create('move', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('nameid', 50).unique();
            table.string('name', 50);
            table.string('type', 10);
            table.decimal('damage', 5, 2);
            table.decimal('energy', 5, 2);
            table.decimal('turns', 5, 2);
            table.boolean('buffself').default(false);
            table.decimal('buffchance', 5, 4).default(0);
            table.string('buffeffect', 255).nullable();
        });

        schema.create('pokedex', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.boolean('caught').default(false);
            table.boolean('shiny').default(false);
            table.boolean('hundo').default(false);
            table.boolean('trade').default(true);
            table.boolean('shadow').default(false);
            table.boolean('shadowshiny').default(false);
            table.integer('seen').default(0);
            table.integer('total').default(0);

            // FK
            table.unsignedInteger('trainerid');
            table.unsignedInteger('pokemonid');
        });

        schema.create('pokemon', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.integer('number');
            table.string('name', 50);
            table.string('gender', 10);
            table.boolean('live').default(false);
            table.boolean('shiny').default(false);
            table.boolean('shadow').default(false);
            table.boolean('shadowshiny').default(false);
            table.string('type1', 10);
            table.string('type2', 10).default('');
            table.integer('attack');
            table.integer('defense');
            table.integer('hp');
            table.decimal('catch', 5, 2);
            table.decimal('flee', 5, 2);
            table.boolean('form').default(false);
            table.boolean('mega').default(false);
            table.string('sprite', 50);
            table.boolean('tradable').default(true);
            table.boolean('giga').default(false);

            // FK
            table.decimal(name = 'generation', length = 2, precision = 1)
        });

        schema.create('pokemonmove', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.boolean('shadow').default(false);
            table.boolean('legacy').default(false);

            // FK
            table.unsignedInteger('pokemonid');
            table.unsignedInteger('moveid');
        });

        schema.create('stat', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.integer('caught').default(0);
            table.integer('spun').default(0);
            table.decimal('walked', 10, 2).default(0);
            table.bigInteger('xp').default(0);

            // FK
            table.unsignedInteger('trainerid');
        });

        schema.create('trainer', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.string('username', 30).unique();
            table.string('email', 100).unique();
            table.string('password', 128);
            table.string('salt', 128);
            table.timestamp('lastlogin').nullable();
            table.integer('securitylevel').default(0);
            table.string('registrationcode', 50).nullable();
            table.string('friendcode', 12).unique();
            table.string('icon', 25);
            table.boolean('verified').default(false);
            table.string('verificationcode', 128).nullable();
            table.timestamp('verificationsentdate').nullable();
            table.string('resetcode', 128).nullable();
            table.timestamp('resetsentdate').nullable();
            table.string('persistcookie').nullable();
            table.string('persisteddate').nullable();
        });

        schema.create('trainermedal', (table) => {
            // Base
            table.increments('id');
            table.timestamp('created').withCurrent();
            table.timestamp('updated').withCurrent();

            // Cols
            table.integer('current');

            // FK
            table.unsignedInteger('trainerid');
            table.unsignedInteger('medalid');
        });

        // --- Begin Constraints

        schema.alter('audit', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });

        schema.alter('blog', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });

        schema.alter('bug', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });

        schema.alter('comment', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );

            table.addConstraint(
                table
                    .foreignKey('blogid')
                    .references('id')
                    .onTable('blog')
            );
        });

        schema.alter('custom', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });

        schema.alter('custompokedex', (table) => {
            table.addConstraint(
                table
                    .foreignKey('customid')
                    .references('id')
                    .onTable('custom')
            );

            table.addConstraint(
                table
                    .foreignKey('pokemonid')
                    .references('id')
                    .onTable('pokemon')
            );
        });

        schema.alter('evolution', (table) => {
            table.addConstraint(
                table
                    .foreignKey('pokemonid')
                    .references('id')
                    .onTable('pokemon')
            );

            table.addConstraint(
                table
                    .foreignKey('evolutionid')
                    .references('id')
                    .onTable('pokemon')
            );
        });

        schema.alter('friend', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );

            table.addConstraint(
                table
                    .foreignKey('friendid')
                    .references('id')
                    .onTable('trainer')
            );
        });

        schema.alter('pokedex', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );

            table.addConstraint(
                table
                    .foreignKey('pokemonid')
                    .references('id')
                    .onTable('pokemon')
            );
        });

        schema.alter('pokemon', (table) => {
            table.addConstraint(
                table
                    .foreignKey('generation')
                    .references('generation')
                    .onTable('generation')
            );
        });

        schema.alter('pokemonmove', (table) => {
            table.addConstraint(
                table
                    .foreignKey('pokemonid')
                    .references('id')
                    .onTable('pokemon')
            );

            table.addConstraint(
                table
                    .foreignKey('moveid')
                    .references('id')
                    .onTable('move')
            );
        });

        schema.alter('stat', (table) => {
            table.addConstraint(
                table
                    .foreignKey('trainerid')
                    .references('id')
                    .onTable('trainer')
            );
        });
    }

    function down(schema, qb) {
        schema.drop('audit');
        schema.drop('bug');
        schema.drop('comment');
        schema.drop('blog');
        schema.drop('custompokedex');
        schema.drop('custom');
        schema.drop('evolution');
        schema.drop('friend');
        schema.drop('level');
        schema.drop('pokedex');
        schema.drop('stat');
        schema.drop('pokemonmove');
        schema.drop('move');
        schema.drop('pokemon');
        schema.drop('generation');
        schema.drop('trainermedal');
        schema.drop('medal');
        schema.drop('trainer');
    }

}
