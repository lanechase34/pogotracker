component singleton accessors="true" {

    property name="cache"             inject="cachebox:appCache";
    property name="generationService" inject="services.generation";
    property name="maxThreads"        inject="coldbox:setting:maxThreads";
    property name="pokemonService"    inject="services.pokemon";
    property name="utilService"       inject="services.util";

    /**
     * Get registered pokemon for a trainer
     * for a region/mega and whether to include forms
     */
    public array function getRegistered(
        required component trainer,
        string region   = "",
        boolean form    = false,
        boolean mega    = false,
        boolean shadow  = false,
        boolean giga    = false,
        boolean costume = false
    ) {
        var cacheKey   = "#arguments.trainer.getId()#|pokedex.getRegistered|region=#arguments.region#|form=#arguments.form#|mega=#arguments.mega#|shadow=#arguments.shadow#|giga=#arguments.giga#|costume=#arguments.costume#";
        var registered = cache.get(cacheKey);
        if(isNull(registered)) {
            var whereClause = "WHERE pokemon.costume = :costume AND pokemon.mega = :mega AND pokemon.giga = :giga";
            var params      = {
                "trainer": arguments.trainer,
                "costume": arguments.costume,
                "mega"   : arguments.mega,
                "giga"   : arguments.giga
            };

            if(arguments.region.len()) {
                whereClause &= " AND pokemon.generation = :generation";
                params.insert("generation", generationService.getFromRegion(arguments.region));
            }
            if(arguments.form) {
                whereClause &= " AND pokemon.form = :form";
                params.insert("form", arguments.form);
            }
            if(arguments.shadow) {
                whereClause &= " AND pokemon.shadow = :shadow";
                params.insert("shadow", arguments.shadow);
            }

            registered = ormExecuteQuery(
                "
                from pokemon as pokemon
                left outer join pokemon.pokedex as pokedex with pokedex.trainer = :trainer
                #whereClause#
                order by pokemon.generation asc, pokemon.number asc, pokemon.costume asc, pokemon.costumetype asc, pokemon.form asc, pokemon.name asc
                ",
                params
            );

            cache.set(cacheKey, registered, 10, 10);
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
            "pokedex",
            {"trainer": arguments.trainer, "pokemon": arguments.pokemon},
            true
        );

        // If we haven't registered this pokemon, create a new record
        if(isNull(entry)) {
            entry = entityNew(
                "pokedex",
                {
                    "trainer"    : arguments.trainer,
                    "pokemon"    : arguments.pokemon,
                    "caught"     : arguments.caught,
                    "shiny"      : arguments.shiny,
                    "hundo"      : arguments.hundo,
                    "shadow"     : arguments.shadow,
                    "shadowshiny": arguments.shadowshiny
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

        clearPokedexCache(trainerid = arguments.trainer.getId(), region = arguments.pokemon.getGeneration().getRegion());
        return;
    }

    /**
     * Registers all pokemon for trainer in a given region
     * Existing entries are flipped with a single UPDATE, missing entries are inserted through ORM with one flush
     * (inserts must go through ORM - ids use hibernate's increment generator, not the db sequence)
     */
    public void function registerAll(
        required component trainer,
        required string region,
        required boolean shiny
    ) {
        var generation = generationService.getFromRegion(arguments.region);
        if(isNull(generation)) return;

        // Column is never user supplied, only one of two literals
        var flag   = arguments.shiny ? "shiny" : "caught";
        var params = {
            trainerid : {value: arguments.trainer.getId(), cfsqltype: "integer"},
            // pokemon.generation references generation.generation (e.g. 3, 2.5), not generation.id
            generation: {
                value    : generation.getGeneration(),
                cfsqltype: "decimal",
                scale    : 1
            }
        };
        // Same set of pokemon as getRegistered(region) - only live shinies when registering shiny
        var eligibleWhere = "
            pokemon.generation = :generation
            AND pokemon.costume = false
            AND pokemon.mega = false
            AND pokemon.giga = false
            #arguments.shiny ? "AND pokemon.shiny = true" : ""#
        ";

        // Existing entries that are not yet caught/shiny
        queryExecute(
            "
            UPDATE pokedex
            SET #flag# = true, updated = now()
            WHERE trainerid = :trainerid
                AND #flag# = false
                AND pokemonid IN (SELECT pokemon.id FROM pokemon WHERE #eligibleWhere#)
            ",
            params
        );

        // Pokemon with no entry yet
        var missing = queryExecute(
            "
            SELECT pokemon.id
            FROM pokemon
            WHERE #eligibleWhere#
                AND NOT EXISTS (
                    SELECT 1 FROM pokedex WHERE pokedex.trainerid = :trainerid AND pokedex.pokemonid = pokemon.id
                )
            ",
            params
        );

        if(missing.recordCount) {
            var pokemonList = ormExecuteQuery("from pokemon where id in (:ids)", {"ids": missing.columnData("id")});
            pokemonList.each((pokemon) => {
                entitySave(
                    entityNew(
                        "pokedex",
                        {
                            "trainer": trainer,
                            "pokemon": pokemon,
                            "caught" : !shiny,
                            "shiny"  : shiny
                        }
                    )
                );
            });
            ormFlush();
        }

        clearPokedexCache(trainerid = arguments.trainer.getId(), region = generation.getRegion());
        return;
    }

    /**
     * Clear every cached view of a trainer's pokedex after a registration
     */
    private void function clearPokedexCache(required numeric trainerid, required string region) {
        cache.clearByKeySnippet("#arguments.trainerid#|pokedex.getRegistered|region=|"); // shadow dex
        cache.clearByKeySnippet("#arguments.trainerid#|pokedex.getRegistered|region=#arguments.region#"); // normal dex
        cache.clearByKeySnippet("#arguments.trainerid#|pokedex.getCustomRegistered"); // custom dex
        // Clear trainer's pokedex stats cache
        cache.clear("#arguments.trainerid#|stats.getPokedexStats");
        // Strings
        cache.clear("#arguments.trainerid#|pokedex.getMissingString");
    }

    /**
     * Get registered pokemon for a trainer under a custom set
     */
    public array function getCustomRegistered(required component trainer, required component custom) {
        var cacheKey         = "#arguments.trainer.getId()#|pokedex.getCustomRegistered|custom=#arguments.custom.getId()#";
        var customRegistered = cache.get(cacheKey);
        if(isNull(customRegistered)) {
            customRegistered = ormExecuteQuery(
                "
                from pokemon as pokemon
                left outer join pokemon.pokedex as pokedex with pokedex.trainer = :trainer
                inner join pokemon.custompokedex as custompokedex
                where custompokedex.custom = :custom
                order by pokemon.generation asc, pokemon.number asc, pokemon.costume asc, pokemon.costumetype asc, pokemon.form asc, pokemon.name asc
                ",
                {"trainer": arguments.trainer, "custom": arguments.custom}
            );

            cache.set(cacheKey, customRegistered, 10, 10);
        }

        return customRegistered;
    }

    /**
     * Create string of missing pokemon for the trainer
     *
     * @trainer trainer cfc
     * @shiny   t/f
     *
     * @return search string to use in pokemon go, uses the pokemon's number/name, with '+' for evolution line
     */
    public string function getMissingString(required component trainer, required boolean shiny) {
        var cacheKey       = "#arguments.trainer.getId()#|pokedex.getMissingString";
        var missingStrings = cache.get(cacheKey);

        if(isNull(missingStrings)) {
            var q = queryExecute(
                "
                select
                    coalesce(string_agg(
                        case when (d.caught is not true and p.live = true)
                        then
                            case when p.form
                            then cast(p.number as text)
                            else '+' || p.name
                            end
                        end
                        , ',' order by p.number asc), ''
                    ) as missingCaught,
                    coalesce(string_agg(
                        case when (d.shiny is not true and p.shiny = true)
                        then
                            case when p.form
                            then cast(p.number as text)
                            else '+' || p.name
                            end
                        end
                        , ',' order by p.number asc), ''
                    ) as missingShiny
                from pokemon p
                left outer join pokedex d on p.id = d.pokemonid and d.trainerid = :trainerid
                where p.costume = false
                    and p.mega = false
                    and p.giga = false
                    and p.number != 201 -- exclude unown
                    and p.tradable = true
            ",
                {trainerid: {value: arguments.trainer.getId(), cfsqltype: "integer"}}
            );

            missingStrings = {
                caught: utilService.removeDuplicates(q.missingCaught),
                shiny : "shiny&#utilService.removeDuplicates(q.missingShiny)#"
            };

            cache.set(cacheKey, missingStrings, 10, 10);
        }

        return arguments.shiny ? missingStrings.shiny : missingStrings.caught;
    }

}
