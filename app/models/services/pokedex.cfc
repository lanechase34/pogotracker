component singleton accessors="true" {

    property name="cacheService"      inject="services.cache";
    property name="generationService" inject="services.generation";
    property name="pokemonService"    inject="services.pokemon";

    /**
     * Get registered pokemon for a trainer
     * for a region/mega and whether to include forms
     */
    public array function getRegistered(
        required component trainer,
        string region  = '',
        boolean form   = false,
        boolean mega   = false,
        boolean shadow = false,
        boolean giga   = false
    ) {
        var cacheKey   = '#arguments.trainer.getId()#|pokedex.getRegistered|region=#arguments.region#|form=#arguments.form#|mega=#arguments.mega#|shadow=#arguments.shadow#|giga=#arguments.giga#';
        var registered = cacheService.get(cacheKey);
        if(isNull(registered)) {
            var whereClause = 'WHERE pokemon.mega = :mega AND pokemon.giga = :giga';
            var params      = {
                'trainer': arguments.trainer,
                'mega'   : arguments.mega,
                'giga'   : arguments.giga
            };

            if(arguments.region.len()) {
                whereClause &= ' AND pokemon.generation = :generation';
                params.insert('generation', generationService.getFromRegion(arguments.region));
            }
            if(arguments.form) {
                whereClause &= ' AND pokemon.form = :form';
                params.insert('form', arguments.form);
            }
            if(arguments.shadow) {
                whereClause &= ' AND pokemon.shadow = :shadow';
                params.insert('shadow', arguments.shadow);
            }

            registered = ormExecuteQuery(
                '
                from pokemon as pokemon
                left outer join pokemon.pokedex as pokedex with pokedex.trainer = :trainer
                #whereClause#
                order by pokemon.generation asc, pokemon.number asc, pokemon.form asc, pokemon.name asc
                ',
                params
            );

            cacheService.put(cacheKey, registered, 10, 10);
        }

        return registered;
    }

    /**
     * Register a pokemon for a trainer
     */
    public void function register(
        required component trainer,
        required component pokemon,
        required boolean caught,
        required boolean shiny,
        required boolean hundo,
        required boolean shadow,
        required boolean shadowshiny
    ) {
        var entry = entityLoad(
            'pokedex',
            {'trainer': arguments.trainer, 'pokemon': arguments.pokemon},
            true
        );

        // If we haven't registered this pokemon, create a new record
        if(isNull(entry)) {
            entry = entityNew(
                'pokedex',
                {
                    'trainer'    : arguments.trainer,
                    'pokemon'    : arguments.pokemon,
                    'caught'     : arguments.caught,
                    'shiny'      : arguments.shiny,
                    'hundo'      : arguments.hundo,
                    'shadow'     : arguments.shadow,
                    'shadowshiny': arguments.shadowshiny
                }
            );
        }
        // Update the already registered values
        else {
            entry.setCaught(arguments.caught);
            entry.setShiny(arguments.shiny);
            entry.setHundo(arguments.hundo);
            entry.setShadow(arguments.shadow);
            entry.setShadowShiny(arguments.shadowshiny);
        }

        entitySave(entry);
        ormFlush();

        // Clear trainer's pokedex cache on update
        cacheService.clear(filter = '#arguments.trainer.getId()#|pokedex.getRegistered|region=|'); // shadow dex
        cacheService.clear(
            filter = '#arguments.trainer.getId()#|pokedex.getRegistered|region=#arguments.pokemon.getGeneration().getRegion()#'
        ); // normal dex
        cacheService.clear(filter = '#arguments.trainer.getId()#|pokedex.getCustomRegistered'); // custom dex
        // Clear trainer's pokedex stats cache
        cacheService.remove(key = '#arguments.trainer.getId()#|stats.getPokedexStats');
        // Strings
        cacheService.remove(key = '#arguments.trainer.getId()#|pokedex.getMissingString');
        return;
    }

    /**
     * Registers all pokemon for trainer in a given region
     */
    public void function registerAll(
        required component trainer,
        required string region,
        required boolean shiny
    ) {
        var registered = getRegistered(trainer = arguments.trainer, region = arguments.region);

        // Loop over the pokemon trainer has registered. If not caught/shiny caught, add the entry
        registered.each(
            (entry) => {
                var pokemon = pokemonService.getFromId(pokemonid = entry[1].getId());

                // Check to make sure the shiny is live first
                if(shiny && !pokemon.getShiny()) continue;

                if(
                    isNull(entry[2]) ||
                    (!shiny && !entry[2].getCaught()) ||
                    (shiny && !entry[2].getShiny())
                ) {
                    register(
                        trainer     = trainer,
                        pokemon     = pokemon,
                        caught      = shiny ? (entry[2]?.getCaught() ?: false) : true,
                        shiny       = !shiny ? (entry[2]?.getShiny() ?: false) : true,
                        hundo       = entry[2]?.getHundo() ?: false,
                        shadow      = entry[2]?.getShadow() ?: false,
                        shadowshiny = entry[2]?.getShadowShiny() ?: false
                    );
                }
            },
            true,
            application.cbController.getSetting('maxThreads')
        );

        return;
    }

    /**
     * Get registered pokemon for a trainer under a custom set
     */
    public array function getCustomRegistered(required component trainer, required component custom) {
        var cacheKey         = '#arguments.trainer.getId()#|pokedex.getCustomRegistered|custom=#arguments.custom.getId()#';
        var customRegistered = cacheService.get(cacheKey);
        if(isNull(customRegistered)) {
            customRegistered = ormExecuteQuery(
                '
                from pokemon as pokemon
                left outer join pokemon.pokedex as pokedex with pokedex.trainer = :trainer
                inner join pokemon.custompokedex as custompokedex
                where custompokedex.custom = :custom
                order by pokemon.generation asc, pokemon.number asc, pokemon.form asc, pokemon.name asc
                ',
                {'trainer': arguments.trainer, 'custom': arguments.custom}
            );

            cacheService.put(cacheKey, customRegistered, 10, 10);
        }

        return customRegistered;
    }

    /**
     * Create search string to use in game, uses pokemon numbers
     *
     * @pokedex Array containing pokemon
     * @view    Current pokedex view
     */
    public string function createSearchString(
        required array pokedex,
        required string view,
        boolean unregisteredOnly = false
    ) {
        var string =
        arguments.view == 'shadowshiny' ? 'shadow&shiny&' : arguments.view == 'shadow' ? 'shadow&' : arguments.view == 'shiny' ? 'shiny&' : arguments.view == 'hundo' ? '4*&' : '';

        arguments.pokedex.each((pokemon) => {
            if(
                !unregisteredOnly ||
                (unregisteredOnly && isNull(pokemon[2]))
            ) {
                string &= '#pokemon[1].getNumber()#,';
            }
        });

        return string;
    }

    /**
     * Create string of missing pokemon for the trainer
     *
     * @trainer 
     * @shiny   t/f
     */
    public string function getMissingString(required component trainer, required boolean shiny) {
        var cacheKey       = '#arguments.trainer.getId()#|pokedex.getMissingString';
        var missingStrings = cacheService.get(cacheKey);

        if(isNull(missingStrings)) {
            q = queryExecute(
                '
                select
                    coalesce(string_agg(case when (d.caught is not true and p.live = true) then cast(p.number as text) end, '','' order by p.number asc), '''') as missingCaught,
                    coalesce(string_agg(case when (d.shiny is not true and p.shiny = true) then cast(p.number as text) end, '','' order by p.number asc), '''') as missingShiny
                from pokemon p
                left outer join pokedex d on p.id = d.pokemonid and d.trainerid = :trainerid
                where p.mega = false
                    and p.giga = false
                    and p.number != 201 -- exclude unown
                    and p.tradable = true
            ',
                {trainerid: {value: arguments.trainer.getId(), cfsqltype: 'integer'}}
            );

            missingStrings = {caught: q.missingCaught, shiny: 'shiny&#q.missingShiny#'};

            cacheService.put(cacheKey, missingStrings, 10, 10);
        }

        return arguments.shiny ? missingStrings.shiny : missingStrings.caught;
    }

}
