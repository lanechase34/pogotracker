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

    property name="catchModifiersMap" type="struct";
    property name="cpMultiplierMap"   type="struct";
    property name="datatableCols"     type="array";
    property name="levels"            type="array";
    property name="types"             type="array";
    property name="cacheTime"         type="numeric";

    public void function init() {
        setCatchModifiersMap(deserializeJSON(fileRead("/includes/assets/catchmodifiersmap.json")));
        setCpMultiplierMap(deserializeJSON(fileRead("/includes/assets/cpmultipliermap.json")));
        var levels = [];
        for(var i = 1; i <= 50; i++) levels.append(i);
        setLevels(levels);
        setTypes(deserializeJSON(fileRead("/includes/assets/types.json")).types);

        // Sortable admin datatable columns, by column index
        setDatatableCols([
            "pokemon.generation",
            "pokemon.number",
            "pokemon.gender",
            "pokemon.name",
            "pokemon.costumetype"
        ]);

        setCacheTime(1400); // 23 hours, 20 mins
    }

    private component function create(required struct pokemonProperties) {
        var newPokemon = entityNew("pokemon", arguments.pokemonProperties);
        try {
            entitySave(newPokemon);
            ormFlush();
        }
        catch(any e) {
            // unq_pokemon_ses / unq_pokemon_identity - name the pokemon so the import's bug log says which one
            var constraint = utilService.getUniqueViolation(e);
            if(!constraint.len()) {
                throw(object = e);
            }
            throw(
                type         = "UniqueViolation",
                message      = "Pokemon #arguments.pokemonProperties.number# #arguments.pokemonProperties.name# (ses #arguments.pokemonProperties.ses#) conflicts with an existing pokemon on #constraint#",
                extendedInfo = constraint
            );
        }
        auditService.audit(
            ip      = "localhost",
            event   = "pokemonService.create",
            referer = "",
            detail  = "Created Pokemon: #arguments.pokemonProperties.number# | #arguments.pokemonProperties.name# | #arguments.pokemonProperties.gender# | #arguments.pokemonProperties.costumetype#",
            agent   = ""
        );
        return newPokemon;
    }

    public void function update(
        required struct pokemonProperties,
        required array moves,
        required array evolutions
    ) {
        // This assumes these properties cannot be changed
        var currPokemon = get({
            number     : arguments.pokemonProperties.number,
            name       : arguments.pokemonProperties.name,
            gender     : arguments.pokemonProperties.gender,
            costume    : arguments.pokemonProperties.costume,
            costumetype: arguments.pokemonProperties.costumetype
        });

        // If this is a new pokemon, create
        if(!currPokemon.len()) {
            currPokemon = create(arguments.pokemonProperties);
        }
        // Otherwise, update
        else {
            currPokemon = currPokemon[1];
            currPokemon.setLive(arguments.pokemonProperties.live);
            currPokemon.setShiny(arguments.pokemonProperties.shiny);
            currPokemon.setSprite(arguments.pokemonProperties.sprite);
            currPokemon.setTradable(arguments.pokemonProperties.tradable);
            currPokemon.setShadow(arguments.pokemonProperties.shadow);
            currPokemon.setShadowShiny(arguments.pokemonProperties.shadowShiny);
            currPokemon.setGiga(arguments.pokemonProperties.giga);
            currPokemon.setFormType(arguments.pokemonProperties.formType);
            currPokemon.setSes(arguments.pokemonProperties.ses);
            entitySave(currPokemon);
        }

        // Create the pokemon's moves
        moveService.updatePokemonMoves(currPokemon, arguments.moves);

        // Create the evolutions
        createEvolutions(currPokemon, arguments.evolutions);
        return;
    }

    /**
     * Get all non-costume pokemon
     */
    public array function getAll() {
        var cacheKey   = "pokemon.getAll";
        var allPokemon = cache.get(cacheKey);
        if(isNull(allPokemon)) {
            allPokemon = get({"costume": false}, "generation asc, number asc, form asc, name asc");

            // Make sure relationships are loaded before being cached
            allPokemon.each((pokemon) => {
                pokemon.getMovesText("fast", "all");
                pokemon.getMovesText("charge", "all");
                pokemon.getEvolutionText();
                pokemon.getGeneration().getRegion();
            });

            cache.set(
                cacheKey,
                allPokemon,
                getCacheTime(),
                getCacheTime()
            );
        }
        return allPokemon;
    }

    public array function get(
        required struct params,
        string order   = "number asc",
        struct options = {}
    ) {
        return entityLoad(
            "pokemon",
            arguments.params,
            arguments.order,
            arguments.options
        );
    }

    public component function getFromId(required numeric pokemonid) {
        return entityLoadByPK("pokemon", arguments.pokemonid);
    }

    public any function getFromSes(required string ses) {
        return entityLoad("pokemon", {ses: ses, costume: false}, true);
    }

    public array function getEvolution(required component pokemon, component evolution) {
        var params = {"pokemon": arguments.pokemon};
        if(!isNull(arguments.evolution)) {
            params.insert("evolution", arguments.evolution);
        }
        return entityLoad("evolution", params);
    }

    /**
     * Create the array of evolutions for the supplied pokemon
     */
    private void function createEvolutions(required component pokemon, required array evolutions) {
        evolutions.each((evolution) => {
            // Attempt to load the evolution pokemon trying to be made
            var evolvedPokemon = get({
                "number"     : evolution.number,
                "name"       : evolution.name,
                "gender"     : evolution.gender,
                "costume"    : evolution?.costume ?: false,
                "costumetype": evolution?.costumetype ?: ""
            });

            // have to skip since the evolved pokemon hasn't been created yet
            if(!evolvedPokemon.len()) continue;

            evolvedPokemon = evolvedPokemon[1];

            // See if the evolution has already been created
            if(!getEvolution(pokemon, evolvedPokemon).len()) {
                var newEvolution = entityNew(
                    "evolution",
                    {
                        "cost"     : evolution.cost,
                        "condition": evolution.condition,
                        "pokemon"  : pokemon,
                        "evolution": evolvedPokemon,
                        "special"  : evolution.special
                    }
                );

                entitySave(newEvolution);
                ormFlush();
            }
        });
    }

    /**
     * Determine the max attack, defense, and hp of all live pokemon
     */
    public struct function getMaxStats() {
        var cacheKey = "pokemon.getMaxStats";
        var max      = cache.get(cacheKey);
        if(isNull(max)) {
            var stats = ormExecuteQuery("
                select max(attack), max(defense), max(hp)
                from pokemon
            ")[1];

            max = {
                attack : stats[1],
                defense: stats[2],
                hp     : stats[3],
                cp     : 7000
            };

            cache.set(cacheKey, max, getCacheTime(), getCacheTime());
        }

        return max;
    }

    /**
     * Get the pokemon that evolve into the argument pokemon
     */
    public array function getEvolvers(required component pokemon) {
        return ormExecuteQuery(
            "
            select evolution.pokemon
            from evolution as evolution
            where evolution.evolution = :pokemon
            ",
            {pokemon: arguments.pokemon}
        );
    }

    private numeric function calculateCP(
        required component pokemon,
        required numeric level,
        numeric iv = 15
    ) {
        return floor(
            (
                (pokemon.getAttack() + iv) *
                (sqr(pokemon.getDefense() + iv)) *
                (sqr(pokemon.getHp() + iv)) *
                (getCpMultiplierMap()[level] ^ 2)
            ) / 10
        );
    }

    private numeric function calculateCatchRate(
        required component pokemon,
        required numeric level,
        numeric modifier = 1
    ) {
        return 1 - (
            1 -
            (pokemon.getCatch() / (2 * getCpMultiplierMap()[level])) ^ modifier
        );
    }

    /**
     * Get previous events this pokemon and costume types they were featured in 
     *
     * @pokemon pokemon cfc
     * @limit   record limit
     */
    public array function getPreviousEvents(
        required component pokemon,
        numeric limit  = 5,
        numeric offset = 0
    ) {
        var events = queryExecute(
            "
            SELECT c.id, c.created, c.begins, c.ends, c.name, c.link, c.commday, STRING_AGG(costumetype, ',') AS form_list
            FROM custom c
            JOIN custompokedex cp ON cp.customid = c.id
            JOIN pokemon p ON cp.pokemonid = p.id
            WHERE p.name = :name
            AND p.number = :number
            AND p.gender = :gender
            AND (
                c.commday = true
                OR (c.link IS NOT NULL AND c.link <> '')
            )
            GROUP BY c.id, c.created, c.begins, c.ends, c.name, c.link, p.name, p.number, p.gender
            ORDER BY c.ends DESC
            LIMIT :limit
            OFFSET :offset
            ",
            {
                name  : {value: pokemon.getName(), cfsqltype: "varchar"},
                number: {value: pokemon.getNumber(), cfsqltype: "integer"},
                gender: {value: pokemon.getGender(), cfsqltype: "varchar"},
                limit : {value: limit, cfsqltype: "integer"},
                offset: {value: offset, cfsqltype: "integer"}
            }
        );

        return events.reduce((result, row) => {
            result.append({
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
            });
            return result;
        }, []);
    }

    /**
     * Get the costume forms of this pokemon
     *
     * @pokemon pokemon cfc
     */
    public array function getCostumes(required component pokemon) {
        return ormExecuteQuery(
            "
            select pokemon
            from pokemon as pokemon
            where pokemon.costume = true
            and pokemon.name = :name
            and pokemon.number = :number
            and pokemon.gender = :gender
            and pokemon.live = true
            ",
            {
                name  : pokemon.getName(),
                number: pokemon.getNumber(),
                gender: pokemon.getGender()
            }
        );
    }

    /**
     * Get the cached, plain data detail of a pokemon (no entities)
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

        // Get the base stage
        var baseStage = pokemon;
        var evolvers  = getEvolvers(baseStage);
        while(evolvers.len()) {
            baseStage = evolvers[1];
            evolvers  = getEvolvers(baseStage);
        }

        // Shallow copy so the cached struct is never mutated by a request
        var detail       = structCopy(info);
        detail.pokemon   = pokemon;
        detail.baseStage = baseStage;
        detail.costumes  = getCostumes(pokemon);
        detail.adjacent  = getAdjacent(ses = ses);
        return detail;
    }

    /**
     * Clear every cached piece of a pokemon's detail page
     *
     * @ses pokemon SES key
     */
    public void function clearDetailCache(required string ses) {
        cache.clear(getDetailCacheKey(ses));
        // Rendered detailContent viewlets, keys are lower cased by ColdBox: <prefix>pokemon.detailcontent-<ses>|<audience>-<hash>
        templateCache.clearByKeySnippet("pokemon.detailcontent-#lCase(ses)#|");
        return;
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
     * @pokemon  pokemon orm entity
     * @fullname pokemon's full name
     * @maxCP    hundo CP at level 50
     */
    private string function buildDetailMetaDescription(
        required component pokemon,
        required string fullname,
        required numeric maxCP
    ) {
        var availability = [];
        if(pokemon.getShiny()) availability.append("shiny");
        if(pokemon.getShadow()) availability.append("shadow");

        var description = "#ucFirst(fullname)# (###pokemon.getNumber()#) in Pokémon GO: max CP #numberFormat(maxCP, ",")# at level 50, "
        & "base stats #pokemon.getAttack()# ATK / #pokemon.getDefense()# DEF / #pokemon.getHP()# HP.";
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
        var cacheKey = "pokemon.getIndex";
        var index    = cache.get(cacheKey);
        if(!isNull(index)) {
            return index;
        }

        index      = [];
        var groups = [:];
        getAll().each((pokemon) => {
            if(!pokemon.getLive()) return;

            var generation = pokemon.getGeneration();
            var key        = toString(generation.getGeneration());
            if(!groups.keyExists(key)) {
                groups[key] = {
                    generation: reReplace(key, "\.0+$", ""),
                    region    : generation.getRegion(),
                    pokemon   : []
                };
                index.append(groups[key]);
            }
            groups[key].pokemon.append(buildIndexEntry(pokemon));
        });

        cache.set(
            cacheKey,
            index,
            getCacheTime() * 15,
            getCacheTime() * 15
        );
        return index;
    }

    /**
     * Every live costume pokemon for the Pokedex index page, linking to its base pokemon's detail page
     *
     * @return array of {name, number, ses, costumeType, sprite, shinySprite, shiny, type1, type2}
     */
    public array function getCostumeIndex() {
        var cacheKey = "pokemon.getCostumeIndex";
        var index    = cache.get(cacheKey);
        if(!isNull(index)) {
            return index;
        }

        // Costumes have no detail page of their own - link to the matching base form
        var baseKey = (pokemon) => "#pokemon.getName()#|#pokemon.getNumber()#|#pokemon.getGender()#";
        var baseSes = getAll().reduce((result, pokemon) => {
            var key = baseKey(pokemon);
            if(!result.keyExists(key)) result[key] = pokemon.getSes();
            return result;
        }, {});

        index = get({"costume": true, "live": true}, "number asc, costumetype asc")
            .filter((costume) => baseSes.keyExists(baseKey(costume)))
            .map((costume) => {
                var entry         = buildIndexEntry(costume);
                entry.ses         = baseSes[baseKey(costume)];
                entry.costumeType = costume.getCostumeType() ?: "";
                return entry;
            });

        cache.set(
            cacheKey,
            index,
            getCacheTime() * 15,
            getCacheTime() * 15
        );
        return index;
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
    private struct function buildIndexEntry(required component pokemon) {
        return {
            name       : pokemon.getFullname(),
            number     : pokemon.getNumber(),
            ses        : pokemon.getSes(),
            sprite     : "/includes/images/sprites/#pokemon.getSprite()##getImageExtension()#",
            shinySprite: "/includes/images/shinysprites/#pokemon.getSprite()##getImageExtension()#",
            shiny      : pokemon.getShiny() ? true : false,
            type1      : pokemon.getType1(),
            type2      : pokemon.getType2() ?: ""
        };
    }

    /**
     * Compute and cache the plain data detail of a pokemon
     */
    private struct function cacheDetailInfo(required component pokemon) {
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
            attack : (pokemon.getAttack() / maxStats.attack) * 100,
            defense: (pokemon.getDefense() / maxStats.defense) * 100,
            hp     : (pokemon.getHP() / maxStats.hp) * 100,
            cp     : (info.cp.lvl50[2] / maxStats.cp) * 100
        };
        info.events   = getPreviousEvents(pokemon);
        info.fullname = pokemon.getFullname();
        info.number   = pokemon.getNumber();
        // Name first - that's what people search for
        info.title    = "#info.fullname# - Pokémon GO Max CP, Moves & Stats";

        info.metaDescription = buildDetailMetaDescription(
            pokemon  = pokemon,
            fullname = info.fullname,
            maxCP    = info.cp.lvl50[2]
        );
        info.ogImage = pokemon.getOgImage();

        cache.set(
            getDetailCacheKey(pokemon.getSes()),
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
        required component pokemon,
        required boolean live,
        required boolean shiny,
        required boolean shadow,
        required boolean shinyShadow,
        required boolean tradable
    ) {
        var overrides = adminService.getOverride(name = "envpokedexoverrides");

        // Update env pokedex overrides
        overrides[pokemon.getName()].live = live;
        overrides[pokemon.getName()].shiny = shiny;
        overrides[pokemon.getName()].shadow = shadow;
        overrides[pokemon.getName()].shadowshiny = shinyShadow;
        overrides[pokemon.getName()].tradable = tradable;

        adminService.saveOverride(name = "envpokedexoverrides", override = overrides);

        // Update the DB
        pokemon.setLive(live);
        pokemon.setShiny(shiny);
        pokemon.setShadow(shadow);
        pokemon.setShadowShiny(shinyShadow);
        pokemon.setTradable(tradable);
        entitySave(pokemon);
        ormFlush();

        clearDetailCache(ses = pokemon.getSes());
        // Index tiles show shiny availability and both indexes respect live
        cache.clear("pokemon.getIndex");
        cache.clear("pokemon.getCostumeIndex");
        templateCache.clearEvent("pokemon.indexContent");
        return;
    }

    /**
     * Build array for pokemon search box
     */
    public array function getSearchArray() {
        var cacheKey    = "pokemon.getSearchArray";
        var searchArray = cache.get(cacheKey);
        if(isNull(searchArray)) {
            searchArray = getAll().map((pokemon) => {
                return {
                    id   : pokemon.getId(),
                    text : "#pokemon.getFullname()#",
                    image: "#pokemon.getSprite()##getImageExtension()#",
                    alt  : "Pokemon #pokemon.getFullname()#",
                    ses  : "#pokemon.getSes()#"
                };
            });
            cache.set(
                cacheKey,
                searchArray,
                getCacheTime(),
                getCacheTime()
            );
        }
        return searchArray;
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

        var offset   = (page - 1) * pageSize;
        var rowCount = filtered.len();
        var results  = [];

        // Slice the correct page from the filtered result
        if(rowCount && offset < rowCount) {
            var startPosition = offset + 1; // slice offset is 1-based
            var remaining     = rowCount - offset; // how many elements remaining after startPosition

            var length = min(remaining, pageSize); // clamp the records returned to not go out of bounds
            results    = filtered.slice(startPosition, length);
        }

        return {results: results, pagination: {more: filtered.len() > offset + pageSize}};
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
        var fromSQL    = "FROM pokemon JOIN generation ON generation.generation = pokemon.generation";
        var baseWhere  = "WHERE pokemon.costume = :costume";
        var baseParams = {costume: {value: costume, cfsqltype: "boolean"}};

        var whereSQL    = baseWhere;
        var whereParams = duplicate(baseParams);
        if(search.len()) {
            var matches = [
                "generation.region ILIKE :search",
                "pokemon.gender ILIKE :search",
                "pokemon.name ILIKE :search",
                "pokemon.costumetype ILIKE :search"
            ];
            whereParams.search = {value: utilService.likeContains(search), cfsqltype: "varchar"};

            if(isNumeric(search)) {
                matches.append("pokemon.number = :number");
                whereParams.number = {value: search, cfsqltype: "numeric"};
            }

            whereSQL &= " AND (#matches.toList(" OR ")#)";
        }

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
            baseWhere   = baseWhere,
            whereSQL    = whereSQL,
            baseParams  = baseParams,
            whereParams = whereParams,
            fetchRows   = (pageParams) => queryExecute(
                "
                SELECT pokemon.id, pokemon.number, pokemon.gender, pokemon.name, pokemon.costume, COALESCE(pokemon.costumetype, '') AS costumetype,
                    pokemon.sprite, pokemon.shiny, pokemon.shadow, pokemon.shadowshiny, pokemon.ses, generation.region
                #fromSQL#
                #whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returntype: "array"}
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
     * Move and evolution text for a page of the admin table, two queries for the whole page instead of lazy loads per pokemon
     * Same text as pokemon.getMovesText("fast"/"charge", "all") and pokemon.getEvolutionText()
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
                    JOIN move ON move.id = pokemonmove.moveid
                    WHERE pokemonmove.pokemonid IN (:ids)
                        AND move.turns IS NOT NULL
                    ",
                    {ids: ids},
                    {returntype: "array"}
                ),
                () => queryExecute(
                    "
                    SELECT evolution.pokemonid, evolved.name, evolved.costume, COALESCE(evolved.costumetype, '') AS costumetype
                    FROM evolution
                    JOIN pokemon AS evolved ON evolved.id = evolution.evolutionid
                    WHERE evolution.pokemonid IN (:ids)
                    ORDER BY evolution.id
                    ",
                    {ids: ids},
                    {returntype: "array"}
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
