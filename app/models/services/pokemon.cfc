component singleton accessors="true" {

    property name="adminService" inject="services.admin";
    property name="async"        inject="asyncManager@coldbox";
    property name="auditService" inject="services.audit";
    property name="cache"        inject="cachebox:appCache";
    property name="moveService"  inject="services.move";

    property name="maxThreads"     inject="coldbox:setting:maxThreads";
    property name="rootPath"       inject="coldbox:setting:rootPath";
    property name="imageExtension" inject="coldbox:setting:imageExtension";

    property name="catchModifiersMap" type="struct";
    property name="cpMultiplierMap"   type="struct";
    property name="datatableCols"     type="array";
    property name="levels"            type="array";
    property name="types"             type="array";
    property name="cacheTime"         type="numeric";

    public void function init() {
        setCatchModifiersMap(deserializeJSON(fileRead('/includes/assets/catchmodifiersmap.json')));
        setCpMultiplierMap(deserializeJSON(fileRead('/includes/assets/cpmultipliermap.json')));
        var levels = [];
        for(var i = 1; i <= 50; i++) levels.append(i);
        setLevels(levels);
        setTypes(deserializeJSON(fileRead('/includes/assets/types.json')).types);

        setDatatableCols([
            'pokemon.generation',
            'pokemon.number',
            'pokemon.gender',
            'pokemon.name',
            'pokemon.costumetype',
            '',
            '',
            '',
            '',
            '',
            '',
            ''
        ]);

        setCacheTime(1400); // 23 hours, 20 mins
    }

    private component function create(required struct pokemonProperties) {
        var newPokemon = entityNew('pokemon', arguments.pokemonProperties);
        entitySave(newPokemon);
        ormFlush();
        auditService.audit(
            ip      = 'localhost',
            event   = 'pokemonService.create',
            referer = '',
            detail  = 'Created Pokemon: #arguments.pokemonProperties.number# | #arguments.pokemonProperties.name# | #arguments.pokemonProperties.gender# | #arguments.pokemonProperties.costumetype#',
            agent   = ''
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
        var cacheKey   = 'pokemon.getAll';
        var allPokemon = cache.get(cacheKey);
        if(isNull(allPokemon)) {
            allPokemon = get({'costume': false}, 'generation asc, number asc, form asc');

            // Make sure relationships are loaded before being cached
            allPokemon.each((pokemon) => {
                pokemon.getMovesText('fast', 'all');
                pokemon.getMovesText('charge', 'all');
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
        string order   = 'number asc',
        struct options = {}
    ) {
        return entityLoad(
            'pokemon',
            arguments.params,
            arguments.order,
            arguments.options
        );
    }

    public component function getFromId(required numeric pokemonid) {
        return entityLoadByPK('pokemon', arguments.pokemonid);
    }

    public any function getFromSes(required string ses) {
        return entityLoad('pokemon', {ses: ses, costume: false}, true);
    }

    public array function getEvolution(required component pokemon, component evolution) {
        var params = {'pokemon': arguments.pokemon};
        if(!isNull(arguments.evolution)) {
            params.insert('evolution', arguments.evolution);
        }
        return entityLoad('evolution', params);
    }

    /**
     * Create the array of evolutions for the supplied pokemon
     */
    private void function createEvolutions(required component pokemon, required array evolutions) {
        evolutions.each((evolution) => {
            // Attempt to load the evolution pokemon trying to be made
            var evolvedPokemon = get({
                'number'     : evolution.number,
                'name'       : evolution.name,
                'gender'     : evolution.gender,
                'costume'    : evolution?.costume ?: false,
                'costumetype': evolution?.costumetype ?: ''
            });

            // have to skip since the evolved pokemon hasn't been created yet
            if(!evolvedPokemon.len()) continue;

            evolvedPokemon = evolvedPokemon[1];

            // See if the evolution has already been created
            if(!getEvolution(pokemon, evolvedPokemon).len()) {
                var newEvolution = entityNew(
                    'evolution',
                    {
                        'cost'     : evolution.cost,
                        'condition': evolution.condition,
                        'pokemon'  : pokemon,
                        'evolution': evolvedPokemon,
                        'special'  : evolution.special
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
        var cacheKey = 'pokemon.getMaxStats';
        var max      = cache.get(cacheKey);
        if(isNull(max)) {
            var stats = ormExecuteQuery('
                select max(attack), max(defense), max(hp)
                from pokemon
            ')[1];

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
            '
            select evolution.pokemon
            from evolution as evolution
            where evolution.evolution = :pokemon
            ',
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
     * Get previous events this pokemon was featured in
     *
     * @pokemon pokemon cfc
     * @limit   record limit
     */
    public array function getPreviousEvents(
        required component pokemon,
        numeric limit  = 5,
        numeric offset = 0
    ) {
        var events = ormExecuteQuery(
            '
            select custom
            from custom as custom
            left outer join custom.custompokedex as custompokedex
            where custompokedex.pokemon = :pokemon
            and custom.link is not null
            and custom.link <> ''''
            order by custom.id desc
            ',
            {pokemon: arguments.pokemon},
            {maxResults: arguments.limit, offset: arguments.offset}
        );

        return events.map((event) => {
            return {
                id    : event.getId(),
                begins: event.getFormattedBegins(),
                ends  : event.getFormattedEnds(),
                name  : event.getName(),
                link  : event.getLink()
            };
        });
    }

    /**
     * Get the costume forms of this pokemon
     *
     * @pokemon 
     */
    public array function getCostumes(required component pokemon) {
        return ormExecuteQuery(
            '
            select pokemon
            from pokemon as pokemon
            where pokemon.costume = true
            and pokemon.name = :name
            and pokemon.number = :number
            and pokemon.gender = :gender
            ',
            {
                name  : pokemon.getName(),
                number: pokemon.getNumber(),
                gender: pokemon.getGender()
            }
        );
    }

    /**
     * Get detail about a pokemon
     */
    public struct function getDetail(required string ses) {
        // Check cache first
        var cacheKey = 'pokemon.getDetail|pokemonses=#ses#';
        var detail   = cache.get(cacheKey);
        if(isNull(detail)) {
            /**
             * Attempt to load pokemon based on ses
             */
            var pokemon = getFromSes(ses = ses);
            if(isNull(pokemon)) {
                // Invalid ses
                return {};
            }

            detail         = {};
            detail.pokemon = pokemon;
            // CP Info | Research(lvl15), egg/raid(lvl20), weather boosted raid(lvl25), max cp(lvl50)
            var info       = async
                .newFuture()
                .all(
                    () => {
                        var cpInfo = {};
                        getLevels().each(
                            (level) => {
                                cpInfo['lvl#level#'] = [
                                    calculateCP(detail.pokemon, level, 10),
                                    calculateCP(detail.pokemon, level, 15)
                                ];
                            },
                            true,
                            50
                        );
                        return cpInfo;
                    },
                    () => {
                        return getMaxStats();
                    },
                    () => {
                        return calculateCatchRate(detail.pokemon, 20);
                    },
                    () => {
                        // Get the base stage
                        var baseStage = detail.pokemon;
                        while(getEvolvers(baseStage).len()) {
                            baseStage = getEvolvers(baseStage)[1];
                        }
                        return baseStage;
                    },
                    () => {
                        return getPreviousEvents(detail.pokemon);
                    },
                    () => {
                        return getCostumes(detail.pokemon);
                    }
                )
                .get();

            var maxStats           = info[2];
            detail.cp              = info[1];
            detail.catchRates      = {};
            detail.catchRate.lvl20 = info[3];
            detail.statPercentages = {
                attack : (detail.pokemon.getAttack() / maxStats.attack) * 100,
                defense: (detail.pokemon.getDefense() / maxStats.defense) * 100,
                hp     : (detail.pokemon.getHP() / maxStats.hp) * 100,
                cp     : (detail.cp.lvl50[2] / maxStats.cp) * 100
            };
            detail.baseStage = entityMerge(info[4]);
            detail.events    = info[5];
            detail.costumes  = info[6];
            detail.fullname  = '#detail.pokemon.getFullname()#';
            detail.title     = '#detail.pokemon.getNumber()# - #detail.fullname#';

            detail.metaDescription = '#ucFirst(detail.fullname)#''s (###detail.pokemon.getNumber()#) evolutions, CP range, stats, moveset, and events in Pokemon GO.';
            detail.ogImage         = detail.pokemon.getOgImage();

            cache.set(
                cacheKey,
                detail,
                getCacheTime() * 15,
                getCacheTime() * 15
            );
        }
        return detail;
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
        var overrides = adminService.getOverride(name = 'envpokedexoverrides');

        // Update env pokedex overrides
        overrides[pokemon.getName()] = {
            live       : live,
            shiny      : shiny,
            shadow     : shadow,
            shadowshiny: shinyShadow,
            tradable   : tradable
        };

        adminService.saveOverride(name = 'envpokedexoverrides', override = overrides);

        // Update the DB
        pokemon.setLive(live);
        pokemon.setShiny(shiny);
        pokemon.setShadow(shadow);
        pokemon.setShadowShiny(shinyShadow);
        pokemon.setTradable(tradable);
        entitySave(pokemon);
        ormFlush();

        cache.clear('pokemon.getDetail|pokemonses=#pokemon.getSes()#');
        return;
    }

    /**
     * Build array for pokemon search box
     */
    public array function getSearchArray() {
        var cacheKey    = 'pokemon.getSearchArray';
        var searchArray = cache.get(cacheKey);
        if(isNull(searchArray)) {
            searchArray = getAll().map((pokemon) => {
                return {
                    id   : pokemon.getId(),
                    text : '#pokemon.getFullname()#',
                    image: '#pokemon.getSprite()##getImageExtension()#',
                    alt  : 'Pokemon #pokemon.getFullname()#',
                    ses  : '#pokemon.getSes()#'
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
        required string search    = '',
        required string orderCol1 = '',
        required string orderDir1 = '',
        string orderCol2          = '',
        string orderDir2          = '',
        boolean costume           = false
    ) {
        var params = {search: '%#uCase(search)#%', costume: costume};

        // Default order by
        var orderBy = '';
        if(orderCol1.len() && orderDir1.len()) {
            orderBy = 'order by #getDatatableCols()[orderCol1 + 1]# #orderDir1#';
        }
        if(orderCol2.len() && orderDir2.len()) {
            orderBy &= ', #getDatatableCols()[orderCol2 + 1]# #orderDir2#';
        }
        if(!orderBy.len()) {
            orderBy = 'order by generation asc, number asc';
        }
        else {
            orderBy &= ', pokemon.form asc';
        }

        var numericSearch = '';
        if(isNumeric(search)) {
            numericSearch = 'or pokemon.number = :numericSearch';
            params.insert('numericSearch', search);
        }

        var results = async
            .all(
                () => ormExecuteQuery(
                    '
                    select pokemon
                    from pokemon as pokemon
                    where costume = :costume
                    and (
                        upper(pokemon.generation.region) like :search
                        or upper(pokemon.gender) like :search
                        or upper(pokemon.name) like :search
                        or upper(pokemon.costumetype) like :search
                        #numericSearch#
                    )
                    #orderBy#
                    ',
                    params,
                    {offset: offset, maxResults: records}
                ).map((currPokemon) => {
                    var currSes = currPokemon.getSes();
                    if(currPokemon.getCostume()) {
                        currSes = listToArray(currSes, '-')[1];
                    }

                    return {
                        pokemonid    : currPokemon.getId(),
                        generation   : currPokemon.getGeneration().getRegion(),
                        number       : currPokemon.getNumber(),
                        gender       : currPokemon.getGender(),
                        name         : currPokemon.getName(),
                        costumetype  : currPokemon.getCostumetype() ?: '',
                        sprite       : '/includes/images/sprites/#currPokemon.getSprite()##getImageExtension()#',
                        shiny        : currPokemon.getShiny() ? '/includes/images/shinysprites/#currPokemon.getSprite()##getImageExtension()#' : '',
                        shadow       : currPokemon.getShadow(),
                        shadowshiny  : currPokemon.getShadowShiny(),
                        fastmoves    : currPokemon.getMovesText('fast', 'all'),
                        chargemoves  : currPokemon.getMovesText('charge', 'all'),
                        evolutiontext: currPokemon.getEvolutionText(),
                        shadowicon   : '/includes/images/shadow-pokemon#getImageExtension()#',
                        ses          : currSes
                    };
                }),
                () => ormExecuteQuery(
                    '
                    select count(pokemon.id)
                    from pokemon as pokemon
                    where costume = :costume
                    and (
                        upper(pokemon.generation.region) like :search
                        or upper(pokemon.gender) like :search
                        or upper(pokemon.name) like :search
                        or upper(pokemon.costumetype) like :search
                        #numericSearch#
                    )
                    ',
                    params,
                    true
                ),
                () => ormExecuteQuery(
                    'select count(pokemon.id) from pokemon as pokemon where costume = :costume',
                    {costume: costume},
                    true
                )
            )
            .get();

        return {
            data           : results[1],
            recordsFiltered: results[2],
            recordsTotal   : results[3]
        };
    }

}
