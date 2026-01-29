component singleton accessors="true" {

    property name="async"        inject="asyncManager@coldbox";
    property name="auditService" inject="services.audit";
    property name="cacheService" inject="services.cache";
    property name="moveService"  inject="services.move";

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
            detail  = 'Created Pokemon: #arguments.pokemonProperties.number# | #arguments.pokemonProperties.name# | #arguments.pokemonProperties.gender#',
            agent   = ''
        );
        return newPokemon;
    }

    public void function update(
        required struct pokemonProperties,
        required array moves,
        required array evolutions
    ) {
        // This assumes these three properties cannot be changed
        var currPokemon = get({
            number: arguments.pokemonProperties.number,
            name  : arguments.pokemonProperties.name,
            gender: arguments.pokemonProperties.gender
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

    public array function getAll() {
        var cacheKey   = 'pokemon.getAll';
        var allPokemon = cacheService.get(cacheKey);
        if(isNull(allPokemon)) {
            allPokemon = get({}, 'generation asc, number asc, form asc');

            // Make sure relationships are loaded before being cached
            allPokemon.each((pokemon, index) => {
                var fastMoves   = arguments.pokemon.getMovesText('fast', 'all');
                var chargeMoves = arguments.pokemon.getMovesText('charge', 'all');
                var evolutions  = arguments.pokemon.getEvolutionText();
                var region      = arguments.pokemon.getGeneration().getRegion();
            });

            cacheService.put(
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
        return entityLoad('pokemon', {ses: ses}, true);
    }

    public array function getEvolution(required component pokemon, component evolution) {
        var params = {'pokemon': arguments.pokemon};
        if(!isNull(arguments.evolution)) {
            params.insert('evolution', arguments.evolution);
        }
        return entityLoad('evolution', params);
    }

    private void function createEvolutions(required component pokemon, required array evolutions) {
        evolutions.each((evolution) => {
            // Attempt to load the evolution pokemon trying to be made
            var evolvedPokemon = get({
                'number': evolution.number,
                'name'  : evolution.name,
                'gender': evolution.gender
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

    public struct function getMaxStats() {
        var cacheKey = 'pokemon.getMaxStats';
        var max      = cacheService.get(cacheKey);
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

            cacheService.put(cacheKey, max, getCacheTime(), getCacheTime());
        }

        return max;
    }

    // Get the pokemon that evolve into the argument pokemon
    private array function getEvolvers(required component pokemon) {
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
    private array function getPreviousEvents(required component pokemon, numeric limit = 5) {
        var events = ormExecuteQuery(
            '
            select custom
            from custom as custom
            left outer join custom.custompokedex as custompokedex
            where custompokedex.pokemon = :pokemon
            and custom.link is not null
            order by custom.id desc
            ',
            {pokemon: arguments.pokemon},
            {maxResults: arguments.limit}
        );

        var result = [];
        events.each((event) => {
            result.append({
                id    : event.getId(),
                begins: event.getFormattedBegins(),
                ends  : event.getFormattedEnds(),
                name  : event.getName(),
                link  : event.getLink()
            });
        });

        return result;
    }

    /**
     * Get detail about a pokemon
     */
    public struct function getDetail(required string ses) {
        // Check cache first
        var cacheKey = 'pokemon.getDetail|pokemonses=#ses#';
        var detail   = cacheService.get(cacheKey);
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
            detail.title     = '#detail.pokemon.getNumber()# - #detail.pokemon.getName()#';

            detail.metaDescription = '#ucFirst(detail.pokemon.getName())#''s (###detail.pokemon.getNumber()#) evolutions, CP range, stats, moveset, and events in Pokemon GO.';
            detail.metaKeywords    = 'Pokémon GO, #ucFirst(detail.pokemon.getName())#, max CP, raid CP, shiny, events, moves';

            cacheService.put(
                cacheKey,
                detail,
                getCacheTime() * 15,
                getCacheTime() * 15
            );
        }
        return detail;
    }

    public void function updateDetail(
        required component pokemon,
        required boolean live,
        required boolean shiny,
        required boolean shadow,
        required boolean shinyShadow,
        required boolean tradable
    ) {
        var overrides = deserializeJSON(fileRead('/includes/assets/envpokedexoverrides.json'));

        // Update env pokedex overrides
        overrides[pokemon.getName()] = {
            live       : live,
            shiny      : shiny,
            shadow     : shadow,
            shadowshiny: shinyShadow,
            tradable   : tradable
        };

        fileWrite(
            '/includes/assets/envpokedexoverrides.json',
            serializeJSON(overrides),
            'UTF-8'
        );

        // Update the DB
        pokemon.setLive(live);
        pokemon.setShiny(shiny);
        pokemon.setShadow(shadow);
        pokemon.setShadowShiny(shinyShadow);
        pokemon.setTradable(tradable);
        entitySave(pokemon);
        ormFlush();

        cacheService.remove('pokemon.getDetail|pokemonses=#pokemon.getSes()#');
        return;
    }

    /**
     * Build JSON for pokemon search box
     */
    public string function getSearch() {
        var cacheKey = 'pokemon.getSearch';
        var search   = cacheService.get(cacheKey);
        if(isNull(search)) {
            var pokemon = getAll();
            search      = getAll().map((pokemon) => {
                return {
                    id   : pokemon.getId(),
                    text : '#pokemon.getGender().len() ? pokemon.getGender() & ' ' : ''##pokemon.getName()#',
                    image: '#pokemon.getSprite()##application.cbController.getSetting('imageExtension')#',
                    alt  : 'Pokemon #pokemon.getNumber()# - #pokemon.getGender().len() ? '-#pokemon.getGender()# ' : ''##pokemon.getName()#',
                    ses  : '#pokemon.getSes()#'
                };
            });

            search = serializeJSON(search);
            cacheService.put(cacheKey, search, getCacheTime(), getCacheTime());
        }
        return search;
    }

    public struct function getTable(
        required numeric records,
        required numeric offset,
        required string search    = '',
        required string orderCol1 = '',
        required string orderDir1 = '',
        string orderCol2          = '',
        string orderDir2          = ''
    ) {
        var params = {search: '%#uCase(arguments.search)#%'};

        // Default order by
        var orderBy = '';
        if(arguments.orderCol1.len() && arguments.orderDir1.len()) {
            orderBy = 'order by #getDatatableCols()[arguments.orderCol1 + 1]# #arguments.orderDir1#';
        }
        if(arguments.orderCol2.len() && arguments.orderDir2.len()) {
            orderBy &= ', #getDatatableCols()[arguments.orderCol2 + 1]# #arguments.orderDir2#';
        }
        if(!orderBy.len()) {
            orderBy = 'order by generation asc, number asc';
        }
        else {
            orderBy &= ', pokemon.form asc';
        }

        var numericSearch = '';
        if(isNumeric(arguments.search)) {
            numericSearch = 'or pokemon.number = :numericSearch';
            params.insert('numericSearch', arguments.search);
        }

        var pokemon = ormExecuteQuery(
            '
            select pokemon
            from pokemon as pokemon
            where upper(pokemon.generation.region) like :search
                or upper(pokemon.gender) like :search
                or upper(pokemon.name) like :search
                #numericSearch#
            #orderBy#
            ',
            params,
            {offset: arguments.offset, maxResults: arguments.records}
        );

        var filteredCount = ormExecuteQuery(
            '
            select count(pokemon.id)
            from pokemon as pokemon
            where upper(pokemon.generation.region) like :search
                or upper(pokemon.gender) like :search
                or upper(pokemon.name) like :search
                #numericSearch#
            ',
            params,
            true
        );

        var data = [];
        pokemon.each((currPokemon) => {
            data.append({
                pokemonid    : currPokemon.getId(),
                generation   : currPokemon.getGeneration().getRegion(),
                number       : currPokemon.getNumber(),
                gender       : currPokemon.getGender(),
                name         : currPokemon.getName(),
                sprite       : '/includes/images/sprites/#currPokemon.getSprite()##application.cbController.getSetting('imageExtension')#',
                shiny        : currPokemon.getShiny() ? '/includes/images/shinysprites/#currPokemon.getSprite()##application.cbController.getSetting('imageExtension')#' : '',
                shadow       : currPokemon.getShadow(),
                shadowshiny  : currPokemon.getShadowShiny(),
                fastmoves    : currPokemon.getMovesText('fast', 'all'),
                chargemoves  : currPokemon.getMovesText('charge', 'all'),
                evolutiontext: currPokemon.getEvolutionText(),
                shadowicon   : '/includes/images/shadow-pokemon#application.cbController.getSetting('imageExtension')#',
                ses          : currPokemon.getSes()
            });
        });

        return {
            data           : data,
            recordsTotal   : getAll().len(),
            recordsFiltered: filteredCount
        }
    }

}
