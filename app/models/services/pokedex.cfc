component singleton accessors="true" {

    property name="trainerCache"      inject="cachebox:trainerCache";
    property name="generationService" inject="services.generation";
    property name="statsService"      inject="services.stats";
    property name="utilService"       inject="services.util";

    // A pokedex grid row: the pokemon's columns, then the trainer's registration of it
    // registered is false (and every dex_ flag false) when the trainer has no entry for the pokemon
    variables.REGISTERED_SELECT = "
        SELECT pokemon.id, pokemon.number, pokemon.name, pokemon.gender, pokemon.form, pokemon.formtype,
            pokemon.live, pokemon.shiny, pokemon.shadow, pokemon.shadowshiny, pokemon.tradable, pokemon.mega,
            pokemon.giga, pokemon.costume, COALESCE(pokemon.costumetype, '') AS costumetype, pokemon.sprite,
            pokemon.generation, pokemon.ses,
            pokedex.id IS NOT NULL AS registered,
            COALESCE(pokedex.caught, false) AS dex_caught,
            COALESCE(pokedex.shiny, false) AS dex_shiny,
            COALESCE(pokedex.hundo, false) AS dex_hundo,
            COALESCE(pokedex.shadow, false) AS dex_shadow,
            COALESCE(pokedex.shadowshiny, false) AS dex_shadowshiny
        FROM pokemon
        LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id AND pokedex.trainerid = :trainerid
    ";
    variables.REGISTERED_ORDER = "
        ORDER BY pokemon.generation ASC, pokemon.number ASC, pokemon.costume ASC, pokemon.costumetype ASC,
            pokemon.form ASC, pokemon.name ASC
    ";

    /**
     * Get registered pokemon for a trainer
     * for a region/mega and whether to include forms
     * Each row is a REGISTERED_SELECT row
     */
    public array function getRegistered(
        required numeric trainerid,
        string region          = "",
        boolean alternateForms = false,
        boolean mega           = false,
        boolean shadow         = false,
        boolean giga           = false,
        boolean costume        = false
    ) {
        // The closure's own arguments scope hides these, so it reads them from here
        var filters = {
            trainerid     : arguments.trainerid,
            region        : arguments.region,
            alternateForms: arguments.alternateForms,
            mega          : arguments.mega,
            shadow        : arguments.shadow,
            giga          : arguments.giga,
            costume       : arguments.costume
        };
        return trainerCache.getOrSet(
            getRegisteredCacheKey(argumentCollection = filters),
            () => {
                var whereClause = "WHERE pokemon.costume = :costume AND pokemon.mega = :mega AND pokemon.giga = :giga";
                var params      = {
                    trainerid: {value: filters.trainerid, cfsqltype: "integer"},
                    costume  : {value: filters.costume, cfsqltype: "boolean"},
                    mega     : {value: filters.mega, cfsqltype: "boolean"},
                    giga     : {value: filters.giga, cfsqltype: "boolean"}
                };

                if(filters.region.len()) {
                    var generation = generationService.getFromRegion(filters.region);
                    whereClause &= " AND pokemon.generation = :generation";
                    params.generation = {
                        value    : isNull(generation) ? -1 : generation.generation,
                        cfsqltype: "decimal",
                        scale    : 1
                    };
                }
                if(filters.alternateForms) {
                    whereClause &= " AND pokemon.form = true";
                }
                if(filters.shadow) {
                    whereClause &= " AND pokemon.shadow = true";
                }

                return queryExecute(
                    "#variables.REGISTERED_SELECT# #whereClause# #variables.REGISTERED_ORDER#",
                    params,
                    {returnType: "array"}
                );
            },
            10,
            10
        );
    }

    /**
     * Register a pokemon for a trainer
     * Only the flags that are passed are written
     */
    public void function register(
        required numeric trainerid,
        required struct pokemon,
        boolean caught,
        boolean shiny,
        boolean hundo,
        boolean shadow,
        boolean shadowshiny
    ) {
        var params = {
            trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
            pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}
        };
        for(
            var flag in [
                "caught",
                "shiny",
                "hundo",
                "shadow",
                "shadowshiny"
            ]
        ) {
            var passed   = !isNull(arguments[flag]);
            params[flag] = {
                value    : passed ? (arguments[flag] ? true : false) : false,
                cfsqltype: "boolean",
                null     : !passed
            };
        }

        var updateSQL = "
            UPDATE pokedex
            SET caught = COALESCE(:caught, caught),
                shiny = COALESCE(:shiny, shiny),
                hundo = COALESCE(:hundo, hundo),
                shadow = COALESCE(:shadow, shadow),
                shadowshiny = COALESCE(:shadowshiny, shadowshiny)
            WHERE trainerid = :trainerid
                AND pokemonid = :pokemonid
            RETURNING id
        ";

        // Update the already registered values
        var written = queryExecute(updateSQL, params);

        // Not registered yet - one row per trainer + pokemon (unq_pokedex_trainerid_pokemonid)
        if(!written.recordCount) {
            written = queryExecute(
                "
                INSERT INTO pokedex (trainerid, pokemonid, caught, shiny, hundo, shadow, shadowshiny)
                VALUES (
                    :trainerid,
                    :pokemonid,
                    COALESCE(:caught, false),
                    COALESCE(:shiny, false),
                    COALESCE(:hundo, false),
                    COALESCE(:shadow, false),
                    COALESCE(:shadowshiny, false)
                )
                ON CONFLICT (trainerid, pokemonid) DO NOTHING
                RETURNING id
                ",
                params
            );

            // Another request inserted the row since the update - apply this request's flags on top
            if(!written.recordCount) {
                written = queryExecute(updateSQL, params);
                if(!written.recordCount) return;
            }
        }

        clearPokedexCache(trainerid = arguments.trainerid, region = arguments.pokemon.region);
        return;
    }

    /**
     * Registers all pokemon for trainer in a given region
     * Existing entries are flipped with a single UPDATE, missing entries are added with a single INSERT ... SELECT
     */
    public void function registerAll(
        required numeric trainerid,
        required string region,
        required boolean shiny
    ) {
        var generation = generationService.getFromRegion(arguments.region);
        if(isNull(generation)) return;

        // Column is never user supplied, only one of two literals
        var flag   = arguments.shiny ? "shiny" : "caught";
        var params = {
            trainerid : {value: arguments.trainerid, cfsqltype: "integer"},
            // pokemon.generation references generation.generation (e.g. 3, 2.5), not generation.id
            generation: {
                value    : generation.generation,
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

        var insertParams    = duplicate(params);
        insertParams.caught = {value: !arguments.shiny, cfsqltype: "boolean"};
        insertParams.shiny  = {value: arguments.shiny, cfsqltype: "boolean"};

        // created/updated come from the table defaults and the set_updated() trigger
        transaction {
            // Existing entries that are not yet caught/shiny
            queryExecute(
                "
                UPDATE pokedex
                SET #flag# = true
                WHERE trainerid = :trainerid
                    AND #flag# = false
                    AND pokemonid IN (SELECT pokemon.id FROM pokemon WHERE #eligibleWhere#)
                ",
                params
            );

            // Pokemon with no entry yet - the other columns take the table defaults
            // ON CONFLICT: unq_pokedex_trainerid_pokemonid already has the row (e.g. a double submit) - leave it be
            queryExecute(
                "
                INSERT INTO pokedex (trainerid, pokemonid, caught, shiny)
                SELECT :trainerid, pokemon.id, :caught, :shiny
                FROM pokemon
                WHERE #eligibleWhere#
                ON CONFLICT (trainerid, pokemonid) DO NOTHING
                ",
                insertParams
            );
        }

        clearPokedexCache(trainerid = arguments.trainerid, region = generation.region);
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
        statsService.clearPokedexStatsCache(arguments.trainerid);

        // Strings
        trainerCache.clear(getMissingStringCacheKey(arguments.trainerid));
    }

    /**
     * Clear every trainer's cached registered list for one custom pokedex
     * Anchored on the end of the key so custom 1 doesn't also clear custom 12, 13...
     *
     * @customid custom pk
     */
    public void function clearCustomRegisteredCache(required numeric customid) {
        trainerCache.clearByKeySnippet("\|pokedex\.getCustomRegistered\|custom=#arguments.customid#$", true);
    }

    /**
     * Get registered pokemon for a trainer under a custom set
     * Each row is a REGISTERED_SELECT row
     */
    public array function getCustomRegistered(required numeric trainerid, required struct custom) {
        var forTrainerid = arguments.trainerid;
        var customid     = arguments.custom.id;
        return trainerCache.getOrSet(
            getCustomRegisteredCacheKey(trainerid = forTrainerid, customid = customid),
            () => queryExecute(
                "
                #variables.REGISTERED_SELECT#
                INNER JOIN custompokedex ON custompokedex.pokemonid = pokemon.id
                WHERE custompokedex.customid = :customid
                #variables.REGISTERED_ORDER#
                ",
                {
                    trainerid: {value: forTrainerid, cfsqltype: "integer"},
                    customid : {value: customid, cfsqltype: "integer"}
                },
                {returnType: "array"}
            ),
            10,
            10
        );
    }

    /**
     * Create string of missing pokemon for the trainer
     *
     * @trainerid trainer pk
     * @shiny     t/f
     *
     * @return search string to use in pokemon go, uses the pokemon's number/name, with '+' for evolution line
     */
    public string function getMissingString(required numeric trainerid, required boolean shiny) {
        var forTrainerid   = arguments.trainerid;
        var missingStrings = trainerCache.getOrSet(
            getMissingStringCacheKey(forTrainerid),
            () => {
                var q = queryExecute(
                    "
                    SELECT
                        COALESCE(STRING_AGG(
                            CASE WHEN (pokedex.caught IS NOT true AND pokemon.live = true)
                            THEN
                                CASE WHEN pokemon.form
                                THEN CAST(pokemon.number AS text)
                                ELSE '+' || pokemon.name
                                END
                            END
                            , ',' ORDER BY pokemon.number ASC), ''
                        ) AS missingCaught,
                        COALESCE(STRING_AGG(
                            CASE WHEN (pokedex.shiny IS NOT true AND pokemon.shiny = true)
                            THEN
                                CASE WHEN pokemon.form
                                THEN CAST(pokemon.number AS text)
                                ELSE '+' || pokemon.name
                                END
                            END
                            , ',' ORDER BY pokemon.number ASC), ''
                        ) AS missingShiny
                    FROM pokemon
                    LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id AND pokedex.trainerid = :trainerid
                    WHERE pokemon.costume = false
                        AND pokemon.mega = false
                        AND pokemon.giga = false
                        AND pokemon.number <> 201 -- exclude unown
                        AND pokemon.tradable = true
                    ",
                    {trainerid: {value: forTrainerid, cfsqltype: "integer"}}
                );

                return {
                    caught: utilService.dedupeList(q.missingCaught),
                    shiny : "shiny&#utilService.dedupeList(q.missingShiny)#"
                };
            },
            10,
            10
        );

        return arguments.shiny ? missingStrings.shiny : missingStrings.caught;
    }

    /**
     * Cache key for the rows getRegistered loads
     *
     * @trainerid      trainer pk
     * @region         region, empty for every region
     * @alternateForms forms only
     * @mega           mega pokemon
     * @shadow         shadow pokemon only
     * @giga           gigantamax pokemon
     * @costume        costume pokemon
     */
    private string function getRegisteredCacheKey(
        required numeric trainerid,
        required string region,
        required boolean alternateForms,
        required boolean mega,
        required boolean shadow,
        required boolean giga,
        required boolean costume
    ) {
        return "#arguments.trainerid#|pokedex.getRegistered|region=#arguments.region#|form=#arguments.alternateForms#|mega=#arguments.mega#|shadow=#arguments.shadow#|giga=#arguments.giga#|costume=#arguments.costume#";
    }

    /**
     * Cache key for the rows getCustomRegistered loads - clearCustomRegisteredCache matches its end
     *
     * @trainerid trainer pk
     * @customid  custom pk
     */
    private string function getCustomRegisteredCacheKey(required numeric trainerid, required numeric customid) {
        return "#arguments.trainerid#|pokedex.getCustomRegistered|custom=#arguments.customid#";
    }

    /**
     * Cache key for the strings getMissingString loads
     *
     * @trainerid trainer pk
     */
    private string function getMissingStringCacheKey(required numeric trainerid) {
        return "#arguments.trainerid#|pokedex.getMissingString";
    }

}
