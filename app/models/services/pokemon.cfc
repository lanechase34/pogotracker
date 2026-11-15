component singleton accessors="true" {

    property name="adminService"  inject="services.admin";
    property name="async"         inject="asyncManager@coldbox";
    property name="auditService"  inject="services.audit";
    property name="cache"         inject="cachebox:appCache";
    property name="moveService"   inject="services.move";
    property name="pagination"    inject="services.pagination";
    property name="templateCache" inject="cachebox:template";
    property name="utilService"   inject="services.util";

    property name="imageExtension" inject="coldbox:setting:imageExtension";
    property name="domain"         inject="coldbox:setting:domain";

    property name="catchModifiersMap" type="struct";
    property name="cpMultiplierMap"   type="struct";
    property name="datatableCols"     type="array";
    property name="levels"            type="array";
    property name="types"             type="array";
    property name="cacheTime"         type="numeric";

    // A pokemon row with its generation's region
    variables.POKEMON_SELECT = "
        SELECT pokemon.id, pokemon.created, pokemon.updated, pokemon.number, pokemon.name, pokemon.gender,
            pokemon.live, pokemon.shiny, pokemon.shadow, pokemon.shadowshiny, pokemon.type1, pokemon.type2,
            pokemon.attack, pokemon.defense, pokemon.hp, pokemon.catch, pokemon.flee, pokemon.form, pokemon.mega,
            pokemon.sprite, pokemon.tradable, pokemon.giga, pokemon.generation, COALESCE(pokemon.ses, '') AS ses,
            COALESCE(pokemon.formtype, '') AS formtype, pokemon.costume, pokemon.costumetype, generation.region
        FROM pokemon
        LEFT JOIN generation ON generation.generation = pokemon.generation
    ";

    // pokemon columns findPokemon() may filter on, and their sql types
    variables.POKEMON_FILTERS = {
        id         : "integer",
        number     : "integer",
        name       : "varchar",
        gender     : "varchar",
        live       : "boolean",
        shiny      : "boolean",
        shadow     : "boolean",
        shadowshiny: "boolean",
        form       : "boolean",
        mega       : "boolean",
        giga       : "boolean",
        tradable   : "boolean",
        costume    : "boolean",
        costumetype: "varchar",
        generation : "decimal",
        ses        : "varchar"
    };

    public void function init() {
        setCatchModifiersMap(deserializeJSON(fileRead("/includes/assets/catchmodifiersmap.json", "UTF-8")));
        setCpMultiplierMap(deserializeJSON(fileRead("/includes/assets/cpmultipliermap.json", "UTF-8")));
        var levels = [];
        for(var i = 1; i <= 50; i++) levels.append(i);
        setLevels(levels);
        setTypes(deserializeJSON(fileRead("/includes/assets/types.json", "UTF-8")).types);

        // Sortable admin datatable columns, by column index
        setDatatableCols([
            "pokemon.generation",
            "pokemon.number",
            "pokemon.gender",
            "pokemon.name",
            "pokemon.costumetype"
        ]);

        setCacheTime(1500); // 25 hours (minutes) - outlives the 24 hour gap between nightly rebuilds
    }

    /**
     * A pokemon row as the app uses it - its columns plus
     * fullname (name with gender), gendertext, ogimage, type1img and type2img
     *
     * @row POKEMON_SELECT row
     */
    private struct function toPokemon(required struct row) {
        var pokemon        = arguments.row;
        pokemon.gendertext = buildGenderText(pokemon.number, pokemon.gender);
        pokemon.fullname   = "#pokemon.name##pokemon.gendertext#";
        pokemon.ogimage    = "#getDomain()#/includes/images/sprites/#pokemon.sprite##getImageExtension()#";
        pokemon.type1img   = "/includes/images/typeicon/#lCase(pokemon.type1)#.webp";
        pokemon.type2img   = "/includes/images/typeicon/#lCase(pokemon.type2)#.webp";
        return pokemon;
    }

    /**
     * " (Male)" / " (Female)" for gendered pokemon - nidorans are their own species, so they get none
     */
    private string function buildGenderText(required numeric number, required string gender) {
        if(arguments.number == 32 || arguments.number == 29) return "";
        if(arguments.gender == "Male") return " (Male)";
        if(arguments.gender == "Female") return " (Female)";
        return "";
    }

    /**
     * Insert a new pokemon and return it
     *
     * @pokemonProperties pokemon columns - generation is its generation number (generation.generation)
     */
    private struct function create(required struct pokemonProperties) {
        var props = arguments.pokemonProperties;
        try {
            var pokemonid = queryExecute(
                "
                INSERT INTO pokemon (
                    number, name, generation, gender, live, shiny, type1, type2, attack, defense, hp, catch, flee,
                    form, mega, sprite, tradable, shadow, shadowshiny, giga, formtype, ses, costume, costumetype
                )
                VALUES (
                    :number, :name, :generation, :gender, :live, :shiny, :type1, :type2, :attack, :defense, :hp, :catch, :flee,
                    :form, :mega, :sprite, :tradable, :shadow, :shadowshiny, :giga, :formtype, :ses, :costume, :costumetype
                )
                RETURNING id
                ",
                {
                    number    : {value: props.number, cfsqltype: "integer"},
                    name      : {value: props.name, cfsqltype: "varchar"},
                    generation: {
                        value    : props.generation,
                        cfsqltype: "decimal",
                        scale    : 1
                    },
                    gender : {value: props.gender, cfsqltype: "varchar"},
                    live   : {value: props.live ? true : false, cfsqltype: "boolean"},
                    shiny  : {value: props.shiny ? true : false, cfsqltype: "boolean"},
                    type1  : {value: props.type1, cfsqltype: "varchar"},
                    type2  : {value: props.type2, cfsqltype: "varchar"},
                    attack : {value: props.attack, cfsqltype: "integer"},
                    defense: {value: props.defense, cfsqltype: "integer"},
                    hp     : {value: props.hp, cfsqltype: "integer"},
                    catch  : {
                        value    : props.catch,
                        cfsqltype: "decimal",
                        scale    : 2
                    },
                    flee: {
                        value    : props.flee,
                        cfsqltype: "decimal",
                        scale    : 2
                    },
                    form       : {value: props.form ? true : false, cfsqltype: "boolean"},
                    mega       : {value: props.mega ? true : false, cfsqltype: "boolean"},
                    sprite     : {value: props.sprite, cfsqltype: "varchar"},
                    tradable   : {value: props.tradable ? true : false, cfsqltype: "boolean"},
                    shadow     : {value: props.shadow ? true : false, cfsqltype: "boolean"},
                    shadowshiny: {value: props.shadowshiny ? true : false, cfsqltype: "boolean"},
                    giga       : {value: props.giga ? true : false, cfsqltype: "boolean"},
                    formtype   : {value: props.formtype, cfsqltype: "varchar"},
                    ses        : {value: props.ses, cfsqltype: "varchar"},
                    costume    : {value: props.costume ? true : false, cfsqltype: "boolean"},
                    costumetype: {value: props.costumetype, cfsqltype: "varchar"}
                }
            ).id;
        }
        catch(any e) {
            // unq_pokemon_ses / unq_pokemon_identity - name the pokemon so the import's bug log says which one
            var constraint = utilService.getUniqueViolation(e);
            if(!constraint.len()) {
                throw(object = e);
            }
            throw(
                type         = "UniqueViolation",
                message      = "Pokemon #props.number# #props.name# (ses #props.ses#) conflicts with an existing pokemon on #constraint#",
                extendedInfo = constraint
            );
        }
        return getFromId(pokemonid);
    }

    public void function upsertPokemon(
        required struct pokemonProperties,
        required array moves,
        required array evolutions
    ) {
        var props = arguments.pokemonProperties;

        // This assumes these properties cannot be changed
        var currPokemon = findPokemon({
            number     : props.number,
            name       : props.name,
            gender     : props.gender,
            costume    : props.costume,
            costumetype: props.costumetype
        });

        // The pokemon, its moves and its evolutions are saved together or not at all
        var created = false;
        transaction {
            // If this is a new pokemon, create
            if(!currPokemon.len()) {
                currPokemon = create(props);
                created     = true;
            }
            // Otherwise, update - only when something changed, so updated (and the sitemap's lastmod) marks a real change
            else {
                currPokemon = currPokemon[1];
                try {
                    queryExecute(
                        "
                        UPDATE pokemon
                        SET live = :live, shiny = :shiny, sprite = :sprite, tradable = :tradable, shadow = :shadow,
                            shadowshiny = :shadowshiny, giga = :giga, formtype = :formtype, ses = :ses
                        WHERE id = :pokemonid
                            AND (live, shiny, sprite, tradable, shadow, shadowshiny, giga, formtype, ses)
                                IS DISTINCT FROM (:live, :shiny, :sprite, :tradable, :shadow, :shadowshiny, :giga, :formtype, :ses)
                        ",
                        {
                            live       : {value: props.live ? true : false, cfsqltype: "boolean"},
                            shiny      : {value: props.shiny ? true : false, cfsqltype: "boolean"},
                            sprite     : {value: props.sprite, cfsqltype: "varchar"},
                            tradable   : {value: props.tradable ? true : false, cfsqltype: "boolean"},
                            shadow     : {value: props.shadow ? true : false, cfsqltype: "boolean"},
                            shadowshiny: {value: props.shadowShiny ? true : false, cfsqltype: "boolean"},
                            giga       : {value: props.giga ? true : false, cfsqltype: "boolean"},
                            formtype   : {value: props.formType, cfsqltype: "varchar"},
                            ses        : {value: props.ses, cfsqltype: "varchar"},
                            pokemonid  : {value: currPokemon.id, cfsqltype: "integer"}
                        }
                    );
                }
                catch(any e) {
                    // A changed ses that collides with another pokemon's
                    utilService.rethrowUniqueViolation(e);
                }
            }

            // Create the pokemon's moves
            moveService.updatePokemonMoves(currPokemon, arguments.moves);

            // Create the evolutions
            createEvolutions(currPokemon, arguments.evolutions);
        }

        // Audit only once the transaction has committed, so a rolled-back create is never recorded
        if(created) {
            auditService.auditSystem(
                event  = "pokemonService.create",
                detail = "Created Pokemon: #props.number# | #props.name# | #props.gender# | #props.costumetype#"
            );
        }
        return;
    }

    /**
     * Get all non-costume pokemon
     */
    public array function getAll() {
        return cache.getOrSet(
            "pokemon.getAll",
            () => findPokemon({"costume": false}, "generation ASC, number ASC, form ASC, name ASC"),
            getCacheTime(),
            getCacheTime()
        );
    }

    /**
     * Pokemon matching every column = value pair, as structs
     *
     * @params  column -> value, columns from POKEMON_FILTERS (generation also takes a generation struct)
     * @order   order by, eg "number ASC, name ASC" - a column without a direction sorts ASC
     * @options maxResults to limit the rows
     */
    public array function findPokemon(
        required struct params,
        string order   = "number ASC",
        struct options = {}
    ) {
        var clauses     = [];
        var queryParams = {};
        arguments.params.each((column, value) => {
            if(!variables.POKEMON_FILTERS.keyExists(column)) {
                throw(type = "pokemonService.InvalidFilter", message = "Can't filter pokemon on #column#");
            }
            if(column == "generation" && isStruct(value)) {
                value = value.generation;
            }
            var sqlType = variables.POKEMON_FILTERS[column];
            clauses.append("pokemon.#column# = :#column#");
            queryParams[column] = {value: sqlType == "boolean" ? (value ? true : false) : value, cfsqltype: sqlType};
            if(sqlType == "decimal") queryParams[column].scale = 1;
        });

        if(!reFindNoCase("^[a-z]+( (asc|desc))?(, *[a-z]+( (asc|desc))?)*$", trim(arguments.order))) {
            throw(type = "pokemonService.InvalidOrder", message = "Invalid pokemon order: #arguments.order#");
        }
        // Every column gets an explicit, uppercase direction - ASC when none was given
        var orderBy = listToArray(arguments.order)
            .map((part) => {
                var words = listToArray(trim(part), " ");
                return "pokemon.#words[1]# #words.len() > 1 ? uCase(words[2]) : "ASC"#";
            })
            .toList(", ");

        var limit = arguments.options.keyExists("maxResults") ? "LIMIT #int(arguments.options.maxResults)#" : "";

        return queryExecute(
            "
            #variables.POKEMON_SELECT#
            #clauses.len() ? "WHERE " & clauses.toList(" AND ") : ""#
            ORDER BY #orderBy#, pokemon.id ASC
            #limit#
            ",
            queryParams,
            {returnType: "array"}
        ).map((row) => toPokemon(row));
    }

    /**
     * One pokemon, null when there is no such pokemon
     *
     * @pokemonid pokemon pk
     */
    public any function getFromId(required numeric pokemonid) {
        var pokemon = findPokemon({id: arguments.pokemonid});
        return utilService.firstRow(pokemon);
    }

    /**
     * The non-costume pokemon with this ses key, null when there is none
     *
     * @ses pokemon SES key
     */
    public any function getFromSes(required string ses) {
        var pokemon = findPokemon({ses: arguments.ses, costume: false});
        return utilService.firstRow(pokemon);
    }

    /**
     * The evolutions out of a pokemon, in the order they were added
     * Each row: id, cost, condition, special, pokemon (the pokemon evolving) and evolution (what it evolves into)
     *
     * @pokemon   pokemon struct
     * @evolution (optional) only the evolution into this pokemon
     */
    public array function getEvolution(required struct pokemon, struct evolution) {
        var whereSQL = "evolution.pokemonid = :pokemonid";
        var params   = {pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}};
        if(!isNull(arguments.evolution)) {
            whereSQL &= " AND evolution.evolutionid = :evolutionid";
            params.evolutionid = {value: arguments.evolution.id, cfsqltype: "integer"};
        }

        var evolutions = queryExecute(
            "
            SELECT id, COALESCE(cost, 0) AS cost, condition, special, pokemonid, evolutionid
            FROM evolution
            WHERE #whereSQL#
            ORDER BY id ASC
            ",
            params,
            {returnType: "array"}
        );
        if(!evolutions.len()) return [];

        // Both ends of every evolution in one query
        var ids  = evolutions.reduce((result, row) => result.append(row.pokemonid).append(row.evolutionid), []);
        var byId = queryExecute(
            "#variables.POKEMON_SELECT# WHERE pokemon.id IN (:ids)",
            {
                ids: {
                    value    : ids.toList(),
                    cfsqltype: "integer",
                    list     : true
                }
            },
            {returnType: "array"}
        ).reduce((result, row) => {
            result[row.id] = toPokemon(row);
            return result;
        }, {});

        return evolutions.map((row) => {
            return {
                id       : row.id,
                cost     : row.cost,
                condition: row.condition,
                special  : row.special,
                pokemon  : byId[row.pokemonid],
                evolution: byId[row.evolutionid]
            };
        });
    }

    /**
     * Create the array of evolutions for the supplied pokemon, in one statement
     * Each evolution's pokemon is matched on its identity (unq_pokemon_identity) - one not created yet is skipped
     * An evolution already there (unq_evolution_pokemonid_evolutionid) is left as is
     * Rows go in the order given, so evolution.id keeps the evolutions' order
     */
    private void function createEvolutions(required struct pokemon, required array evolutions) {
        if(!arguments.evolutions.len()) return;

        var params = {pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}};
        var rows   = [];
        arguments.evolutions.each((evolution, i) => {
            rows.append(
                "(#i#, :number#i#, :name#i#, :gender#i#, :costume#i#, :costumetype#i#, :cost#i#, :condition#i#, :special#i#)"
            );
            params["number#i#"]      = {value: evolution.number, cfsqltype: "integer"};
            params["name#i#"]        = {value: evolution.name, cfsqltype: "varchar"};
            params["gender#i#"]      = {value: evolution.gender, cfsqltype: "varchar"};
            params["costume#i#"]     = {value: (evolution?.costume ?: false) ? true : false, cfsqltype: "boolean"};
            params["costumetype#i#"] = {value: evolution?.costumetype ?: "", cfsqltype: "varchar"};
            params["cost#i#"]        = {
                value    : val(evolution.cost),
                cfsqltype: "integer",
                null     : !len(evolution.cost)
            };
            params["condition#i#"] = {value: evolution.condition, cfsqltype: "varchar"};
            params["special#i#"]   = {value: evolution.special ? true : false, cfsqltype: "boolean"};
        });

        queryExecute(
            "
            INSERT INTO evolution (cost, condition, pokemonid, evolutionid, special)
            SELECT wanted.cost, wanted.condition, :pokemonid, pokemon.id, wanted.special
            FROM (
                VALUES #rows.toList(", ")#
            ) AS wanted (position, number, name, gender, costume, costumetype, cost, condition, special)
            INNER JOIN pokemon
                ON pokemon.number = wanted.number
                AND pokemon.name = wanted.name
                AND pokemon.gender = wanted.gender
                AND pokemon.costume = wanted.costume
                AND pokemon.costumetype = wanted.costumetype
            ORDER BY wanted.position ASC
            ON CONFLICT (pokemonid, evolutionid) DO NOTHING
            ",
            params
        );
    }

    /**
     * Determine the max attack, defense, and hp of all live pokemon
     */
    public struct function getMaxStats() {
        return cache.getOrSet(
            "pokemon.getMaxStats",
            () => {
                var stats = queryExecute(
                    "SELECT MAX(attack) AS attack, MAX(defense) AS defense, MAX(hp) AS hp FROM pokemon WHERE live = true"
                );

                return {
                    attack : stats.attack,
                    defense: stats.defense,
                    hp     : stats.hp,
                    cp     : 7000
                };
            },
            getCacheTime(),
            getCacheTime()
        );
    }

    /**
     * Get the pokemon that evolve into the argument pokemon
     *
     * @pokemon pokemon struct
     */
    public array function getEvolvers(required struct pokemon) {
        return queryExecute(
            "
            #variables.POKEMON_SELECT#
            INNER JOIN evolution ON evolution.pokemonid = pokemon.id
            WHERE evolution.evolutionid = :pokemonid
            ORDER BY evolution.id ASC
            ",
            {pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}},
            {returnType: "array"}
        ).map((row) => toPokemon(row));
    }

    private numeric function calculateCP(
        required struct pokemon,
        required numeric level,
        numeric iv = 15
    ) {
        return floor(
            (
                (pokemon.attack + iv) *
                (sqr(pokemon.defense + iv)) *
                (sqr(pokemon.hp + iv)) *
                (getCpMultiplierMap()[level] ^ 2)
            ) / 10
        );
    }

    private numeric function calculateCatchRate(
        required struct pokemon,
        required numeric level,
        numeric modifier = 1
    ) {
        return 1 - (
            1 -
            (pokemon.catch / (2 * getCpMultiplierMap()[level])) ^ modifier
        );
    }

    /**
     * Get previous events this pokemon and costume types they were featured in 
     *
     * @pokemon pokemon struct
     * @limit   record limit
     */
    public array function getPreviousEvents(
        required struct pokemon,
        numeric limit  = 5,
        numeric offset = 0
    ) {
        var events = queryExecute(
            "
            SELECT custom.id, custom.created, custom.begins, custom.ends, custom.name, custom.link, custom.commday,
                STRING_AGG(pokemon.costumetype, ',' ORDER BY pokemon.id ASC) AS form_list
            FROM custom
            INNER JOIN custompokedex ON custompokedex.customid = custom.id
            INNER JOIN pokemon ON pokemon.id = custompokedex.pokemonid
            WHERE pokemon.name = :name
                AND pokemon.number = :number
                AND pokemon.gender = :gender
                AND (
                    custom.commday = true
                    OR (custom.link IS NOT NULL AND custom.link <> '')
                )
            GROUP BY custom.id, custom.created, custom.begins, custom.ends, custom.name, custom.link,
                pokemon.name, pokemon.number, pokemon.gender
            ORDER BY custom.ends DESC, custom.id DESC
            LIMIT :limit
            OFFSET :offset
            ",
            {
                name  : {value: pokemon.name, cfsqltype: "varchar"},
                number: {value: pokemon.number, cfsqltype: "integer"},
                gender: {value: pokemon.gender, cfsqltype: "varchar"},
                limit : {value: limit, cfsqltype: "integer"},
                offset: {value: offset, cfsqltype: "integer"}
            },
            {returnType: "array"}
        );

        return events.map((row) => {
            return {
                id      : row.id,
                begins  : dateFormat((!isDate(row.begins) ? row.created : row.begins), "mmm d, yyyy"),
                ends    : dateFormat((!isDate(row.ends) ? row.created : row.ends), "mmm d, yyyy"),
                name    : row.name,
                link    : row.link,
                commday : row.commday,
                costumes: listToArray(
                    list               = row.form_list,
                    delimiters         = ",",
                    includeEmptyFields = false
                )
            };
        });
    }

    /**
     * Get the live costume forms of this pokemon
     *
     * @pokemon pokemon struct
     */
    public array function getCostumes(required struct pokemon) {
        return findPokemon(
            {
                costume: true,
                name   : arguments.pokemon.name,
                number : arguments.pokemon.number,
                gender : arguments.pokemon.gender,
                live   : true
            },
            "id ASC"
        );
    }

    /**
     * The pokemon's fast and charge moves in one query, each in the order they were added
     * Each row is the move (moveService.toMove) plus the pokemon's shadow and legacy flags for it
     * A move with no turns is neither fast nor charge, and is left out
     *
     * @pokemon     pokemon struct
     * @pokemonType all, normal (not shadow only), shadow
     *
     * @return {fast: [moves], charge: [moves]}
     */
    public struct function getMovesByKind(required struct pokemon, required string pokemonType) {
        var shadowSQL = "";
        if(arguments.pokemonType == "normal") shadowSQL = "AND pokemonmove.shadow = false";
        if(arguments.pokemonType == "shadow") shadowSQL = "AND pokemonmove.shadow = true";

        return queryExecute(
            "
            SELECT #moveService.getMoveColumns()#, pokemonmove.shadow, pokemonmove.legacy
            FROM pokemonmove
            INNER JOIN move ON move.id = pokemonmove.moveid
            WHERE pokemonmove.pokemonid = :pokemonid
                AND move.turns IS NOT NULL
                #shadowSQL#
            ORDER BY pokemonmove.id ASC
            ",
            {pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}},
            {returnType: "array"}
        ).reduce((result, row) => {
            result[row.turns > 0 ? "fast" : "charge"].append(moveService.toMove(row));
            return result;
        }, {fast: [], charge: []});
    }

    /**
     * Every evolution out of a pokemon and out of what it evolves into, in the order the detail page lists them
     * Each one is followed by the evolutions out of what it evolves into - three stages at most
     *
     * @baseStage pokemon the chain starts from - the first pokemon of the line on the detail page
     */
    public array function buildEvolutionChain(required struct baseStage) {
        var chain = [];
        getEvolution(arguments.baseStage).each((firstStage) => {
            chain.append(firstStage);
            getEvolution(firstStage.evolution).each((secondStage) => {
                chain.append(secondStage);
                chain.append(getEvolution(secondStage.evolution), true);
            });
        });
        return chain;
    }

    /**
     * Get the cached, plain data detail of a pokemon (no objects)
     * Only touches the DB when the cache is cold
     *
     * @ses pokemon SES key
     */
    public struct function getDetailInfo(required string ses) {
        var info = cache.get(getDetailCacheKey(ses));
        if(!isNull(info)) {
            return info;
        }

        var pokemon = getFromSes(ses = ses);
        if(isNull(pokemon)) {
            // Invalid ses
            return {};
        }
        return cacheDetailInfo(pokemon);
    }

    /**
     * Get detail about a pokemon
     *
     * @ses pokemon SES key
     */
    public struct function getDetail(required string ses) {
        var pokemon = getFromSes(ses = ses);
        if(isNull(pokemon)) {
            // Invalid ses
            return {};
        }

        var info = cache.get(getDetailCacheKey(ses)) ?: cacheDetailInfo(pokemon);

        // Get the base stage - stop at a pokemon already walked so cyclic evolution data (A -> B -> A) can't loop forever
        var baseStage = pokemon;
        var visited   = {"#baseStage.id#": true};
        var evolvers  = getEvolvers(baseStage);
        while(evolvers.len() && !visited.keyExists(evolvers[1].id)) {
            baseStage             = evolvers[1];
            visited[baseStage.id] = true;
            evolvers              = getEvolvers(baseStage);
        }

        // Shallow copy so the cached struct is never mutated by a request
        var detail            = structCopy(info);
        detail.pokemon        = pokemon;
        detail.baseStage      = baseStage;
        detail.evolutionChain = buildEvolutionChain(baseStage);
        detail.moves          = getMovesByKind(pokemon, "normal");
        detail.costumes       = getCostumes(pokemon);
        detail.adjacent       = getAdjacent(ses = ses);
        return detail;
    }

    /**
     * Cache suffix for the rendered detail page viewlet
     *
     * @ses     pokemon SES key
     * @isAdmin admins see the update detail form
     */
    public string function getDetailContentCacheSuffix(required string ses, required boolean isAdmin) {
        return "#ses#|#isAdmin ? "admin" : "public"#";
    }

    private string function getDetailCacheKey(required string ses) {
        return "pokemon.getDetail|pokemonses=#ses#";
    }

    /**
     * Unique meta description for a pokemon's detail page using its real numbers
     * ie. Pikachu (#25) in Pokémon GO: max CP 1,048 at level 50, base stats 112 ATK / 96 DEF / 111 HP. Shiny available. ...
     *
     * @pokemon  pokemon struct
     * @fullname pokemon's full name
     * @maxCP    hundo CP at level 50
     */
    private string function buildDetailMetaDescription(
        required struct pokemon,
        required string fullname,
        required numeric maxCP
    ) {
        var availability = [];
        if(pokemon.shiny) availability.append("shiny");
        if(pokemon.shadow) availability.append("shadow");

        var description = "#ucFirst(fullname)# (###pokemon.number#) in Pokémon GO: max CP #numberFormat(maxCP, ",")# at level 50, "
        & "base stats #pokemon.attack# ATK / #pokemon.defense# DEF / #pokemon.hp# HP.";
        if(availability.len()) {
            description &= " #ucFirst(availability.toList(" and "))# available.";
        }
        description &= " Moves, evolutions, and past events.";
        return description;
    }

    /**
     * All live non-costume pokemon grouped by generation for the Pokedex index page
     *
     * @return array of {generation, region, pokemon: [{name, number, ses, sprite, type1, type2}]}
     */
    public array function getIndex() {
        return cache.getOrSet(
            "pokemon.getIndex",
            () => {
                var index  = [];
                var groups = [:];
                getAll().each((pokemon) => {
                    if(!pokemon.live) return;

                    var key = toString(pokemon.generation);
                    if(!groups.keyExists(key)) {
                        groups[key] = {
                            generation: reReplace(key, "\.0+$", ""),
                            region    : pokemon.region,
                            pokemon   : []
                        };
                        index.append(groups[key]);
                    }
                    groups[key].pokemon.append(buildIndexEntry(pokemon));
                });
                return index;
            },
            getCacheTime() * 15,
            getCacheTime() * 15
        );
    }

    /**
     * Every live costume pokemon for the Pokedex index page, linking to its base pokemon's detail page
     *
     * @return array of {name, number, ses, costumeType, sprite, shinySprite, shiny, type1, type2}
     */
    public array function getCostumeIndex() {
        return cache.getOrSet(
            "pokemon.getCostumeIndex",
            () => {
                // Costumes have no detail page of their own - link to the matching base form
                var baseKey = (pokemon) => "#pokemon.name#|#pokemon.number#|#pokemon.gender#";
                var baseSes = getAll().reduce((result, pokemon) => {
                    var key = baseKey(pokemon);
                    if(!result.keyExists(key)) result[key] = pokemon.ses;
                    return result;
                }, {});

                return findPokemon({"costume": true, "live": true}, "number ASC, costumetype ASC")
                    .filter((costume) => baseSes.keyExists(baseKey(costume)))
                    .map((costume) => {
                        var entry         = buildIndexEntry(costume);
                        entry.ses         = baseSes[baseKey(costume)];
                        entry.costumeType = costume.costumetype ?: "";
                        return entry;
                    });
            },
            getCacheTime() * 15,
            getCacheTime() * 15
        );
    }

    /**
     * Previous and next pokemon in Pokedex index order (generation, number, form) for detail page navigation
     *
     * @ses pokemon SES key
     *
     * @return {previous: {name, number, ses, sprite} | {}, next: {...} | {}}
     */
    public struct function getAdjacent(required string ses) {
        var flat = getIndex().reduce((result, group) => result.append(group.pokemon, true), []);

        var position = flat.find((mon) => mon.ses == ses);
        var pick     = (i) => {
            if(position == 0 || i < 1 || i > flat.len()) return {};
            return {
                name  : flat[i].name,
                number: flat[i].number,
                ses   : flat[i].ses,
                sprite: flat[i].sprite
            };
        };
        return {previous: pick(position - 1), next: pick(position + 1)};
    }

    /**
     * Plain data tile for the Pokedex index grid
     */
    private struct function buildIndexEntry(required struct pokemon) {
        return {
            name       : pokemon.fullname,
            number     : pokemon.number,
            ses        : pokemon.ses,
            sprite     : "/includes/images/sprites/#pokemon.sprite##getImageExtension()#",
            shinySprite: "/includes/images/shinysprites/#pokemon.sprite##getImageExtension()#",
            shiny      : pokemon.shiny ? true : false,
            type1      : pokemon.type1,
            type2      : pokemon.type2 ?: ""
        };
    }

    /**
     * Compute and cache the plain data detail of a pokemon
     */
    private struct function cacheDetailInfo(required struct pokemon) {
        var info = {};

        // CP Info | Research(lvl15), egg/raid(lvl20), weather boosted raid(lvl25), max cp(lvl50)
        info.cp = getLevels().reduce((result, level) => {
            result["lvl#level#"] = [
                calculateCP(pokemon, level, 10),
                calculateCP(pokemon, level, 15)
            ];
            return result;
        }, {});

        var maxStats         = getMaxStats();
        info.catchRate       = {lvl20: calculateCatchRate(pokemon, 20)};
        info.statPercentages = {
            attack : (pokemon.attack / maxStats.attack) * 100,
            defense: (pokemon.defense / maxStats.defense) * 100,
            hp     : (pokemon.hp / maxStats.hp) * 100,
            cp     : (info.cp.lvl50[2] / maxStats.cp) * 100
        };
        info.events   = getPreviousEvents(pokemon);
        info.fullname = pokemon.fullname;
        info.number   = pokemon.number;
        // Name first - that's what people search for
        info.title    = "#info.fullname# - Pokémon GO Max CP, Moves & Stats";

        info.metaDescription = buildDetailMetaDescription(
            pokemon  = pokemon,
            fullname = info.fullname,
            maxCP    = info.cp.lvl50[2]
        );
        info.ogImage = pokemon.ogimage;

        cache.set(
            getDetailCacheKey(pokemon.ses),
            info,
            getCacheTime() * 15,
            getCacheTime() * 15
        );
        return info;
    }

    /**
     * Manually update the flags of a pokemon, saves these to env specific config
     */
    public void function updateDetail(
        required struct pokemon,
        required boolean live,
        required boolean shiny,
        required boolean shadow,
        required boolean shinyShadow,
        required boolean tradable
    ) {
        // Update env pokedex overrides, under the same key the nightly build uses, so the toggles survive the rebuild
        // Costumes aren't built from the pokedex scrape - their name key would override the base pokemon instead
        if(!arguments.pokemon.costume) {
            var overrides = adminService.getOverride(name = "envpokedexoverrides");
            var key       = adminService.getOverrideKey(arguments.pokemon);
            if(!overrides.keyExists(key) || !isStruct(overrides[key])) {
                overrides[key] = {};
            }

            overrides[key].live = arguments.live;
            overrides[key].shiny = arguments.shiny;
            overrides[key].shadow = arguments.shadow;
            overrides[key].shadowshiny = arguments.shinyShadow;
            overrides[key].tradable = arguments.tradable;

            adminService.saveOverride(name = "envpokedexoverrides", override = overrides);
        }

        // Update the DB
        queryExecute(
            "
            UPDATE pokemon
            SET live = :live, shiny = :shiny, shadow = :shadow, shadowshiny = :shadowshiny, tradable = :tradable
            WHERE id = :pokemonid
            ",
            {
                live       : {value: arguments.live ? true : false, cfsqltype: "boolean"},
                shiny      : {value: arguments.shiny ? true : false, cfsqltype: "boolean"},
                shadow     : {value: arguments.shadow ? true : false, cfsqltype: "boolean"},
                shadowshiny: {value: arguments.shinyShadow ? true : false, cfsqltype: "boolean"},
                tradable   : {value: arguments.tradable ? true : false, cfsqltype: "boolean"},
                pokemonid  : {value: arguments.pokemon.id, cfsqltype: "integer"}
            }
        );

        // getAll feeds the indexes and builders, live changes max stats and every page's previous/next links
        clearAllCaches();
        return;
    }

    /**
     * Clear every cached pokemon entry and rendered pokemon page
     */
    public void function clearAllCaches() {
        cache.clearByKeySnippet("pokemon.");
        templateCache.clearEvent("pokemon.detailContent");
        templateCache.clearEvent("pokemon.indexContent");
        return;
    }

    /**
     * Clear every pokemon's cached detail info and rendered detail page
     */
    public void function clearAllDetailCaches() {
        cache.clearByKeySnippet("pokemon.getDetail|");
        templateCache.clearEvent("pokemon.detailContent");
        return;
    }

    /**
     * Build array for pokemon search box
     */
    public array function getSearchArray() {
        return cache.getOrSet(
            "pokemon.getSearchArray",
            () => getAll().map((pokemon) => {
                return {
                    id   : pokemon.id,
                    text : "#pokemon.fullname#",
                    image: "#pokemon.sprite##getImageExtension()#",
                    alt  : "Pokemon #pokemon.fullname#",
                    ses  : "#pokemon.ses#"
                };
            }),
            getCacheTime(),
            getCacheTime()
        );
    }

    /**
     * Filter the cached pokemon search array by term with pagination
     *
     * @search   search term
     * @page     current page number
     * @pageSize records per page
     */
    public struct function searchPokemon(
        required string search,
        required numeric page,
        numeric pageSize = 20
    ) {
        var searchLower = lCase(search);
        var filtered    = getSearchArray().filter((item) => {
            return lCase(item.text).find(searchLower) > 0;
        });

        var offset = (page - 1) * pageSize;
        return {
            results   : pagination.slicePage(filtered, offset, pageSize),
            pagination: {more: filtered.len() > offset + pageSize}
        };
    }

    /**
     * Paginated table for pokemon
     */
    public struct function getTable(
        required numeric records,
        required numeric offset,
        required string search    = "",
        required string orderCol1 = "",
        required string orderDir1 = "",
        string orderCol2          = "",
        string orderDir2          = "",
        boolean costume           = false
    ) {
        var fromSQL = "FROM pokemon INNER JOIN generation ON generation.generation = pokemon.generation";
        var filters = pagination.buildFilters(
            searchColumns = [
                "generation.region",
                "pokemon.gender",
                "pokemon.name",
                "pokemon.costumetype"
            ],
            search         = search,
            baseCondition  = "pokemon.costume = :costume",
            baseParams     = {costume: {value: costume, cfsqltype: "boolean"}},
            integerColumns = ["pokemon.number"]
        );

        var orderBy = pagination.orderBy(
            columns = getDatatableCols(),
            orders  = [
                {column: orderCol1, dir: orderDir1},
                {column: orderCol2, dir: orderDir2}
            ],
            defaultSort = "pokemon.generation ASC, pokemon.number ASC",
            tiebreak    = "pokemon.form ASC, pokemon.id ASC"
        );

        var page = pagination.paginate(
            records     = records,
            offset      = offset,
            fromSQL     = fromSQL,
            baseWhere   = filters.baseWhere,
            whereSQL    = filters.whereSQL,
            baseParams  = filters.baseParams,
            whereParams = filters.whereParams,
            fetchRows   = (pageParams) => queryExecute(
                "
                SELECT pokemon.id, pokemon.number, pokemon.gender, pokemon.name, pokemon.costume, COALESCE(pokemon.costumetype, '') AS costumetype,
                    pokemon.sprite, pokemon.shiny, pokemon.shadow, pokemon.shadowshiny, pokemon.ses, generation.region
                #fromSQL#
                #filters.whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returnType: "array"}
            )
        );

        var details = getTableDetails(page.rows.map((row) => row.id));

        return {
            data: page.rows.map((row) => {
                return {
                    pokemonid    : row.id,
                    generation   : row.region,
                    number       : row.number,
                    gender       : row.gender,
                    name         : row.name,
                    costumetype  : row.costumetype,
                    sprite       : "/includes/images/sprites/#row.sprite##getImageExtension()#",
                    shiny        : row.shiny ? "/includes/images/shinysprites/#row.sprite##getImageExtension()#" : "",
                    shadow       : row.shadow,
                    shadowshiny  : row.shadowshiny,
                    fastmoves    : (details.fastMoves[row.id] ?: []).sort("text", "asc").toList("<br>"),
                    chargemoves  : (details.chargeMoves[row.id] ?: []).sort("text", "asc").toList("<br>"),
                    evolutiontext: (details.evolutions[row.id] ?: []).toList(", "),
                    shadowicon   : "/includes/images/shadow-pokemon#getImageExtension()#",
                    ses          : row.costume ? listFirst(row.ses, "-") : row.ses
                };
            }),
            recordsFiltered: page.recordsFiltered,
            recordsTotal   : page.recordsTotal
        };
    }

    /**
     * Move and evolution text for a page of the admin table, two queries for the whole page instead of a lookup per pokemon
     * Move text (name, $ shadow, * legacy) and evolution text (costume type + name) for the table rows
     *
     * @pokemonIds ids on the page
     *
     * @return {fastMoves, chargeMoves, evolutions} - each pokemon id -> array of text
     */
    private struct function getTableDetails(required array pokemonIds) {
        var details = {
            fastMoves  : {},
            chargeMoves: {},
            evolutions : {}
        };
        if(!pokemonIds.len()) {
            return details;
        }

        var ids = {
            value    : pokemonIds.toList(),
            cfsqltype: "integer",
            list     : true
        };
        var results = async
            .all(
                () => queryExecute(
                    "
                    SELECT pokemonmove.pokemonid, move.name, pokemonmove.shadow, pokemonmove.legacy,
                        CASE WHEN move.turns > 0 THEN 'fastMoves' ELSE 'chargeMoves' END AS kind
                    FROM pokemonmove
                    INNER JOIN move ON move.id = pokemonmove.moveid
                    WHERE pokemonmove.pokemonid IN (:ids)
                        AND move.turns IS NOT NULL
                    ",
                    {ids: ids},
                    {returnType: "array"}
                ),
                () => queryExecute(
                    "
                    SELECT evolution.pokemonid, evolved.name, evolved.costume, COALESCE(evolved.costumetype, '') AS costumetype
                    FROM evolution
                    INNER JOIN pokemon AS evolved ON evolved.id = evolution.evolutionid
                    WHERE evolution.pokemonid IN (:ids)
                    ORDER BY evolution.id ASC
                    ",
                    {ids: ids},
                    {returnType: "array"}
                )
            )
            .get();

        results[1].each((move) => {
            var text                           = "#move.name##move.shadow ? "$" : ""##move.legacy ? "*" : ""#";
            details[move.kind][move.pokemonid] = (details[move.kind][move.pokemonid] ?: []).append(text);
        });

        results[2].each((evolution) => {
            var text                                = evolution.costume ? "#evolution.costumetype# #evolution.name#" : evolution.name;
            details.evolutions[evolution.pokemonid] = (details.evolutions[evolution.pokemonid] ?: []).append(text);
        });

        return details;
    }

}
