component singleton accessors="true" {

    property name="trainerCache"      inject="cachebox:trainerCache";
    property name="generationService" inject="services.generation";
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
        var registered = trainerCache.get(cacheKey);
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

            trainerCache.set(cacheKey, registered, 10, 10);
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
        var values = {
            "caught"     : arguments.caught,
            "shiny"      : arguments.shiny,
            "hundo"      : arguments.hundo,
            "shadow"     : arguments.shadow,
            "shadowshiny": arguments.shadowshiny
        };

        var entry = entityLoad(
            "pokedex",
            {"trainer": arguments.trainer, "pokemon": arguments.pokemon},
            true
        );

        // If we haven't registered this pokemon, create a new record
        if(isNull(entry)) {
            var properties        = duplicate(values);
            properties["trainer"] = arguments.trainer;
            properties["pokemon"] = arguments.pokemon;
            entry                 = entityNew("pokedex", properties);
        }
        // Update the already registered values
        else {
            entry.setCaught(values.caught);
            entry.setShiny(values.shiny);
            entry.setHundo(values.hundo);
            entry.setShadow(values.shadow);
            entry.setShadowShiny(values.shadowshiny);
        }

        try {
            entitySave(entry);
            ormFlush();
        }
        catch(any e) {
            if(utilService.getUniqueViolation(e) != "unq_pokedex_trainerid_pokemonid") {
                throw(object = e);
            }

            // Another request (double submit) inserted this entry between our load and insert - the first write stands
            // Hibernate can't continue a session after a failed statement, so it is cleared
            ormClearSession();
            return;
        }

        clearPokedexCache(trainerid = arguments.trainer.getId(), region = arguments.pokemon.getGeneration().getRegion());
        return;
    }

    /**
     * Registers all pokemon for trainer in a given region
     * Existing entries are flipped with a single UPDATE, missing entries are added with a single INSERT ... SELECT
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

        // Pokemon with no entry yet - the other columns take the table defaults, same as the entity defaults
        // ON CONFLICT: unq_pokedex_trainerid_pokemonid already has the row (e.g. a double submit) - leave it be
        var insertParams    = duplicate(params);
        insertParams.caught = {value: !arguments.shiny, cfsqltype: "boolean"};
        insertParams.shiny  = {value: arguments.shiny, cfsqltype: "boolean"};
        queryExecute(
            "
            INSERT INTO pokedex (trainerid, pokemonid, caught, shiny, created, updated)
            SELECT :trainerid, pokemon.id, :caught, :shiny, now(), now()
            FROM pokemon
            WHERE #eligibleWhere#
            ON CONFLICT (trainerid, pokemonid) DO NOTHING
            ",
            insertParams
        );

        clearPokedexCache(trainerid = arguments.trainer.getId(), region = generation.getRegion());
        return;
    }

    /**
     * Clear every cached view of a trainer's pokedex after a registration
     */
    private void function clearPokedexCache(required numeric trainerid, required string region) {
        // Anchored on "<trainerid>|"
        var trainerKey = "^#arguments.trainerid#\|";

        // shadow dex
        trainerCache.clearByKeySnippet(trainerKey & "pokedex\.getRegistered\|region=\|", true);

        // normal dex
        trainerCache.clearByKeySnippet(
            trainerKey & "pokedex\.getRegistered\|region=#utilService.escapeRegex(arguments.region)#\|",
            true
        );

        // custom dex
        trainerCache.clearByKeySnippet(trainerKey & "pokedex\.getCustomRegistered\|", true);

        // Clear trainer's pokedex stats cache
        trainerCache.clear("#arguments.trainerid#|stats.getPokedexStats");

        // Strings
        trainerCache.clear("#arguments.trainerid#|pokedex.getMissingString");
    }

    /**
     * Get registered pokemon for a trainer under a custom set
     */
    public array function getCustomRegistered(required component trainer, required component custom) {
        var cacheKey         = "#arguments.trainer.getId()#|pokedex.getCustomRegistered|custom=#arguments.custom.getId()#";
        var customRegistered = trainerCache.get(cacheKey);
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

            trainerCache.set(cacheKey, customRegistered, 10, 10);
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
        var missingStrings = trainerCache.get(cacheKey);

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

            trainerCache.set(cacheKey, missingStrings, 10, 10);
        }

        return arguments.shiny ? missingStrings.shiny : missingStrings.caught;
    }

}
