component singleton accessors="true" {

    property name="auditService"      inject="services.audit";
    property name="blogService"       inject="services.blog";
    property name="cacheService"      inject="services.cache";
    property name="customService"     inject="services.custom";
    property name="generationService" inject="services.generation";
    property name="medalService"      inject="services.medal";
    property name="moveService"       inject="services.move";
    property name="pokemonService"    inject="services.pokemon";
    property name="schedulerService"  inject="coldbox:schedulerService";
    property name="scraperService"    inject="services.scraper";
    property name="securityService"   inject="services.security";

    property name="maxThreads"  inject="coldbox:setting:maxThreads";
    property name="concurrency" inject="coldbox:setting:concurrency";

    property name="leekduckNameMap" type="struct";
    property name="regionalForms"   type="array";

    public void function init() {
        // Maps leekduck name to name used in pogo tracker
        setLeekduckNameMap(deserializeJSON(fileRead('/includes/assets/leekducknamemap.json')));
        setRegionalForms(['Alolan', 'Galarian', 'Hisuian', 'Paldean']);
    }

    /**
     * Builds the pokedex.json database
     * Builds pokemon details, evolutions, moves
     */
    public void function buildPokemonData() {
        var pokedex      = [];
        var pokedexDoc   = scraperService.getData('https://pokemondb.net/go/pokedex');
        var pokedexTable = pokedexDoc.body().select('##pokedex');

        var headerData   = pokedexTable.select('thead').select('tr')[1].select('th');
        // Map the wanted fields to the correct indices from the header row
        var wantedFields = [
            '##',
            'Name',
            'Type',
            'Attack',
            'Defense',
            'HP',
            'Catch',
            'Flee',
            'Fast Moves',
            'Charge Moves'
        ];
        var headerMap = [];
        headerData.each((th) => {
            if(wantedFields.contains(th.text())) {
                headerMap.append(th.text());
            }
            else {
                headerMap.append(''); // Insert blank spot to preserve order
            }
        });

        var bodyData = pokedexTable.select('tbody').select('tr');
        // Build the table json data
        bodyData.each(
            (tr, trindex) => {
                var rowData = tr.select('td');
                var curr    = {};

                rowData.each((td, tdindex) => {
                    var currKey = headerMap[tdindex];
                    if(!len(currKey)) return;

                    if(currKey == '##') {
                        curr.number = parseNumber(td.text(), 'dec');
                    }
                    else if(
                        currKey == 'Catch' || currKey == 'Flee' || currKey == 'Attack' || currKey == 'Defense' || currKey == 'HP'
                    ) {
                        var temp      = reReplace(td.text(), '[^0-9.]', '');
                        curr[currKey] = temp.len() ? parseNumber(temp) : -1;
                    }
                    else if(currKey == 'Fast Moves' || currKey == 'Charge Moves') {
                        var currMoves = listToArray(td.html(), '<br>', false, true);

                        if(!curr.keyExists('moves')) {
                            curr.moves = [];
                        }
                        currMoves.each((move) => {
                            // Remove spaces and HTML
                            var safe = reReplaceNoCase(move.trim(), '<[^>]*>', '', 'ALL'); // remove spaces

                            // Move conditions, shadow/purified marked with $, elite tmable moves marked *, unobtainable moves marked **
                            var condition = '';
                            if(safe.findNoCase('(Shadow)')) {
                                safe      = safe.replaceNoCase(' (Shadow)', '');
                                condition = '$';
                            }
                            else if(safe.findNoCase('(Purified)')) {
                                safe      = safe.replaceNoCase(' (Purified)', '');
                                condition = '$';
                            }
                            else if(safe.findNoCase('(Community Day)')) {
                                safe      = safe.replaceNoCase(' (Community Day)', '');
                                condition = '*';
                            }
                            else if(safe.findNoCase('(Legacy)')) {
                                safe      = safe.replaceNoCase(' (Legacy)', '');
                                condition = '*';
                            }

                            // Replace all spaces, dashes, and apostrophes with underscore/blank
                            safe = uCase(
                                safe.replace(' ', '_', 'ALL')
                                    .replace('-', '_', 'ALL')
                                    .replace('''', '', 'ALL')
                            );

                            // Edge cases and data mismatches between sources
                            if(safe.find('___')) {
                                safe = safe.replace('___', '_', 'ALL');
                            }
                            if(safe == 'SUPERPOWER') {
                                safe = 'SUPER_POWER';
                            }
                            if(safe == 'VISE_GRIP') {
                                safe = 'VICE_GRIP';
                            }
                            if(safe == 'TECHNO_BLAST_FIRE') {
                                safe = 'TECHNO_BLAST_BURN';
                            }
                            if(safe == 'TECHNO_BLAST_ELECTRIC') {
                                safe = 'TECHNO_BLAST_SHOCK';
                            }
                            if(safe == 'TECHNO_BLAST_WATER') {
                                safe = 'TECHNO_BLAST_DOUSE';
                            }
                            if(safe == 'TECHNO_BLAST_ICE') {
                                safe = 'TECHNO_BLAST_CHILL';
                            }

                            safe &= condition;

                            curr.moves.append(safe);
                        });
                    }
                    else {
                        curr[currKey] = td.text();
                    }
                });

                pokedex.append(curr);
            },
            true,
            maxThreads
        );

        var shinyData = {}; // map the name to whether they are shiny
        var shinyDoc  = scraperService.getData('https://pokemondb.net/go/shiny');
        var shinyDivs = shinyDoc.body().select('div.infocard-list');

        shinyDivs.each(
            (genDiv, genIndex) => {
                var currGenData = genDiv.select('div.infocard').select('span.infocard-lg-data');
                currGenData.each((pokemonData, pokemonIndex) => {
                    var name    = pokemonData.select('a.ent-name').text();
                    var special = pokemonData.select('small')[2];
                    if(!special.select('a').len()) {
                        special = special.text();
                        if(special.findNoCase(name)) {
                            name = special;
                        }
                        else {
                            name = '#name# #special#';
                        }
                    }

                    shinyData.insert(name, pokemonData.text().findNoCase('*') > 0);
                });
            },
            true,
            maxThreads
        );

        var shadowData = deserializeJSON(fileRead('/includes/assets/shadowdata.json'));
        // Web scraper is blocked in prod
        if(application.cbController.getSetting('getShadowData')) {
            shadowData    = {};
            var shadowDoc = scraperService.getData(
                'https://bulbapedia.bulbagarden.net/wiki/List_of_Shadow_Pok%C3%A9mon_in_Pok%C3%A9mon_GO',
                true
            );
            var shadowTable = shadowDoc
                .body()
                .select('table.roundy.sortable')
                .select('tbody > tr');
            shadowTable.each((tr, trindex) => {
                var rowData = tr.select('td');
                if(!rowData.len()) continue;
                var curr = {};

                rowData.each((td, tdindex) => {
                    if(tdindex > 3) break;

                    // number
                    if(tdindex == 1) {
                        curr.number = parseNumber(td.text(), 'dec');
                    }
                    // shiny available check
                    else if(tdindex == 2) {
                        var isShiny = td.select('span > a > img[alt=Shiny]');
                        curr.shiny  = isShiny.len() ? true : false;
                        curr.img    = td.select('span > span > a > img').attr('src');
                    }
                    // name
                    else {
                        // have to check if this is a regional form
                        var check  = listToArray(listToArray(listToArray(listLast(curr.img, '/'), '-')[2], '.')[1], '');
                        curr.check = check[check.len()];

                        if(isNumeric(curr.check)) {
                            curr.name = td.text();
                        }
                        else {
                            // A - alolan, G - galarian, H - hisuian, P - paldean
                            if(curr.check == 'A') {
                                curr.name = 'Alolan #td.text()#';
                            }
                            else if(curr.check == 'G') {
                                curr.name = 'Galarian #td.text()#';
                            }
                            else if(curr.check == 'H') {
                                curr.name = 'Hisuian #td.text()#';
                            }
                            else if(curr.check == 'P') {
                                curr.name = 'Paldean #td.text()#';
                            }
                        }
                    }
                });

                if(!shadowData.keyExists(curr.name)) {
                    shadowData.insert(curr.name, curr);
                }
                else {
                    shadowData.insert('SKIPPED#curr.name#', curr);
                }
            });
            fileWrite(
                '/includes/assets/shadowdata.json',
                serializeJSON(shadowdata),
                'UTF-8'
            );
        }

        // Build the evolution data
        var evolutionData = {}; // map name -> stage, evolution, cost
        var evolutionDoc  = scraperService.getData('https://pokemondb.net/go/evolution');
        var evoLists      = evolutionDoc.body().select('.infocard-filter-block > .infocard-list-evo');

        // Handles branching evolutions
        evoLists.each(
            (evo) => {
                processEvolutionChain(evo, evolutionData);
            },
            true,
            maxThreads
        );

        // Map final stage -> mega/giga mon
        var specialEvolutionMap     = {};
        var specialEvolutionPokemon = ormExecuteQuery(
            '
            from pokemon as pokemon
            where pokemon.mega = true or pokemon.giga = true
            '
        );
        specialEvolutionPokemon.each((pokemon) => {
            // no regional forms have mega/giga. use number and name to get the form that should have the evolution added
            var curr = listToArray(pokemon.getName(), ' ');

            if(!specialEvolutionMap.keyExists(curr[2])) {
                specialEvolutionMap[curr[2]] = [];
            }
            specialEvolutionMap[curr[2]].append({
                condition: pokemon.getGiga() ? 'Gigantamax Form' : 'Mega Evolution',
                number   : pokemon.getNumber(),
                cost     : '',
                gender   : '',
                name     : pokemon.getName(),
                stage    : 0,
                special  : true
            });
        });

        var jsonPokedex = {};

        // Perform data aggregation and cleanup
        pokedex.each(
            (pokemon, index) => {
                // Turn the type list into an array
                pokemon.type = listToArray(pokemon.type, ' ');

                // Properly format the name
                var currNameSplit = listToArray(pokemon.name, ' ');

                pokemon.mega     = false;
                pokemon.giga     = false;
                pokemon.form     = false;
                pokemon.formtype = '';
                pokemon.gender   = '';
                // Remove the first index since that is the base pokemon name
                if(currNameSplit.len() >= 2) {
                    // Galarian Mr. Mime
                    if(currNameSplit[1] == 'Mr.') {
                        if(currNameSplit.len() >= 3) {
                            currNameSplit    = arraySlice(currNameSplit, 3);
                            pokemon.name     = arrayToList(currNameSplit, ' ');
                            pokemon.formtype = 'Galarian';
                        }
                    }
                    // Mime Jr. OR Tapu
                    else if(currNameSplit[2] == 'Jr.' || currNameSplit[1] == 'Tapu') {
                        pokemon.name = pokemon.name;
                    }
                    // Gender pokemon
                    else if(currNameSplit[2] == 'Male' || currNameSplit[2] == 'Female') {
                        pokemon.name     = currNameSplit[1];
                        pokemon.gender   = currNameSplit[2];
                        pokemon.formtype = pokemon.gender;
                    }
                    // Mega or Regional Form
                    else if(
                        currNameSplit[2] == 'Mega' ||
                        currNameSplit[2] == 'Primal' ||
                        getRegionalForms().contains(currNameSplit[2])
                    ) {
                        // Strip the leading name
                        currNameSplit = arraySlice(currNameSplit, 2);
                        pokemon.name  = arrayToList(currNameSplit, ' ');

                        // Determine whether this pokemon is a mega
                        pokemon.mega     = currNameSplit[1] == 'Mega' || currNameSplit[1] == 'Primal';
                        // Mega are special forms
                        pokemon.form     = true;
                        pokemon.formtype = currNameSplit[1];
                    }
                    // Special form
                    else {
                        pokemon.form = true;

                        // Strip the leading name if it's repeated in the form name
                        if(
                            arraySlice(currNameSplit, 2).contains(currNameSplit[1])
                            || currNameSplit[1].findNoCase('Ho-Oh')
                        ) {
                            currNameSplit = arraySlice(currNameSplit, 2);
                            pokemon.name  = arrayToList(currNameSplit, ' ');
                        }

                        // Handle cases where formtype comes before pokemon's name
                        if(
                            currNameSplit[2] == 'Rotom'
                            || currNameSplit[2] == 'Kyurem'
                        ) {
                            pokemon.formtype = currNameSplit[1];
                        }
                        // Maushold
                        else if(currNameSplit[1] == 'Maushold') {
                            pokemon.formtype = currNameSplit[4];
                        }
                        else {
                            pokemon.formtype = currNameSplit[2];
                        }
                    }
                }

                // Nidoran
                if(findNoCase('Nidoran', pokemon.name)) {
                    if(pokemon.name.find('♀')) {
                        pokemon.gender = 'Female';
                    }
                    else if(pokemon.name.find('♂')) {
                        pokemon.gender = 'Male';
                    }
                }

                // Pokemon on this list are in the game
                pokemon.live = true;

                // assume tradable - this flag overwritten if needed
                pokemon.tradable = !(pokemon.mega || pokemon.giga);

                // Shiny data
                pokemon.shiny = false;
                if(shinyData.keyExists(pokemon.name)) {
                    pokemon.shiny = shinyData['#pokemon.name#'];
                }
                else if(shinyData.keyExists('#pokemon.name# #pokemon.gender#')) {
                    pokemon.shiny = shinyData['#pokemon.name# #pokemon.gender#']
                }

                // Shadow Data
                pokemon.shadow      = false;
                pokemon.shadowshiny = false;
                if(shadowData.keyExists(pokemon.name)) {
                    pokemon.shadow      = true;
                    pokemon.shadowshiny = shadowData[pokemon.name].shiny;
                }

                // Evolution Data
                pokemon.evolutions = [];
                if(evolutionData.keyExists(pokemon.name)) {
                    pokemon.evolutions = evolutionData[pokemon.name];
                }
                else if(evolutionData.keyExists('#pokemon.name# #pokemon.gender#')) {
                    pokemon.evolutions = evolutionData['#pokemon.name# #pokemon.gender#'];
                }

                // Mega/Giga evolution data
                if(specialEvolutionMap.keyExists(pokemon.name)) {
                    pokemon.evolutions.append(specialEvolutionMap['#pokemon.name#'], true);
                }

                pokemon.generation = getGeneration(pokemon.name, pokemon.number);

                pokemon.sprite = '#pokemon.number#';
                if(pokemon.form) {
                    pokemon.sprite &= '-#pokemon.name#';
                }
                if(pokemon.gender != '') {
                    pokemon.sprite &= '-#pokemon.gender#';
                }

                if(pokemon.gender.len() && !findNoCase('Nidoran', pokemon.name)) {
                    jsonPokedex.insert('#pokemon.name# #pokemon.gender#', pokemon);
                }
                else {
                    jsonPokedex.insert(pokemon.name, pokemon);
                }
            },
            true,
            maxThreads
        );

        // Read in custom overrides and overwrite scraped data
        var overrides = deserializeJSON(fileRead('/includes/assets/pokedexoverrides.json'));
        overrides.each(
            (pokemon, custom) => {
                custom.each((key, value) => {
                    // If we want to remove this pokemon
                    if(key == 'Delete' && value == true) {
                        if(jsonPokedex.keyExists(pokemon)) {
                            jsonPokedex.delete(pokemon);
                        }
                    }
                    else {
                        if(!jsonPokedex.keyExists(pokemon)) {
                            jsonPokedex.insert(pokemon, {});
                        }

                        if(jsonPokedex['#pokemon#'].keyExists(key)) {
                            if(key == 'moves') {
                                // Only add new moves
                                value.each((move) => {
                                    if(!jsonPokedex['#pokemon#'][key].contains(move)) {
                                        jsonPokedex['#pokemon#'][key].append(move);
                                    }
                                });
                            }
                            else {
                                jsonPokedex['#pokemon#'][key] = value;
                            }
                        }
                        else {
                            jsonPokedex['#pokemon#'].insert(key, value);
                        }
                    }
                });
            },
            true,
            maxThreads
        );

        // Read in env overrides
        if(!fileExists('#application.cbController.getSetting('rootPath')#/includes/assets/envpokedexoverrides.json')) {
            fileWrite(
                '#application.cbController.getSetting('rootPath')#/includes/assets/envpokedexoverrides.json',
                serializeJSON({})
            );
        }
        var envOverrides = deserializeJSON(
            fileRead('#application.cbController.getSetting('rootPath')#/includes/assets/envpokedexoverrides.json')
        );
        envOverrides.each(
            (pokemon, custom) => {
                custom.each((key, value) => {
                    jsonPokedex['#pokemon#'][key] = value;
                });
            },
            true,
            maxThreads
        );

        // Derive SES urls
        jsonPokedex.each(
            (name, pokemon) => {
                pokemon.ses   = createSes(pokemon);
                pokemon.moves = pokemon.moves.map((move) => {
                    // Mark which moves are shadow or legacy only
                    // Clean up nameid
                    var curr = {shadow: false, legacy: false};
                    if(move.find('*')) {
                        move        = left(move, move.len() - 1);
                        curr.legacy = true;
                    }
                    else if(move.find('$')) {
                        move        = left(move, move.len() - 1);
                        curr.shadow = true;
                    }

                    curr.nameid = move;
                    return curr;
                });

                // Clean up duplicate evos
                var evoMap         = {};
                pokemon.evolutions = pokemon.evolutions.each((evolution) => {
                    // Account for gender evolutions
                    var safeName = evolution.name;
                    if(findNoCase('male', safeName)) {
                        safeName = listToArray(safeName, ' ')[1];
                    }
                    evolution.name = safeName;
                });
                pokemon.evolutions = pokemon.evolutions.filter((evolution) => {
                    // Check that this key isn't already inserted
                    var key = '#evolution.name#|#evolution.number#|#evolution.gender#';
                    if(!evoMap.keyExists(key)) {
                        evoMap[key] = true;
                        return true;
                    }
                    return false;
                });
            },
            true,
            maxThreads
        );

        if(application.cbController.getSetting('writeJson')) {
            fileWrite(
                '/includes/assets/pokedex.json',
                serializeJSON(jsonPokedex),
                'UTF-8'
            );
        }

        // Update the data
        updatePokemonData(jsonPokedex);
        return;
    }

    /**
     * Get all evolution data in this chain. The branching can occur at any point
     */
    function processEvolutionChain(evoElement, evolutionData) {
        // Get direct children only (not nested ones)
        var directCards  = evoElement.select('> div.infocard');
        var directArrows = evoElement.select('> span.infocard-arrow');
        var splitElement = evoElement.select('> span.infocard-evo-split');

        var chain = [];

        // Parse direct cards in the main chain
        directCards.each((card, idx) => {
            var data = parseCardData(card, idx);

            // Get evolution cost if not the first card
            if(idx > 1 && directArrows.len() >= idx - 1) {
                var costData   = parseEvolutionCost(directArrows[idx - 1], data.name);
                data.cost      = costData.cost;
                data.condition = costData.condition;

                // Gender checks for condition - apply to previous pokemon
                if((data.condition == 'Female' || data.condition == 'Male') && chain[idx - 1].gender == '') {
                    chain[idx - 1].gender = data.condition;
                }
            }

            chain.append(data);
        });

        // Store evolutions for the direct chain
        for(var i = 2; i <= chain.len(); i++) {
            if(!evolutionData.keyExists(chain[i - 1].name)) {
                evolutionData[chain[i - 1].name] = [];
            }
            evolutionData[chain[i - 1].name].append(chain[i]);

            // Burmy...
            if(findNoCase('burmy ', chain[i - 1].name)) {
                evolutionData[chain[i - 1].name].append({
                    'condition': 'Male',
                    'cost'     : 50,
                    'gender'   : '',
                    'name'     : 'Mothim',
                    'number'   : 414,
                    'region'   : '',
                    'special'  : false,
                    'stage'    : 2
                });
            }
        }

        // Handle branching
        if(splitElement.len()) {
            splitElement = splitElement.first();
            var branches = splitElement.select('> div.infocard-list-evo');
            var baseCard = chain.len() > 0 ? chain[chain.len()] : null;

            branches.each((branch) => {
                var branchCards  = branch.select('div.infocard');
                var branchArrows = branch.select('span.infocard-arrow');
                var branchChain  = [];

                // If we have a base card from main chain, start from there
                if(!isNull(baseCard)) {
                    branchChain.append(duplicate(baseCard));
                }

                // Parse all cards in this branch
                branchCards.each((card, idx) => {
                    var stageOffset = branchChain.len();
                    var data        = parseCardData(card, stageOffset + idx);

                    // Get evolution cost from arrows
                    if(branchArrows.len() >= idx) {
                        var costData   = parseEvolutionCost(branchArrows[idx], data.name);
                        data.cost      = costData.cost;
                        data.condition = costData.condition;

                        // Gender checks for condition - apply to previous pokemon
                        if(
                            (data.condition == 'Female' || data.condition == 'Male') && branchChain.len() > 0 && branchChain[
                                branchChain.len()
                            ].gender == ''
                        ) {
                            branchChain[branchChain.len()].gender = data.condition;
                        }
                    }

                    branchChain.append(data);
                });

                // Store evolutions for this branch
                for(var i = 2; i <= branchChain.len(); i++) {
                    if(!evolutionData.keyExists(branchChain[i - 1].name)) {
                        evolutionData[branchChain[i - 1].name] = [];
                    }
                    evolutionData[branchChain[i - 1].name].append(branchChain[i]);
                }
            });
        }
    }

    /**
     * Parses the evolution cost and the conditions that need to be met card
     */
    function parseEvolutionCost(arrow, pokemonName) {
        var evolutionCondition = listToArray(arrow.select('small').text(), ' (', false, true);

        var cost      = pokemonName == 'Gholdengo' ? 999 : parseNumber(evolutionCondition[1]);
        var condition = evolutionCondition.len() == 2 ? left(evolutionCondition[2], evolutionCondition[2].len() - 1) : '';

        return {cost: cost, condition: condition};
    }

    /**
     * Parse the current info-card 
     * We need the current stage, the number, name, gender (if applicable)
     * Handles all the special cases of name
     */
    function parseCardData(card, stage) {
        var currData = {
            stage    : stage,
            number   : -1,
            name     : '',
            gender   : '',
            cost     : -1,
            condition: '',
            region   : '',
            special  : false
        };

        var infoDiv     = card.select('.infocard-lg-data');
        var currName    = infoDiv.select('a.ent-name').text();
        currData.number = parseNumber(replace((infoDiv.select('small')[1]).text(), '##', ''), 'dec');

        if(infoDiv.select('small').len() > 2) {
            var extraInfo      = infoDiv.select('small')[2].text();
            var extraInfoSplit = listToArray(extraInfo, ' ');
            var seasons        = ['Winter', 'Summer', 'Autumn', 'Spring'];

            // Regional Check
            if(getRegionalForms().contains(extraInfoSplit[1])) {
                currData.region = extraInfoSplit[1];
            }

            // Gender check
            if(extraInfo == 'Female' || extraInfo == 'Male') {
                currData.gender = extraInfo;
            }

            // Deerling/Sawsbuck seasonal form check
            if(seasons.contains(extraInfoSplit[1])) {
                currName = '#currName# #extraInfo#';
            }

            // Darmanitan Check
            if(
                (extraInfoSplit.len() >= 1 && extraInfoSplit[1] == 'Standard') ||
                (extraInfoSplit.len() >= 2 && extraInfoSplit[2] == 'Standard')
            ) {
                currName = '#currName# Standard Mode';
            }

            // Burmy/Wormadam Check
            if(extraInfoSplit[1] == 'Plant' || extraInfoSplit[1] == 'Sandy' || extraInfoSplit[1] == 'Trash') {
                currName = '#currName# #extraInfo#';
            }

            // Shellos/Gastrodon Check
            if(extraInfoSplit[1] == 'East' || extraInfoSplit[1] == 'West') {
                currName = '#currName# #extraInfo#';
            }

            // Lycanroc
            if(extraInfoSplit[1] == 'Midday' || extraInfoSplit[1] == 'Midnight' || extraInfoSplit[1] == 'Dusk') {
                currName = '#currName# #extraInfo#';
            }

            // Gimmighoul
            if(extraInfo == 'Roaming Form') {
                currName = '#currName# #extraInfo#';
            }

            // Toxtricity
            if(extraInfo == 'Low Key Form' || extraInfo == 'Amped Form') {
                currName = '#currName# #extraInfo#';
            }
        }

        currData.name = '#currData.region.len() ? '#currData.region# ' : ''##currName##currData.gender.len() ? ' #currData.gender#' : ''#';
        return currData;
    }

    /**
     * Updates the database using json pokedex
     */
    public void function updatePokemonData(required struct jsonPokedex) {
        // Create missing generations
        generationService.createAll();

        // Update pokemon / create if new pokemon
        jsonPokedex.each((name, pokemon) => {
            var moves = []; // {move cfc, legacy t/f, shadow t/f}
            pokemon.moves.each((move) => {
                var curr = {shadow: move.shadow, legacy: move.legacy};
                // Add move cfc
                if(moveService.check(move.nameid)) {
                    curr.move = moveService.get(move.nameid);
                    moves.append(curr);
                }
            });

            pokemonService.update(
                {
                    'number'     : pokemon.number,
                    'name'       : pokemon.name,
                    'generation' : generationService.get(pokemon.generation),
                    'gender'     : pokemon.gender,
                    'live'       : pokemon.live,
                    'shiny'      : pokemon.shiny,
                    'type1'      : pokemon.type[1],
                    'type2'      : pokemon.type.len() == 2 ? pokemon.type[2] : '',
                    'attack'     : pokemon.attack,
                    'defense'    : pokemon.defense,
                    'hp'         : pokemon.hp,
                    'catch'      : pokemon.catch,
                    'flee'       : pokemon.flee,
                    'form'       : pokemon.form,
                    'mega'       : pokemon.mega,
                    'sprite'     : pokemon.sprite,
                    'tradable'   : pokemon.tradable,
                    'shadow'     : pokemon.shadow,
                    'shadowshiny': pokemon.shadowshiny,
                    'giga'       : pokemon.giga,
                    'formtype'   : pokemon?.formtype ?: '',
                    'ses'        : pokemon.ses
                },
                moves,
                pokemon.evolutions
            );
        });

        ormFlush();

        // Flush pokemon cache
        cacheService.clear('pokemon.');

        // Cache the pokemon data
        var allPokemon = pokemonService.getAll();
        pokemonService.getMaxStats();
        pokemonService.getSearch();
        return;
    }

    /**
     * Reads the levels.json and adds levels to database
     * This will need revisited once level 80 has been added
     */
    public void function buildLevels() {
        var levelMap   = deserializeJSON(fileRead('/includes/assets/levels.json'));
        var currLevels = entityLoad('level');
        if(currLevels.len() == levelMap.count()) {
            return;
        }

        currLevels.each((level) => {
            entityDelete(level);
        });
        ormFlush();


        levelMap.each((key, value) => {
            var currLevel = entityNew('level', {level: key, requiredxp: value});
            entitySave(currLevel);
        });

        ormFlush();
        return;
    }

    /**
     * Builds the medal data from pokemon go wiki
     */
    public void function buildMedalData() {
        var jsonMedals = {};
        var medalDoc   = scraperService.getData('https://pokemongo.fandom.com/wiki/Medals');
        var medalTable = medalDoc
            .body()
            .select('##content')
            .select('table.pogo-legacy-table');

        // Map wanted fields to the correct column indices
        var wantedFields = [
            'Name',
            'Requirement',
            'None',
            'Bronze',
            'Silver',
            'Gold',
            'Platinum'
        ];
        var headerMap  = [];
        var headerData = medalTable.select('tbody')[1].select('tr')[1].select('th');
        headerData.each((th, thindex) => {
            if(wantedFields.contains(th.text())) {
                headerMap.append(th.text());
            }
            else {
                headerMap.append(''); // Blank to preserve order
            }
        });

        // Build the table body data
        var order     = 1; // track the order to display
        var tableData = medalTable.select('tbody');
        tableData.each((tbody, bodyindex) => {
            if(bodyindex == 2) continue; // unreleased medals

            var bodyData = tbody.select('tr');
            bodyData.each((tr, trindex) => {
                var rowData = tr.select('td');
                if(!rowData.len()) continue;
                var curr = {order: order};

                rowData.each((td, tdindex) => {
                    // Image index
                    if(tdindex == 3) {
                        // Select the image src url
                        var imgSrc = td.select('a').attr('href');
                        if(!imgSrc.contains('https')) return;

                        // Fetch the image blob
                        cfhttp(
                            url    = imgSrc,
                            result = "imgResult",
                            method = "GET"
                        );

                        // CF make image object and write to disk
                        var img = imageNew(imgResult.filecontent);
                        img.write('/includes/images/medals/#curr.name#.webp');
                    }
                    // catch medals are all set values
                    else if(bodyIndex == 3 && tdindex > 3) {
                        if(tdindex == 4) curr.bronze = 10;
                        else if(tdindex == 5) curr.silver = 50;
                        else if(tdindex == 6) curr.gold = 200;
                        else if(tdindex == 7) curr.platinum = 2500;
                    }
                    else {
                        var currKey = headerMap[tdindex];
                        if(!currKey.len() || !td.text().len()) return;

                        if(currKey == 'Requirement') {
                            curr.description = td.text();
                        }
                        else {
                            // community member medal is formatted wrong on site
                            if((curr?.name ?: '') == 'Community Member' || (curr?.name ?: '') == 'Life of the Party') {
                                curr[currKey] = lsParseNumber(listLast(td.text(), ' '));
                            }
                            else {
                                curr[currKey] = lsIsNumeric(td.text()) ? lsParseNumber(td.text()) : td.text();
                            }
                        }
                    }
                });

                if(curr.keyExists('name')) {
                    jsonMedals.insert(curr.name, curr.delete('name'));
                    order++;
                }
            });
        });

        if(application.cbController.getSetting('writeJson')) {
            fileWrite(
                '/includes/assets/medals.json',
                serializeJSON(jsonMedals),
                'UTF-8'
            );
        }

        // Update the medal data
        updateMedalData(jsonMedals);
        return;
    }

    /**
     * Updates the database using the medals.json
     */
    public void function updateMedalData(required struct jsonMedals) {
        // Update medals / create if new medal
        jsonMedals.each((name, medal) => {
            medalService.update({
                'name'        : name,
                'description' : medal.description,
                'bronze'      : medal.bronze,
                'silver'      : medal.silver,
                'gold'        : medal.gold,
                'platinum'    : medal.platinum,
                'displayorder': medal.order
            });
        });

        ormFlush();

        cacheService.remove('medal.getAll');
        return;
    }

    /**
     * Build move data from pvpoke gamemaster
     */
    public void function buildMoveData() {
        var pvppokeData = 'https://pvpoke.com/data/gamemaster.min.json';
        cfhttp(
            url    = pvppokeData,
            result = "result",
            method = "GET"
        );
        var jsonMoves = deserializeJSON(result.filecontent).moves;

        // extra moves
        jsonMoves.append({
            'moveId'    : 'HIDDEN_POWER',
            'name'      : 'Hidden Power',
            'type'      : 'normal',
            'power'     : 9,
            'energy'    : 0,
            'energyGain': 8,
            'cooldown'  : 1500,
            'archetype' : 'Low Quality'
        });

        jsonMoves = refineMoveData(jsonMoves);
        if(application.cbController.getSetting('writeJson')) {
            fileWrite(
                '/includes/assets/moves.json',
                serializeJSON(jsonMoves),
                'UTF-8'
            );
        }

        // Update move data
        updateMoveData(jsonMoves);
        return;
    }

    /**
     * Maps raw json returned to usable fields
     */
    private array function refineMoveData(required array jsonMoves) {
        return jsonMoves.map((move) => {
            var curr = {
                'nameid': move.moveId,
                'name'  : move.name,
                'type'  : move.type,
                'damage': move.power
            };

            if(move.keyExists('energyGain') && move.energyGain > 0) {
                curr.energy = move.energyGain;
                curr.turns  = move.cooldown / 500;
            }
            else {
                curr.energy = move.energy;
                curr.turns  = 0;
            }

            if(move.keyExists('buffTarget')) {
                curr.buffSelf   = move.buffTarget == 'self';
                curr.buffChance = move.buffApplyChance;

                curr.buffEffect = '';
                if(move.buffs[1] != 0) {
                    curr.buffEffect &= '#move.buffs[1] > 0 ? '+' : ''##move.buffs[1]# ATK';
                }
                if(move.buffs[2] != 0) {
                    curr.buffEffect &= ' #move.buffs[2] > 0 ? '+' : ''##move.buffs[2]# DEF';
                }
            }
            else {
                curr.buffSelf   = false;
                curr.buffChance = 0;
                curr.buffEffect = '';
            }

            return curr;
        });
    }

    /**
     * Update move data
     *
     * @jsonMoves result from buildMoveData()
     */
    private void function updateMoveData(required array jsonMoves) {
        // Update / create
        jsonMoves.each((move) => {
            moveService.update(move);
        });

        ormFlush();

        cacheService.remove('move.getAllFastMoves');
        cacheService.remove('move.getAllChargeMoves');
        return;
    }

    /**
     * Create events from leekduck - looks for upcoming pages labeled 'Event'
     *
     * @eventDaysBefore number of days before event starts to create custom pokedex
     */
    public void function createEvents(numeric eventDaysBefore = application.cbController.getSetting('eventDaysBefore')) {
        // Get the events lists
        var events = blogService.getEvents(application.cbController.getSetting('fetchCount') * 2);

        // Find events of type 'event' and < eventDaysBefore days away
        events.each((event) => {
            if(event.type == 'Event' && dateDiff('d', now(), event.datatimestamp) <= eventDaysBefore) {
                createEvent(event.link);
            }
        });
        return;
    }

    /**
     * Create a custom pokedex of event spawns from a leekduck event page
     *
     * @eventLink Leek duck event page
     */
    public void function createEvent(required string eventLink) {
        var spawns   = {};
        // Fetch the event page
        var eventDoc = scraperService.getData(arguments.eventLink);

        // Get the title and wild spawns
        var eventTitle = eventDoc
            .body()
            .select('h1.page-title')
            .text();

        if(eventTitle == 'Pokémon GO Wild Area: Global') {
            eventTitle = eventTitle.split(':');
            eventTitle = '#eventTitle[1]# #year(now())#:#eventTitle[2]#';
        }

        // Remove shadow spawns
        var hasShadow = eventDoc.body().select('h2##shadow');
        if(hasShadow.len() == 1) {
            eventDoc.body().select('h2##shadow ~ ul.pkmn-list-flex')[1].remove();
        }

        // Remove Giovanni spawn
        var giovanni = eventDoc.body().select('h2:contains(Save Shadow)');
        if(giovanni.len() == 1) {
            eventDoc.body().select('h2###giovanni[1].id()# ~ ul.pkmn-list-flex')[1].remove();
        }

        // Remove shadow raids
        var oneStarShadow = eventDoc.body().select('h3##appearing-in-1-star-shadow-raids');
        if(oneStarShadow.len() == 1) {
            eventDoc.body().select('h3##appearing-in-1-star-shadow-raids ~ ul.pkmn-list-flex')[1].remove();
        }

        var threeStarShadow = eventDoc.body().select('h3##appearing-in-3-star-shadow-raids');
        if(threeStarShadow.len() == 1) {
            eventDoc.body().select('h3##appearing-in-3-star-shadow-raids ~ ul.pkmn-list-flex')[1].remove();
        }

        // Remove new rocket leaders
        var rocketLeaders = eventDoc.body().select('h2##team-go-rocket-leaders');
        if(rocketLeaders.len()) {
            eventDoc.body().select('h2##team-go-rocket-leaders ~ ul.pkmn-list-flex')[1].remove();
        }

        // Event Spawns
        var eventPokemon = eventDoc
            .body()
            .select('.pkmn-list-item')
            .select('.pkmn-name');

        eventPokemon.each((pokemon) => {
            spawns[pokemon.text()] = true;
            if(pokemon.text() == 'Castform') {
                spawns['Castform Snowy Form'] = true;
                spawns['Castform Rainy Form'] = true;
                spawns['Castform Sunny Form'] = true;
            }
        });

        // Research task spawns
        var researchPokemon = eventDoc
            .body()
            .select('div.reward-list')
            .select('div.reward');
        researchPokemon.each((div) => {
            if(div.select('span.cp-values').len()) {
                spawns[div.select('span.reward-label').text()] = true;
            }
        });

        if(!spawns.count()) return;

        // Get when event starts and ends
        var begins = formatStringToDate(
            eventDoc
                .body()
                .select('span##event-date-start')
                .text()
        );

        var ends = formatStringToDate(
            eventDoc
                .body()
                .select('span##event-date-end')
                .text()
        );

        // Create custom pokedex if needed
        var custom = ormExecuteQuery(
            '
            select custom
            from custom as custom
            where upper(custom.name) = :eventTitle
            ',
            {eventTitle: uCase(eventTitle)},
            true
        );

        if(isNull(custom)) {
            customid = customService.create(
                trainer = securityService.getTrainer('lanechase34@outlook.com')[1],
                name    = eventTitle,
                public  = true,
                begins  = begins,
                ends    = ends,
                link    = arguments.eventLink
            );
            custom = customService.getFromId(customid);

            auditService.audit(
                ip      = 'localhost',
                event   = 'adminService.createEvent',
                referer = '',
                detail  = 'Created Event: #eventTitle#',
                agent   = ''
            );
        }
        else {
            custom.setBegins(begins);
            custom.setEnds(ends);
            custom.setLink(arguments.eventLink);
            entitySave(custom);
        }

        var pokemon = []; // Create array of pokemon ids
        var map     = {}; // use map to not double enter pokemon
        spawns.each((name, value) => {
            // Check the name map
            if(getLeekduckNameMap().keyExists(name)) {
                name = getLeekduckNameMap()[name];
            }

            var genderCheck = listToArray(name, ' ');
            if(genderCheck.len() == 2 && (genderCheck[2] == 'Male' || genderCheck[2] == 'Female')) {
                var currPokemon = pokemonService.get({'name': genderCheck[1], 'gender': genderCheck[2]});
            }
            else {
                var currPokemon = pokemonService.get({'name': name});
            }

            currPokemon.each((curr) => {
                if(!map.keyExists('#curr.getName()#|#curr.getNumber()#|#curr.getGender()#')) {
                    pokemon.append(curr.getId());
                    map.insert('#curr.getName()#|#curr.getNumber()#|#curr.getGender()#', true);
                }

                // Add its evolution(s)
                curr.getEvolution()
                    .each((evolution) => {
                        // First stage
                        var evolvedMon = evolution.getEvolution();

                        if(
                            !map.keyExists('#evolvedMon.getName()#|#evolvedMon.getNumber()#|#evolvedMon.getGender()#') && !evolution.getSpecial()
                        ) {
                            pokemon.append(evolvedMon.getId());
                            map.insert('#evolvedMon.getName()#|#evolvedMon.getNumber()#|#evolvedMon.getGender()#', true);
                        }

                        // Second stages
                        evolvedMon
                            .getEvolution()
                            .each((twoEvolution) => {
                                var twoEvolvedMon = twoEvolution.getEvolution();

                                if(
                                    !map.keyExists('#twoEvolvedMon.getName()#|#twoEvolvedMon.getNumber()#|#twoEvolvedMon.getGender()#') && !twoEvolution.getSpecial()
                                ) {
                                    pokemon.append(twoEvolvedMon.getId());
                                    map.insert(
                                        '#twoEvolvedMon.getName()#|#twoEvolvedMon.getNumber()#|#twoEvolvedMon.getGender()#',
                                        true
                                    );
                                }
                            })
                    });
            });
        });

        // Update the spawns
        customService.createCustomPokedex(custom, pokemon);

        // Clear the cache
        cacheService.clear('custom.getMine');
        cacheService.clear('|pokedex.getCustomRegistered|custom=#custom.getId()#');
        return;
    }

    /**
     * Get Coldbox task info
     */
    public array function getTaskInfo() {
        var tasks = [];

        schedulerService
            .getSchedulers()
            .each((key, scheduler) => {
                var executorName = scheduler
                    .getExecutor()
                    .getName()
                    .reReplace(
                        'coldbox\.system\.web\.tasks.|-scheduler',
                        '',
                        'all'
                    );
                var moduleName = key == 'appScheduler@coldbox' ? 'global' : key.replace('cbScheduler@', '');

                scheduler
                    .getRegisteredTasks()
                    .each((taskName) => {
                        var task = scheduler.getTaskRecord(taskName);

                        tasks.append({
                            name          : taskName,
                            label         : task.task.getName(),
                            module        : moduleName,
                            executor      : executorName,
                            disabled      : task.task.isDisabled(),
                            constrained   : task.task.isConstrained(),
                            error         : task.error,
                            errorMessage  : task.errorMessage,
                            period        : task.task.getPeriod(),
                            timeUnit      : task.task.getTimeUnit(),
                            meta          : task.task.getMeta(),
                            startTime     : task.task.getStartTime(),
                            endTime       : task.task.getEndTime(),
                            stats         : task.task.getStats(),
                            group         : task.task.getGroup(),
                            debug         : task.task.getDebug(),
                            meta          : task.task.getMeta(),
                            dayOfWeek     : task.task.getDayOfTheWeek(),
                            onTaskSuccess : task.task.getOnTaskSuccess(),
                            onTaskFailure : task.task.getOnTaskFailure(),
                            serverFixation: task.task.getServerFixation(),
                            cacheName     : task.task.getCacheName(),
                            scheduled     : task.task.getScheduled()
                        });
                    });
            });

        return tasks;
    }

    /**
     * Attempt to format the incoming string to date object
     * Falls back to now() if fails
     *
     * @toFormat string that may contain a valid date
     */
    private date function formatStringToDate(required string toFormat) {
        try {
            // Remove trailing comma
            if(toFormat[toFormat.len()] == ',') {
                toFormat = toFormat.left(toFormat.len() - 1);
            }

            return dateTimeFormat(toFormat);
        }
        catch(any e) {
            return now();
        }
    }

    /**
     * Get the generation based on the pokemon's name (if regional form)
     * or by their number
     *
     * @name   Pokemon's full name (including region)
     * @number Pokedex number
     */
    private numeric function getGeneration(required string name, required numeric number) {
        var currNameSplit = listToArray(arguments.name, ' ');
        // Determine region. Use first name split if regional form, else use number
        if(currNameSplit[1] == 'Alolan') {
            return 7;
        }
        else if(currNameSplit[1] == 'Galarian') {
            return 8;
        }
        else if(currNameSplit[1] == 'Hisuian') {
            return 8.5;
        }
        else if(currNameSplit[1] == 'Paldean') {
            return 9;
        }
        else if(arguments.number <= 151) {
            return 1;
        }
        else if(arguments.number <= 251) {
            return 2;
        }
        else if(arguments.number <= 386) {
            return 3;
        }
        else if(arguments.number <= 493) {
            return 4;
        }
        else if(arguments.number <= 649) {
            return 5;
        }
        else if(arguments.number <= 721) {
            return 6;
        }
        else if(arguments.number <= 809) {
            return 7;
        }
        else if(arguments.number <= 898) {
            return 8;
        }
        else if(arguments.number <= 905) {
            return 8.5;
        }
        else if(arguments.number <= 1025) {
            return 9;
        }
        return -1; // Invalid
    }

    /**
     * Create a pokemon from db.pokemongohub.com
     *
     * @pokemonLink 
     */
    public void function createPokemon(required string pokemonLink) {
        // Fetch the pokemon page
        var pokemonDoc = scraperService.getData(arguments.pokemonLink, true).body();

        // Additional Pokedex Information Table
        var pokedexTable = pokemonDoc.select('h1##additional')[1]
            .parent()
            .nextSibling()
            .select('tr');
        // Stats table
        var statsTable = pokemonDoc.select('h3[class*=PokemonPageRenderers_inlineTitle]')[1]
            .nextSibling()
            .select('table')
            .select('tr');

        // Needed information per pokemon
        var pokemon = {
            name  : pokemonDoc.select('##overview-and-stats').text(),
            number: pokedexTable[1]
                .select('td')
                .text()
                .replace('##', '', 'all'),
            type: pokemonDoc
                .select('span[class*=officialImageTyping] > img')
                .map((img) => {
                    return img.attr('title')
                }),
            flee: parseNumber(
                pokedexTable[8]
                    .select('td')
                    .text()
                    .replace('%', '', 'all')
            ),
            catch: parseNumber(
                pokedexTable[7]
                    .select('td')
                    .text()
                    .replace('%', '', 'all')
            ),
            tradable: pokedexTable[5].select('td').text() == 'Allowed',
            attack  : reReplace(
                statsTable[2]
                    .select('td')
                    .select('strong > span > strong')
                    .text(),
                '[^0-9]',
                '',
                'all'
            ),
            defense: reReplace(
                statsTable[3]
                    .select('td')
                    .select('strong > span > strong')
                    .text(),
                '[^0-9]',
                '',
                'all'
            ),
            hp: reReplace(
                statsTable[4]
                    .select('td')
                    .select('strong > span > strong')
                    .text(),
                '[^0-9]',
                '',
                'all'
            ),
            live       : true,
            shiny      : statsTable[7].select('td').text() == 'Yes',
            generation : 0,
            shadowshiny: false,
            giga       : false,
            form       : false,
            formtype   : '',
            mega       : false,
            shadow     : false,
            gender     : '',
            sprite     : '',
            evolutions : [],
            moves      : [],
            ses        : ''
        };

        // Derived information
        pokemon.generation = getGeneration(pokemon.name, pokemon.number);

        var nameSplit = listToArray(pokemon.name, ' ');
        pokemon.mega  = nameSplit[1] == 'Mega';
        pokemon.giga  = nameSplit[1] == 'Gigantamax';
        pokemon.form  = pokemon.mega || pokemon.giga;
        if(pokemon.form || getRegionalForms().contains(nameSplit[1])) {
            pokemon.formtype = nameSplit[1];
        }
        pokemon.tradable = !(pokemon.mega || pokemon.giga);

        pokemon.sprite = '#pokemon.number#';
        if(pokemon.form) {
            pokemon.sprite &= '-#pokemon.name#';
        }
        if(pokemon.gender != '') {
            pokemon.sprite &= '-#pokemon.gender#';
        }

        // Evolutions
        var evolutionChart = pokemonDoc
            .select('div[class*=EvolutionChart_evolutionChart] > table')
            .select('tbody')
            .select('tr');
        evolutionChart.each((evolutionRow, index) => {
            var cells = evolutionRow.select('td');

            // Check if this is the current pokemon
            if(cells[1].select('a > span').text() == pokemon.name) {
                // Get the evolution
                pokemon.evolutions.push({
                    condition: '',
                    number   : cells[3]
                        .select('a')
                        .attr('href')
                        .listLast('/'),
                    cost: reReplace(
                        cells[2].select('ul > li > span').text(),
                        '[^0-9]',
                        '',
                        'all'
                    ),
                    gender : '',
                    name   : cells[3].select('a > span').text(),
                    region : '',
                    stage  : '',
                    special: false
                });
            }
        });

        // Moves
        var moveLists = pokemonDoc.select('ul[class*=PokemonPageMoves_movesList]');
        moveLists.each((list) => {
            list.select('li')
                .each((item) => {
                    var curr = uCase(
                        replace(
                            item.select('details > summary > strong[class*=MoveCard_name]').text(),
                            ' ',
                            '_'
                        )
                    );
                    if(curr.len()) pokemon.moves.push(curr);
                });
        });

        // Create ses url
        pokemon.ses = createSes(pokemon);
        addPokemon(pokemon);
        return;
    }

    /**
     * Uses the json created from createPokemon() and allows you to add the pokemon
     *
     * @jsonPokemon 
     */
    function addPokemon(required struct pokemon) {
        // Add to the overrides
        var envOverrides = deserializeJSON(fileRead('/includes/assets/envpokedexoverrides.json'));
        if(envOverrides.keyExists(pokemon.name)) {
            envOverrides.delete(pokemon.name);
        }

        envOverrides.insert(pokemon.name, pokemon);
        fileWrite(
            '/includes/assets/envpokedexoverrides.json',
            serializeJSON(envOverrides),
            'UTF-8'
        );

        // Parse the moves to add
        pokemon.moves = pokemon.moves.map((move) => {
            return {
                nameid: move,
                shadow: false,
                legacy: false
            }
        });

        updatePokemonData({'#pokemon.name#': pokemon});
        return;
    }

    /**
     * Returns query of logs from lucee and commandbox runtimes
     */
    public query function getLogs() {
        // Commandbox output logs
        var cbLogs = directoryList(
            path    : '#application.cbController.getSetting('logPath')#/../logs',
            recurse : false,
            listInfo: 'query',
            sort    : ''
        );

        // Lucee server logs
        var serverLogs = directoryList(
            path    : '#application.cbController.getSetting('logPath')#/lucee-server/context/logs',
            recurse : false,
            listInfo: 'query',
            sort    : ''
        );

        // Combine results and return
        return queryExecute(
            '
            select name, size, type, dateLastModified, attributes, mode, directory
            from cbLogs
            union
            select name, size, type, dateLastModified, attributes, mode, directory
            from serverLogs
            order by dateLastModified desc
        ',
            {},
            {dbtype: 'query'}
        );
    }

    /**
     * Read a log file and save contents
     */
    public string function readLog(
        required string filename,
        required numeric start,
        required numeric end
    ) {
        var logContent = '';

        var logFile = '';
        // Commandbox log
        if(fileExists('#application.cbController.getSetting('logPath')#/../logs/#arguments.filename#')) {
            logFile = fileOpen('#application.cbController.getSetting('logPath')#/../logs/#arguments.filename#');
        }
        // Lucee server log
        else if(
            fileExists('#application.cbController.getSetting('logPath')#/lucee-server/context/logs/#arguments.filename#')
        ) {
            logFile = fileOpen('#application.cbController.getSetting('logPath')#/lucee-server/context/logs/#arguments.filename#');
        }

        if(!isStruct(logFile)) return logContent;

        for(var i = 1; i <= arguments.end; i++) {
            if(fileIsEOF(logFile)) break;
            currLine = fileReadLine(logFile);
            if(i < arguments.start) continue;
            logContent &= '#currLine# <br>';
        }

        return logContent;
    }

    /**
     * Create unique ses url based on the pokemon's data
     *
     * @pokemon struct of pokemon data
     */
    private string function createSes(required struct pokemon) {
        // 1. number
        var ses = '#pokemon.number#';

        // 2. form
        if(pokemon.keyExists('formType') && pokemon.formType.len()) {
            ses &= '-#pokemon.formType#';
        }

        return ses;
    }

    /**
     * Return struct containing server metric information
     */
    public struct function getMetrics() {
        // JVM Memory
        var runtime  = createObject('java', 'java.lang.Runtime').getRuntime();
        var totalMem = runtime.totalMemory();
        var freeMem  = runtime.freeMemory();
        var maxMem   = runtime.maxMemory();
        var usedMem  = totalMem - freeMem;

        // CPU
        var osBean         = createObject('java', 'java.lang.management.ManagementFactory').getOperatingSystemMXBean();
        var systemCpuLoad  = '';
        var processCpuLoad = '';
        try {
            systemCpuLoad  = osBean.getSystemCpuLoad() * 100;
            processCpuLoad = osBean.getProcessCpuLoad() * 100;
        }
        catch(any e) {
        }

        var metrics = {
            timestamp: now(),
            memory   : {
                usedMB : round(usedMem / 1024 / 1024),
                totalMB: round(totalMem / 1024 / 1024),
                maxMB  : round(maxMem / 1024 / 1024)
            },
            cpu: {
                systemPercent : normalizeCPU(systemCpuLoad),
                processPercent: normalizeCPU(processCpuLoad),
                cores         : osBean.getAvailableProcessors()
            },
            concurrency: {
                activeRequests: concurrency.activeRequests,
                maxRequests   : concurrency.maxRequests,
                slowRequests  : concurrency.slowRequests
            }
        };

        return metrics;
    }

    /**
     * Reset the active requests count
     */
    public void function resetActiveRequests() {
        lock name="concurrencyLock" timeout="5" type="exclusive" throwOnTimeout=false {
            concurrency.activeRequests = 0;
        }
    }

    /**
     * Normalizes the CPU percentage
     */
    private number function normalizeCPU(any cpuVal) {
        if(!isNumeric(cpuVal)) return null;
        if(cpuVal < 0 || cpuVal > 100) return null;
        return round(cpuVal);
    }

}
