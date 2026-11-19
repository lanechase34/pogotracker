component singleton accessors="true" {

    property name="adminLog"          inject="logbox:logger:adminLog";
    property name="async"             inject="asyncManager@coldbox";
    property name="auditService"      inject="services.audit";
    property name="blogService"       inject="services.blog";
    property name="cache"             inject="cachebox:appCache";
    property name="trainerCache"      inject="cachebox:trainerCache";
    property name="customService"     inject="services.custom";
    property name="generationService" inject="services.generation";
    property name="medalService"      inject="services.medal";
    property name="moveService"       inject="services.move";
    property name="pokemonService"    inject="services.pokemon";
    property name="schedulerService"  inject="coldbox:schedulerService";
    property name="scraperService"    inject="services.scraper";
    property name="trainerService"    inject="services.trainer";
    property name="utilService"       inject="services.util";

    property name="defaultCache"  inject="cachebox:default";
    property name="templateCache" inject="cachebox:template";

    property name="concurrency"    inject="coldbox:setting:concurrency";
    property name="costumeData"    inject="coldbox:setting:costumeData";
    property name="domainProd"     inject="coldbox:setting:domainProd";
    property name="logPath"        inject="coldbox:setting:logPath";
    property name="imageExtension" inject="coldbox:setting:imageExtension";
    property name="maxThreads"     inject="coldbox:setting:maxThreads";
    property name="rootPath"       inject="coldbox:setting:rootPath";
    property name="shadowData"     inject="coldbox:setting:shadowData";
    property name="systemTrainer"  inject="coldbox:setting:systemTrainer";
    property name="writeJson"      inject="coldbox:setting:writeJson";

    property name="regionalForms" type="array";

    // The pokemon fields upsertPokemon updates on an existing pokemon - the ones a build can change
    variables.POKEMON_DIFF_FIELDS = [
        "live",
        "shiny",
        "sprite",
        "tradable",
        "shadow",
        "shadowshiny",
        "giga",
        "formtype",
        "ses"
    ];

    public void function init() {
        setRegionalForms(["Alolan", "Galarian", "Hisuian", "Paldean"]);
    }

    /**
     * Builds the pokedex.json database
     * Builds pokemon details, evolutions, moves
     */
    public void function buildPokemonData() {
        var pokedex = [];

        // Perform necessary scrapes in tandem
        var scrapes = async
            .all(
                () => {
                    return scraperService.getData("https://pokemondb.net/go/pokedex");
                },
                () => {
                    return scraperService.getData("https://pokemondb.net/go/shiny");
                },
                () => {
                    return getShadowData() ? buildShadowData() : readShadowData();
                },
                () => {
                    return scraperService.getData("https://pokemondb.net/go/evolution");
                }
            )
            .get();

        var pokedexDoc   = scrapes[1];
        var shinyDoc     = scrapes[2];
        var shadowData   = scrapes[3];
        var evolutionDoc = scrapes[4];

        // Build the pokedex
        var pokedexTable = pokedexDoc.body().select("##pokedex");

        var headerData   = pokedexTable.select("thead").select("tr")[1].select("th");
        // Map the wanted fields to the correct indices from the header row
        var wantedFields = [
            "##",
            "Name",
            "Type",
            "Attack",
            "Defense",
            "HP",
            "Catch",
            "Flee",
            "Fast Moves",
            "Charge Moves"
        ];
        var headerMap = [];
        headerData.each((th) => {
            if(wantedFields.contains(th.text())) {
                headerMap.append(th.text());
            }
            else {
                headerMap.append(""); // Insert blank spot to preserve order
            }
        });

        var bodyData = pokedexTable.select("tbody").select("tr");
        // Build the table json data
        bodyData.each(
            (tr, trindex) => {
                var rowData = tr.select("td");
                var curr    = {};

                rowData.each((td, tdindex) => {
                    var currKey = headerMap[tdindex];
                    if(!len(currKey)) return;

                    if(currKey == "##") {
                        curr.number = parseNumber(td.text(), "dec");
                    }
                    else if(
                        currKey == "Catch" || currKey == "Flee" || currKey == "Attack" || currKey == "Defense" || currKey == "HP"
                    ) {
                        var temp      = reReplace(td.text(), "[^0-9.]", "");
                        curr[currKey] = temp.len() ? parseNumber(temp) : -1;
                    }
                    else if(currKey == "Fast Moves" || currKey == "Charge Moves") {
                        var currMoves = listToArray(td.html(), "<br>", false, true);

                        if(!curr.keyExists("moves")) {
                            curr.moves = [];
                        }
                        currMoves.each((move) => {
                            // Remove spaces and HTML
                            var safe = reReplaceNoCase(move.trim(), "<[^>]*>", "", "ALL"); // remove spaces

                            // Move conditions, shadow/purified marked with $, elite tmable moves marked *, unobtainable moves marked **
                            var condition = "";
                            if(safe.findNoCase("(Shadow)")) {
                                safe      = safe.replaceNoCase(" (Shadow)", "");
                                condition = "$";
                            }
                            else if(safe.findNoCase("(Purified)")) {
                                safe      = safe.replaceNoCase(" (Purified)", "");
                                condition = "$";
                            }
                            else if(safe.findNoCase("(Community Day)")) {
                                safe      = safe.replaceNoCase(" (Community Day)", "");
                                condition = "*";
                            }
                            else if(safe.findNoCase("(Legacy)")) {
                                safe      = safe.replaceNoCase(" (Legacy)", "");
                                condition = "*";
                            }

                            // Replace all spaces, dashes, and apostrophes with underscore/blank
                            safe = uCase(
                                safe.replace(" ", "_", "ALL")
                                    .replace("-", "_", "ALL")
                                    .replace("'", "", "ALL")
                            );

                            // Edge cases and data mismatches between sources
                            if(safe.find("___")) {
                                safe = safe.replace("___", "_", "ALL");
                            }
                            if(safe == "SUPERPOWER") {
                                safe = "SUPER_POWER";
                            }
                            if(safe == "VISE_GRIP") {
                                safe = "VICE_GRIP";
                            }
                            if(safe == "TECHNO_BLAST_FIRE") {
                                safe = "TECHNO_BLAST_BURN";
                            }
                            if(safe == "TECHNO_BLAST_ELECTRIC") {
                                safe = "TECHNO_BLAST_SHOCK";
                            }
                            if(safe == "TECHNO_BLAST_WATER") {
                                safe = "TECHNO_BLAST_DOUSE";
                            }
                            if(safe == "TECHNO_BLAST_ICE") {
                                safe = "TECHNO_BLAST_CHILL";
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
            getMaxThreads()
        );

        var shinyData = {}; // map the name to whether they are shiny
        var shinyDivs = shinyDoc.body().select("div.infocard-list");

        shinyDivs.each(
            (genDiv, genIndex) => {
                var currGenData = genDiv.select("div.infocard").select("span.infocard-lg-data");
                currGenData.each((pokemonData, pokemonIndex) => {
                    var name    = pokemonData.select("a.ent-name").text();
                    var special = pokemonData.select("small")[2];
                    if(!special.select("a").len()) {
                        special = special.text();
                        if(special.findNoCase(name)) {
                            name = special;
                        }
                        else {
                            name = "#name# #special#";
                        }
                    }

                    shinyData.insert(name, pokemonData.text().findNoCase("*") > 0);
                });
            },
            true,
            getMaxThreads()
        );

        // Build the evolution data
        var evolutionData = {}; // map name -> stage, evolution, cost
        var evoLists      = evolutionDoc.body().select(".infocard-filter-block > .infocard-list-evo");

        // Handles branching evolutions
        evoLists.each(
            (evo) => {
                processEvolutionChain(evo, evolutionData);
            },
            true,
            getMaxThreads()
        );

        // Map final stage -> mega/giga mon
        var specialEvolutionMap     = {};
        var specialEvolutionPokemon = queryExecute(
            "SELECT name, number, giga 
            FROM pokemon 
            WHERE mega = true 
                OR giga = true 
            ORDER BY id ASC
            ",
            {},
            {returnType: "array"}
        );
        specialEvolutionPokemon.each((pokemon) => {
            // no regional forms have mega/giga. use number and name to get the form that should have the evolution added
            var curr = listToArray(pokemon.name, " ");

            if(!specialEvolutionMap.keyExists(curr[2])) {
                specialEvolutionMap[curr[2]] = [];
            }
            specialEvolutionMap[curr[2]].append({
                condition: pokemon.giga ? "Gigantamax Form" : "Mega Evolution",
                number   : pokemon.number,
                cost     : "",
                gender   : "",
                name     : pokemon.name,
                stage    : 0,
                special  : true
            });
        });

        var jsonPokedex = {};

        // Perform data aggregation and cleanup
        pokedex.each(
            (pokemon, index) => {
                // Turn the type list into an array
                pokemon.type = listToArray(pokemon.type, " ");

                // Properly format the name
                var currNameSplit = listToArray(pokemon.name, " ");

                pokemon.mega     = false;
                pokemon.giga     = false;
                pokemon.form     = false;
                pokemon.formtype = "";
                pokemon.gender   = "";
                // Remove the first index since that is the base pokemon name
                if(currNameSplit.len() >= 2) {
                    // Galarian Mr. Mime
                    if(currNameSplit[1] == "Mr.") {
                        if(currNameSplit.len() >= 3) {
                            currNameSplit    = arraySlice(currNameSplit, 3);
                            pokemon.name     = arrayToList(currNameSplit, " ");
                            pokemon.formtype = "Galarian";
                        }
                    }
                    // Mime Jr. OR Tapu
                    else if(currNameSplit[2] == "Jr." || currNameSplit[1] == "Tapu") {
                        pokemon.name = pokemon.name;
                    }
                    // Gender pokemon
                    else if(currNameSplit[2] == "Male" || currNameSplit[2] == "Female") {
                        pokemon.name     = currNameSplit[1];
                        pokemon.gender   = currNameSplit[2];
                        pokemon.formtype = pokemon.gender;
                    }
                    // Mega or Regional Form
                    else if(
                        currNameSplit[2] == "Mega" ||
                        currNameSplit[2] == "Primal" ||
                        getRegionalForms().contains(currNameSplit[2])
                    ) {
                        // Strip the leading name
                        currNameSplit = arraySlice(currNameSplit, 2);
                        pokemon.name  = arrayToList(currNameSplit, " ");

                        // Determine whether this pokemon is a mega
                        pokemon.mega     = currNameSplit[1] == "Mega" || currNameSplit[1] == "Primal";
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
                            || currNameSplit[1].findNoCase("Ho-Oh")
                        ) {
                            currNameSplit = arraySlice(currNameSplit, 2);
                            pokemon.name  = arrayToList(currNameSplit, " ");
                        }

                        // Handle cases where formtype comes before pokemon's name
                        if(
                            currNameSplit[2] == "Rotom"
                            || currNameSplit[2] == "Kyurem"
                        ) {
                            pokemon.formtype = currNameSplit[1];
                        }
                        // Maushold
                        else if(currNameSplit[1] == "Maushold") {
                            pokemon.formtype = currNameSplit[4];
                        }
                        else {
                            pokemon.formtype = currNameSplit[2];
                        }
                    }
                }

                // Nidoran
                if(findNoCase("Nidoran", pokemon.name)) {
                    if(pokemon.name.find("♀")) {
                        pokemon.gender = "Female";
                    }
                    else if(pokemon.name.find("♂")) {
                        pokemon.gender = "Male";
                    }
                }

                // Pokemon on this list are in the game
                pokemon.live = true;

                // assume tradable - this flag overwritten if needed
                pokemon.tradable = !(pokemon.mega || pokemon.giga);

                // Shiny data
                pokemon.shiny = false;
                if(shinyData.keyExists(pokemon.name)) {
                    pokemon.shiny = shinyData["#pokemon.name#"];
                }
                else if(shinyData.keyExists("#pokemon.name# #pokemon.gender#")) {
                    pokemon.shiny = shinyData["#pokemon.name# #pokemon.gender#"]
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
                else if(evolutionData.keyExists("#pokemon.name# #pokemon.gender#")) {
                    pokemon.evolutions = evolutionData["#pokemon.name# #pokemon.gender#"];
                }

                // Mega/Giga evolution data
                if(specialEvolutionMap.keyExists(pokemon.name)) {
                    pokemon.evolutions.append(specialEvolutionMap["#pokemon.name#"], true);
                }

                pokemon.generation = getGeneration(pokemon.name, pokemon.number);

                pokemon.sprite = "#pokemon.number#";
                if(pokemon.form) {
                    pokemon.sprite &= "-#pokemon.name#";
                }
                if(pokemon.gender != "") {
                    pokemon.sprite &= "-#pokemon.gender#";
                }

                jsonPokedex.insert(getOverrideKey(pokemon), pokemon);
            },
            true,
            getMaxThreads()
        );

        // Read in custom overrides and overwrite scraped data
        var overrides = getOverride(name = "envpokedexoverrides");
        overrides.each(
            (pokemon, custom) => {
                // Partial overrides can't create a pokemon that wasn't scraped
                if(!jsonPokedex.keyExists(pokemon) && !custom.keyExists("number")) {
                    if(!custom.keyExists("Delete")) {
                        adminLog.warn("Pokedex override [#pokemon#] matches no scraped pokemon, skipping");
                    }
                    return;
                }

                custom.each((key, value) => {
                    // If we want to remove this pokemon
                    if(key == "Delete" && value == true) {
                        if(jsonPokedex.keyExists(pokemon)) {
                            jsonPokedex.delete(pokemon);
                        }
                    }
                    else {
                        if(!jsonPokedex.keyExists(pokemon)) {
                            jsonPokedex.insert(pokemon, {});
                        }

                        if(jsonPokedex["#pokemon#"].keyExists(key)) {
                            if(key == "moves") {
                                // Only add new moves
                                value.each((move) => {
                                    if(!jsonPokedex["#pokemon#"][key].contains(move)) {
                                        jsonPokedex["#pokemon#"][key].append(move);
                                    }
                                });
                            }
                            else {
                                jsonPokedex["#pokemon#"][key] = value;
                            }
                        }
                        else {
                            jsonPokedex["#pokemon#"].insert(key, value);
                        }
                    }
                });
            },
            true,
            getMaxThreads()
        );

        jsonPokedex.each(
            (name, pokemon) => {
                // Derive SES urls
                pokemon.ses = createSes(pokemon);

                // Clean up moves - dynamax only plus moves (scraped or from an override) are dropped
                pokemon.moves = pokemon.moves
                    .filter((move) => !moveService.isDynamaxOnly(move))
                    .map((move) => {
                        // Mark which moves are shadow or legacy only
                        // Clean up nameid
                        var curr = {shadow: false, legacy: false};
                        if(move.find("*")) {
                            move        = left(move, move.len() - 1);
                            curr.legacy = true;
                        }
                        else if(move.find("$")) {
                            move        = left(move, move.len() - 1);
                            curr.shadow = true;
                        }

                        curr.nameid = move;
                        return curr;
                    });

                // Clean up duplicate evos
                var evoMap         = {};
                pokemon.evolutions = pokemon.evolutions.map((evolution) => {
                    // Account for gender evolutions
                    if(findNoCase("male", evolution.name)) {
                        evolution.name = listToArray(evolution.name, " ")[1];
                    }
                    return evolution;
                });
                pokemon.evolutions = pokemon.evolutions.filter((evolution) => {
                    // Check that this key isn't already inserted
                    var key = "#evolution.name#|#evolution.number#|#evolution.gender#";
                    if(!evoMap.keyExists(key)) {
                        evoMap[key] = true;
                        return true;
                    }
                    return false;
                });
            },
            true,
            getMaxThreads()
        );

        if(getWriteJson()) {
            utilService.writeJsonFile(
                path: "/includes/assets/pokedex.json",
                data: jsonPokedex,
                name: "pokedex"
            );
        }

        // Snapshot the current pokemon before the update so the audit can report what changed
        var pokemonDiff = utilService.diffRecords(
            keyPokemonRecords(pokemonService.findPokemon({costume: false})),
            keyPokemonRecords(jsonPokedex.keyArray().map((key) => jsonPokedex[key])),
            variables.POKEMON_DIFF_FIELDS
        );

        // Update the data
        updatePokemonData(jsonPokedex);

        auditService.auditSystem(
            event  = "adminService.buildPokemonData",
            detail = "Pulled #jsonPokedex.count()# pokemon (shadow data #getShadowData() ? "scraped" : "skipped"#). #describeDiff(pokemonDiff)#"
        );
        return;
    }

    /**
     * Scrapes the bulbapedia shadow pokemon list, saves it to shadowdata.json and audits the counts
     * On its own this only refreshes the json - buildPokemonData applies it to the pokemon
     *
     * @return {name: {number, shiny, img, check, name}}
     */
    public struct function buildShadowData() {
        var shadowDoc = scraperService.getWikiPage(
            host    = "bulbapedia.bulbagarden.net",
            page    = "List_of_Shadow_Pokémon_in_Pokémon_GO",
            apiPath = "/w/api.php"
        );

        var savedShadowCount = readShadowData().count();
        var shadowData       = {};
        var shadowTable      = shadowDoc
            .body()
            .select("table.roundy.sortable")
            .select("tbody > tr");
        shadowTable.each((tr, trindex) => {
            var rowData = tr.select("td");
            if(!rowData.len()) return;
            var curr = {};

            rowData.each((td, tdindex) => {
                if(tdindex > 3) return;

                // number
                if(tdindex == 1) {
                    curr.number = parseNumber(td.text(), "dec");
                }
                // shiny available check
                else if(tdindex == 2) {
                    var isShiny = td.select("span > a > img[alt=Shiny]");
                    curr.shiny  = isShiny.len() ? true : false;
                    curr.img    = td.select("span > span > a > img").attr("src");
                }
                // name
                else {
                    // have to check if this is a regional form
                    var check  = listToArray(listToArray(listToArray(listLast(curr.img, "/"), "-")[2], ".")[1], "");
                    curr.check = check[check.len()];

                    if(isNumeric(curr.check)) {
                        curr.name = td.text();
                    }
                    else {
                        // A - alolan, G - galarian, H - hisuian, P - paldean
                        if(curr.check == "A") {
                            curr.name = "Alolan #td.text()#";
                        }
                        else if(curr.check == "G") {
                            curr.name = "Galarian #td.text()#";
                        }
                        else if(curr.check == "H") {
                            curr.name = "Hisuian #td.text()#";
                        }
                        else if(curr.check == "P") {
                            curr.name = "Paldean #td.text()#";
                        }
                    }
                }
            });

            if(!shadowData.keyExists(curr.name)) {
                shadowData.insert(curr.name, curr);
            }
            else {
                shadowData.insert("SKIPPED#curr.name#", curr);
            }
        });

        utilService.writeJsonFile(
            path: "/includes/assets/shadowdata.json",
            data: shadowData,
            name: "shadowdata"
        );

        auditService.auditSystem(
            event  = "adminService.buildShadowData",
            detail = "Saved #shadowData.count()# shadow pokemon to shadowdata.json (was #savedShadowCount#)."
        );
        return shadowData;
    }

    /**
     * The shadow data last saved to shadowdata.json, keyed by pokemon name
     */
    private struct function readShadowData() {
        return deserializeJSON(fileRead("/includes/assets/shadowdata.json", "UTF-8"));
    }

    /**
     * Get all evolution data in this chain. The branching can occur at any point
     */
    private void function processEvolutionChain(required any evoElement, required struct evolutionData) {
        // Get direct children only (not nested ones)
        var directCards  = evoElement.select("> div.infocard");
        var directArrows = evoElement.select("> span.infocard-arrow");
        var splitElement = evoElement.select("> span.infocard-evo-split");

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
                if((data.condition == "Female" || data.condition == "Male") && chain[idx - 1].gender == "") {
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
            if(findNoCase("burmy ", chain[i - 1].name)) {
                evolutionData[chain[i - 1].name].append({
                    "condition": "Male",
                    "cost"     : 50,
                    "gender"   : "",
                    "name"     : "Mothim",
                    "number"   : 414,
                    "region"   : "",
                    "special"  : false,
                    "stage"    : 2
                });
            }
        }

        // Handle branching
        if(splitElement.len()) {
            splitElement = splitElement.first();
            var branches = splitElement.select("> div.infocard-list-evo");
            var baseCard = chain.len() > 0 ? chain[chain.len()] : null;

            branches.each((branch) => {
                var branchCards  = branch.select("div.infocard");
                var branchArrows = branch.select("span.infocard-arrow");
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
                            (data.condition == "Female" || data.condition == "Male") && branchChain.len() > 0 && branchChain[
                                branchChain.len()
                            ].gender == ""
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
        return;
    }

    /**
     * Parses the evolution cost and the conditions that need to be met card
     */
    private struct function parseEvolutionCost(required any arrow, required string pokemonName) {
        var evolutionCondition = listToArray(arrow.select("small").text(), " (", false, true);

        var cost      = pokemonName == "Gholdengo" ? 999 : parseNumber(evolutionCondition[1]);
        var condition = evolutionCondition.len() == 2 ? left(evolutionCondition[2], evolutionCondition[2].len() - 1) : "";

        return {cost: cost, condition: condition};
    }

    /**
     * Parse the current info-card 
     * We need the current stage, the number, name, gender (if applicable)
     * Handles all the special cases of name
     */
    private struct function parseCardData(required any card, required numeric stage) {
        var currData = {
            stage    : stage,
            number   : -1,
            name     : "",
            gender   : "",
            cost     : -1,
            condition: "",
            region   : "",
            special  : false
        };

        var infoDiv     = card.select(".infocard-lg-data");
        var currName    = infoDiv.select("a.ent-name").text();
        currData.number = parseNumber(replace((infoDiv.select("small")[1]).text(), "##", ""), "dec");

        if(infoDiv.select("small").len() > 2) {
            var extraInfo      = infoDiv.select("small")[2].text();
            var extraInfoSplit = listToArray(extraInfo, " ");
            var seasons        = ["Winter", "Summer", "Autumn", "Spring"];

            // Regional Check
            if(getRegionalForms().contains(extraInfoSplit[1])) {
                currData.region = extraInfoSplit[1];
            }

            // Gender check
            if(extraInfo == "Female" || extraInfo == "Male") {
                currData.gender = extraInfo;
            }

            // Deerling/Sawsbuck seasonal form check
            if(seasons.contains(extraInfoSplit[1])) {
                currName = "#currName# #extraInfo#";
            }

            // Darmanitan Check
            if(
                (extraInfoSplit.len() >= 1 && extraInfoSplit[1] == "Standard") ||
                (extraInfoSplit.len() >= 2 && extraInfoSplit[2] == "Standard")
            ) {
                currName = "#currName# Standard Mode";
            }

            // Burmy/Wormadam Check
            if(extraInfoSplit[1] == "Plant" || extraInfoSplit[1] == "Sandy" || extraInfoSplit[1] == "Trash") {
                currName = "#currName# #extraInfo#";
            }

            // Shellos/Gastrodon Check
            if(extraInfoSplit[1] == "East" || extraInfoSplit[1] == "West") {
                currName = "#currName# #extraInfo#";
            }

            // Lycanroc
            if(extraInfoSplit[1] == "Midday" || extraInfoSplit[1] == "Midnight" || extraInfoSplit[1] == "Dusk") {
                currName = "#currName# #extraInfo#";
            }

            // Gimmighoul
            if(extraInfo == "Roaming Form") {
                currName = "#currName# #extraInfo#";
            }

            // Toxtricity
            if(extraInfo == "Low Key Form" || extraInfo == "Amped Form") {
                currName = "#currName# #extraInfo#";
            }
        }

        currData.name = "#currData.region.len() ? "#currData.region# " : ""##currName##currData.gender.len() ? " #currData.gender#" : ""#";
        return currData;
    }

    /**
     * Updates the database using json pokedex
     */
    public void function updatePokemonData(required struct jsonPokedex) {
        // Create missing generations
        generationService.createAll();

        // Every move in one query, instead of a lookup per move per pokemon
        var movesByNameId = moveService.getMovesByNameId();

        // Update pokemon / create if new pokemon
        jsonPokedex.each((name, pokemon) => {
            var moves = []; // {move struct, legacy t/f, shadow t/f}
            pokemon.moves.each((move) => {
                // Moves not in the database are skipped
                if(movesByNameId.keyExists(move.nameid)) {
                    moves.append({
                        move  : movesByNameId[move.nameid],
                        shadow: move.shadow,
                        legacy: move.legacy
                    });
                }
            });

            pokemonService.upsertPokemon(
                {
                    "number"     : pokemon.number,
                    "name"       : pokemon.name,
                    "generation" : pokemon.generation,
                    "gender"     : pokemon.gender,
                    "live"       : pokemon.live,
                    "shiny"      : pokemon.shiny,
                    "type1"      : pokemon.type[1],
                    "type2"      : pokemon.type.len() == 2 ? pokemon.type[2] : "",
                    "attack"     : pokemon.attack,
                    "defense"    : pokemon.defense,
                    "hp"         : pokemon.hp,
                    "catch"      : pokemon.catch,
                    "flee"       : pokemon.flee,
                    "form"       : pokemon.form,
                    "mega"       : pokemon.mega,
                    "sprite"     : pokemon.sprite,
                    "tradable"   : pokemon.tradable,
                    "shadow"     : pokemon.shadow,
                    "shadowshiny": pokemon.shadowshiny,
                    "giga"       : pokemon.giga,
                    "formtype"   : pokemon?.formtype ?: "",
                    "ses"        : pokemon.ses,
                    "costume"    : pokemon?.costume ?: false,
                    "costumetype": pokemon?.costumetype ?: ""
                },
                moves,
                pokemon.evolutions
            );
        });

        // Flush pokemon cache and rendered detail pages
        pokemonService.clearAllCaches();

        // Cache the pokemon data
        pokemonService.getAll();
        pokemonService.getMaxStats();
        pokemonService.getSearchArray();
        return;
    }

    /**
     * The key a pokemon has in the scraped pokedex, which is also its envpokedexoverrides key
     * Gendered pokemon are "Name Gender" (Pikachu Male), except Nidoran whose name already carries the gender
     *
     * @pokemon struct with name and gender
     */
    public string function getOverrideKey(required struct pokemon) {
        var gender = arguments.pokemon.gender ?: "";
        if(gender.len() && !findNoCase("Nidoran", arguments.pokemon.name)) {
            return "#arguments.pokemon.name# #gender#";
        }
        return arguments.pokemon.name;
    }

    /**
     * Reads the levels.json and adds levels to database
     * This will need revisited once level 80 has been added
     */
    public void function buildLevels() {
        var levelMap   = deserializeJSON(fileRead("/includes/assets/levels.json", "UTF-8"));
        var levelCount = queryExecute("SELECT COUNT(*) AS total FROM level").total;
        if(levelCount == levelMap.count()) {
            auditService.auditSystem(
                event  = "adminService.buildLevels",
                detail = "Levels unchanged, #levelCount# levels in the database match levels.json."
            );
            return;
        }

        // Replace every level in one transaction so readers never see a partial table
        transaction {
            queryExecute("DELETE FROM level");
            levelMap.each((key, value) => {
                queryExecute(
                    "INSERT INTO level (level, requiredxp) VALUES (:level, :requiredxp)",
                    {level: {value: key, cfsqltype: "integer"}, requiredxp: {value: value, cfsqltype: "bigint"}}
                );
            });
        }

        auditService.auditSystem(
            event  = "adminService.buildLevels",
            detail = "Replaced #levelCount# levels with #levelMap.count()# levels from levels.json."
        );
        return;
    }

    /**
     * Builds the medal data from pokemon go wiki
     */
    public void function buildMedalData() {
        var jsonMedals = {};
        var medalDoc   = scraperService.getWikiPage(host = "pokemongo.fandom.com", page = "Medals");
        var medalTable = medalDoc.body().select("table.pogo-legacy-table");

        // Map wanted fields to the correct column indices
        var wantedFields = [
            "Name",
            "Requirement",
            "None",
            "Bronze",
            "Silver",
            "Gold",
            "Platinum"
        ];
        var headerMap  = [];
        var headerData = medalTable.select("tbody")[1].select("tr")[1].select("th");
        headerData.each((th, thindex) => {
            if(wantedFields.contains(th.text())) {
                headerMap.append(th.text());
            }
            else {
                headerMap.append(""); // Blank to preserve order
            }
        });

        // Build the table body data
        var imageStats = {fetched: 0, skipped: 0};
        var order      = 1; // track the order to display
        var tableData  = medalTable.select("tbody");
        tableData.each((tbody, bodyindex) => {
            if(bodyindex == 2) return; // unreleased medals

            var bodyData = tbody.select("tr");
            bodyData.each((tr, trindex) => {
                var rowData = tr.select("td");
                if(!rowData.len()) return;
                var curr = {order: order};

                rowData.each((td, tdindex) => {
                    // Image index
                    if(tdindex == 3) {
                        // Select the image src url
                        var imgSrc = td.select("a").attr("href");
                        if(!imgSrc.contains("https")) {
                            imageStats.skipped++;
                            return;
                        }

                        // Fetch the image through the scraper
                        // The scraped name becomes the file name - path characters are stripped
                        scraperService.downloadImage(
                            targetURL   = imgSrc,
                            destination = "/includes/images/medals/#reReplace(curr.name, "[\\/:*?""<>|]|\.\.", "", "all")#.webp"
                        );
                        imageStats.fetched++;
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

                        if(currKey == "Requirement") {
                            curr.description = td.text();
                        }
                        else {
                            // community member medal is formatted wrong on site
                            if((curr?.name ?: "") == "Community Member" || (curr?.name ?: "") == "Life of the Party") {
                                curr[currKey] = lsParseNumber(listLast(td.text(), " "));
                            }
                            else {
                                curr[currKey] = lsIsNumeric(td.text()) ? lsParseNumber(td.text()) : td.text();
                            }
                        }
                    }
                });

                if(curr.keyExists("name")) {
                    jsonMedals.insert(curr.name, curr.delete("name"));
                    order++;
                }
            });
        });

        if(getWriteJson()) {
            utilService.writeJsonFile(
                path: "/includes/assets/medals.json",
                data: jsonMedals,
                name: "medals"
            );
        }

        // Snapshot the current medals before the update so the audit can report what changed
        var currentMedals = {};
        medalService
            .getAll()
            .each((medal) => {
                currentMedals[medal.name] = medal;
            });
        var scrapedMedals = jsonMedals.map((name, medal) => {
            return {
                description : medal.description ?: "",
                bronze      : medal.bronze ?: 0,
                silver      : medal.silver ?: 0,
                gold        : medal.gold ?: 0,
                platinum    : medal.platinum ?: 0,
                displayorder: medal.order
            };
        });
        var medalDiff = utilService.diffRecords(
            currentMedals,
            scrapedMedals,
            [
                "description",
                "bronze",
                "silver",
                "gold",
                "platinum",
                "displayorder"
            ]
        );

        // Update the medal data
        updateMedalData(jsonMedals);

        auditService.auditSystem(
            event  = "adminService.buildMedalData",
            detail = "Pulled #jsonMedals.count()# medals, fetched #imageStats.fetched# images (#imageStats.skipped# skipped). #describeDiff(medalDiff)#"
        );
        return;
    }

    /**
     * Audit text for a utilService.diffRecords result - counts first, then the keys in each group
     */
    private string function describeDiff(required struct diff) {
        var detail = "Added #arguments.diff.added.len()#, changed #arguments.diff.changed.len()#, missing from source #arguments.diff.missing.len()#.";
        if(arguments.diff.added.len()) detail &= " Added: #arguments.diff.added.toList(", ")#.";
        if(arguments.diff.changed.len()) detail &= " Changed: #arguments.diff.changed.toList(", ")#.";
        if(arguments.diff.missing.len()) detail &= " Missing: #arguments.diff.missing.toList(", ")#.";
        return detail;
    }

    /**
     * Pokemon records keyed by their natural key (number, name, gender, costume type), for diffRecords
     *
     * @pokemon array of pokemon
     */
    private struct function keyPokemonRecords(required array pokemon) {
        var keyed = {};
        arguments.pokemon.each((mon) => {
            var key = reReplace(
                trim("###mon.number# #mon.name# #mon.gender ?: ""# #mon.costumetype ?: ""#"),
                "\s+",
                " ",
                "all"
            );
            keyed[key] = mon;
        });
        return keyed;
    }

    /**
     * Updates the database using the medals.json
     */
    public void function updateMedalData(required struct jsonMedals) {
        // Update medals / create if new medal
        jsonMedals.each((name, medal) => {
            medalService.upsertMedal({
                "name"        : name,
                "description" : medal.description,
                "bronze"      : medal.bronze,
                "silver"      : medal.silver,
                "gold"        : medal.gold,
                "platinum"    : medal.platinum,
                "displayorder": medal.order
            });
        });


        medalService.clearAllCache();
        return;
    }

    /**
     * Build move data from pvpoke gamemaster
     */
    public void function buildMoveData() {
        var pvppokeData = "https://pvpoke.com/data/gamemaster.min.json";
        var jsonData    = scraperService.getData(targetURL = pvppokeData, returnJSON = true);
        var jsonMoves   = deserializeJSON(jsonData).moves;


        // extra moves
        jsonMoves.append({
            "moveId"    : "HIDDEN_POWER",
            "name"      : "Hidden Power",
            "type"      : "normal",
            "power"     : 9,
            "energy"    : 0,
            "energyGain": 8,
            "cooldown"  : 1500,
            "archetype" : "Low Quality"
        });

        // Dynamax only plus moves are never imported
        jsonMoves = jsonMoves.filter((move) => !moveService.isDynamaxOnly(move.moveId));
        jsonMoves = refineMoveData(jsonMoves);
        if(getWriteJson()) {
            utilService.writeJsonFile(
                path    : "/includes/assets/moves.json",
                data    : jsonMoves,
                name    : "moves",
                keyField: "nameid"
            );
        }

        // Snapshot the current moves before the update so the audit can report what changed
        var scrapedMoves = {};
        jsonMoves.each((move) => {
            scrapedMoves[move.nameid] = move;
        });
        var moveDiff = utilService.diffRecords(
            moveService.getMovesByNameId(),
            scrapedMoves,
            [
                "name",
                "type",
                "damage",
                "energy",
                "turns",
                "buffself",
                "buffchance",
                "buffeffect"
            ]
        );

        // Update move data
        updateMoveData(jsonMoves);

        auditService.auditSystem(
            event  = "adminService.buildMoveData",
            detail = "Pulled #jsonMoves.len()# moves. #describeDiff(moveDiff)#"
        );
        return;
    }

    /**
     * Maps raw json returned to usable fields
     */
    private array function refineMoveData(required array jsonMoves) {
        return jsonMoves.map((move) => {
            var curr = {
                "nameid": move.moveId,
                "name"  : move.name,
                "type"  : move.type,
                "damage": move.power
            };

            if(move.keyExists("energyGain") && move.energyGain > 0) {
                curr.energy = move.energyGain;
                curr.turns  = move.cooldown / 500;
            }
            else {
                curr.energy = move.energy;
                curr.turns  = 0;
            }

            if(move.keyExists("buffTarget")) {
                curr.buffSelf   = move.buffTarget == "self";
                curr.buffChance = move.buffApplyChance;

                curr.buffEffect = "";
                if(move.buffs[1] != 0) {
                    curr.buffEffect &= "#move.buffs[1] > 0 ? "+" : ""##move.buffs[1]# ATK";
                }
                if(move.buffs[2] != 0) {
                    curr.buffEffect &= " #move.buffs[2] > 0 ? "+" : ""##move.buffs[2]# DEF";
                }
            }
            else {
                curr.buffSelf   = false;
                curr.buffChance = 0;
                curr.buffEffect = "";
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
            moveService.upsertMove(move);
        });

        moveService.clearCache();
        templateCache.clearEvent("pokemon.detailContent");
        return;
    }

    /**
     * Create events from leekduck - looks for upcoming pages labeled 'Event'
     *
     * @eventDaysBefore number of days before event starts to create custom pokedex
     */
    public void function createEvents(numeric eventDaysBefore = application.cbController.getSetting("eventDaysBefore")) {
        // Get the events lists
        var events = blogService.getEvents(application.cbController.getSetting("fetchCount") * 2);

        // Find events of type 'event' or 'community day' and < eventDaysBefore days away
        // Exclude 'location specific events'
        events.each((event) => {
            if(
                !event.locationSpecific
                && (event.type == "Event" || event.type == "Community Day")
                && dateDiff("d", now(), event.datatimestamp) <= eventDaysBefore
            ) {
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

        // Maps leekduck name -> pogotracker
        var leekduckNameMap = getOverride(name = "leekducknamemap");

        // Get the title and wild spawns
        var eventTitle = eventDoc
            .body()
            .select("h1.page-title")
            .text();

        var isCommunityDay = eventTitle.findNoCase("Community Day");

        var currYear = year(now());

        if(eventTitle == "Pokémon GO Wild Area: Global") {
            eventTitle = eventTitle.split(":");
            eventTitle = "#eventTitle[1]# #currYear#:#eventTitle[2]#";
        }

        // Remove shadow spawns
        var hasShadow = eventDoc.body().select("h2##shadow");
        if(hasShadow.len() == 1) {
            eventDoc.body().select("h2##shadow ~ ul.pkmn-list-flex")[1].remove();
        }

        // Remove Giovanni spawn
        var giovanni = eventDoc.body().select("h2:contains(Save Shadow)");
        if(giovanni.len() == 1) {
            eventDoc.body().select("h2###giovanni[1].id()# ~ ul.pkmn-list-flex")[1].remove();
        }

        // Remove shadow raids
        var oneStarShadow = eventDoc.body().select("h3##appearing-in-1-star-shadow-raids");
        if(oneStarShadow.len() == 1) {
            eventDoc.body().select("h3##appearing-in-1-star-shadow-raids ~ ul.pkmn-list-flex")[1].remove();
        }

        var threeStarShadow = eventDoc.body().select("h3##appearing-in-3-star-shadow-raids");
        if(threeStarShadow.len() == 1) {
            eventDoc.body().select("h3##appearing-in-3-star-shadow-raids ~ ul.pkmn-list-flex")[1].remove();
        }

        // Remove new rocket leaders
        var rocketLeaders = eventDoc.body().select("h2##team-go-rocket-leaders");
        if(rocketLeaders.len()) {
            eventDoc.body().select("h2##team-go-rocket-leaders ~ ul.pkmn-list-flex")[1].remove();
        }

        // Remove featured moves (header and everything up to the next h2)
        var featuredMoves = eventDoc.body().select("h2##featured-attacks");
        if(featuredMoves.len()) {
            var moveHeader = featuredMoves[1];
            var siblings   = moveHeader.parent().children();
            var i          = moveHeader.elementSiblingIndex() + 1;
            while(i < siblings.size() && siblings.get(i).tagName() != "h2") {
                siblings.get(i).remove();
                i++;
            }
            moveHeader.remove();
        }

        // Event Spawns
        var eventPokemon = eventDoc
            .body()
            .select(".pkmn-list-item")
            .select(".pkmn-name");

        eventPokemon.each((pokemon) => {
            spawns[pokemon.text()] = true;
            if(pokemon.text() == "Castform") {
                spawns["Castform Snowy Form"] = true;
                spawns["Castform Rainy Form"] = true;
                spawns["Castform Sunny Form"] = true;
            }
        });

        // Research task spawns
        var researchPokemon = eventDoc
            .body()
            .select("div.reward-list")
            .select("div.reward");
        researchPokemon.each((div) => {
            if(div.select("span.cp-values").len()) {
                spawns[div.select("span.reward-label").text()] = true;
            }
        });

        // Battle pass Pokemon encounters - Only include if it is a costume type
        var battlePassPokemon = eventDoc
            .body()
            .select(".battle-pass-container .reward-item:has(div.reward-image > img[src*=""pokemon_icons_crop""])");
        battlePassPokemon.each((item) => {
            var curr = item
                .select("span.reward-name")
                .text()
                .trim();
            if(leekduckNameMap.keyExists(curr) && isStruct(leekduckNameMap[curr])) {
                spawns[curr] = true;
            }
        });

        if(!spawns.count()) return;

        // Get when event starts and ends
        // Most events render separate start/end rows, single-day events render one row,
        // and multi-day events render one row per day (data-kind=day) - use the first/last rows
        var startRow = eventDoc.body().select("div.schedule-row[data-kind=start]");
        var endRow   = eventDoc.body().select("div.schedule-row[data-kind=end]");
        var allRows  = eventDoc.body().select("div.schedule-row[data-start]");

        var begins = utilService.parseDateString(
            listFirst(startRow.len() ? startRow.attr("data-start") : allRows.first().attr("data-start"), "T")
        );

        var ends = utilService.parseDateString(
            listFirst(endRow.len() ? endRow.attr("data-start") : allRows.last().attr("data-end"), "T")
        );

        // Create custom pokedex if needed
        // Use link which contains year
        var custom = customService.findByLink(eventLink);

        // Check if this event title already exists in db - if so, append the currYear to title
        var checkName = queryExecute(
            "
            SELECT 1
            FROM custom
            WHERE UPPER(link) IS DISTINCT FROM :eventLink
                AND UPPER(name) = :eventTitle
            LIMIT 1
            ",
            {
                eventLink : {value: uCase(eventLink), cfsqltype: "varchar"},
                eventTitle: {value: uCase(eventTitle), cfsqltype: "varchar"}
            }
        );

        if(checkName.recordCount) {
            eventTitle &= " #currYear#";
        }

        if(isNull(custom)) {
            var customid = customService.create(
                trainerid = trainerService.findByEmail(getSystemTrainer()).id,
                name      = eventTitle,
                isPublic  = true,
                begins    = begins,
                ends      = ends,
                link      = arguments.eventLink,
                commday   = isCommunityDay
            );
            custom = customService.getFromId(customid);

            auditService.auditSystem(event = "adminService.createEvent", detail = "Created Event: #eventTitle#");
        }
        else {
            customService.updateEvent(
                customid = custom.id,
                begins   = begins,
                ends     = ends,
                link     = arguments.eventLink
            );
        }

        // Begin event overrides
        var overrideSpawns = getOverride(name = "enveventoverrides")[eventTitle] ?: {};
        overrideSpawns.each((pokemon, override) => {
            // 1 = add, 0 = delete
            if(override && !spawns.keyExists(pokemon)) {
                spawns.insert(pokemon, true);
            }
            else if(!override) {
                spawns.delete(pokemon);
            }
        });

        var pokemon    = []; // Create array of pokemon ids
        var map        = {}; // use map to not double enter pokemon
        var addPokemon = (mon) => {
            var key = "#mon.name#|#mon.number#|#mon.gender#|#mon.costumetype#";
            if(map.keyExists(key)) return;
            pokemon.append(mon.id);
            map.insert(key, true);
        };
        spawns.each((name, value) => {
            var costumetype = "";

            // Check the name map
            if(leekduckNameMap.keyExists(name)) {
                // Check if this is a costume mon
                if(isStruct(leekduckNameMap[name])) {
                    costumetype = leekduckNameMap[name].costumetype;
                    name        = leekduckNameMap[name].name;
                }
                else {
                    name = leekduckNameMap[name];
                }
            }

            var genderCheck = listToArray(name, " ");
            if(genderCheck.len() == 2 && (genderCheck[2] == "Male" || genderCheck[2] == "Female")) {
                var currPokemon = pokemonService.findPokemon({
                    "name"       : genderCheck[1],
                    "gender"     : genderCheck[2],
                    "costume"    : costumetype.len(),
                    "costumetype": costumetype
                });
            }
            else {
                var currPokemon = pokemonService.findPokemon({
                    "name"       : name,
                    "costume"    : costumetype.len(),
                    "costumetype": costumetype
                });
            }

            // The pokemon and everything it evolves into, except special evolutions
            currPokemon.each((curr) => {
                addPokemon(curr);
                pokemonService
                    .buildEvolutionChain(curr)
                    .filter((evolution) => !evolution.special)
                    .each((evolution) => addPokemon(evolution.evolution));
            });
        });

        // Update the spawns
        customService.createCustomPokedex(custom, pokemon);

        // Detail pages list the events a pokemon was featured in
        pokemonService.clearAllDetailCaches();
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
                        "coldbox\.system\.web\.tasks.|-scheduler",
                        "",
                        "all"
                    );
                var moduleName = key == "appScheduler@coldbox" ? "global" : key.replace("cbScheduler@", "");

                scheduler
                    .getRegisteredTasks()
                    .each((taskName) => {
                        var task = scheduler.getTaskRecord(taskName);

                        tasks.append({
                            name          : taskName,
                            scheduler     : key,
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
     * Force run a Coldbox scheduled task now, bypassing disabled/constraint checks
     *
     * @scheduler Scheduler name the task is registered with
     * @name      Task name
     */
    public struct function runTask(required string scheduler, required string name) {
        var task           = schedulerService.getSchedulers()[arguments.scheduler].getTaskRecord(arguments.name).task;
        var failuresBefore = task.getStats().totalFailures;

        // Exceptions are trapped by the task itself, so detect failure through the stats
        task.run(force = true);

        var stats   = task.getStats();
        var success = stats.totalFailures == failuresBefore;
        var result  = "";

        if(success) {
            var lastResult = task.getLastResult();
            if(lastResult.isPresent()) {
                var value = lastResult.get();
                try {
                    result = isSimpleValue(value) ? value : serializeJSON(value);
                }
                catch(any e) {
                    result = "[Unserializable #getMetadata(value).name ?: "value"#]";
                }
            }
        }

        return {
            name             : arguments.name,
            success          : success,
            // App scheduler tasks record the exception message on overviewStruct in callbackOnFailure
            errorMessage     : success ? "" : (task?.overviewStruct?.message ?: "Task failed. Check the bug log for details."),
            result           : result,
            lastRun          : stats.lastRun,
            lastExecutionTime: stats.lastExecutionTime,
            totalRuns        : stats.totalRuns,
            totalSuccess     : stats.totalSuccess,
            totalFailures    : stats.totalFailures
        };
    }

    /**
     * Get the generation based on the pokemon's name (if regional form)
     * or by their number
     *
     * @name   Pokemon's full name (including region)
     * @number Pokedex number
     */
    private numeric function getGeneration(required string name, required numeric number) {
        var currNameSplit = listToArray(arguments.name, " ");
        // Determine region. Use first name split if regional form, else use number
        if(currNameSplit[1] == "Alolan") {
            return 7;
        }
        else if(currNameSplit[1] == "Galarian") {
            return 8;
        }
        else if(currNameSplit[1] == "Hisuian") {
            return 8.5;
        }
        else if(currNameSplit[1] == "Paldean") {
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
        var pokemonDoc = scraperService.getData(arguments.pokemonLink).body();

        // Additional Pokedex Information Table, keyed by row label (rows vary per pokemon)
        var pokedexInfo = {};
        pokemonDoc.select("h2##additional")[1]
            .parent()
            .nextElementSibling()
            .select("tr")
            .each((row) => {
                pokedexInfo[row.select("th").text()] = row.select("td").text();
            });
        // Stats gauges
        var statBars = pokemonDoc.select("div[class*=_pokemonStatBars]");

        // Needed information per pokemon
        var pokemon = {
            name: reReplace(
                pokemonDoc.select("##overview-and-stats").text(),
                "\s+in Pok.mon GO$",
                ""
            ),
            number: trim(
                replace(
                    pokedexInfo["Pokédex Number"] ?: "",
                    "##",
                    "",
                    "all"
                )
            ),
            type: pokemonDoc
                .select("span[class*=officialImageTyping] > img")
                .map((img) => {
                    return img.attr("title")
                }),
            flee: val(
                replace(
                    pokedexInfo["Base Flee Rate"] ?: "0",
                    "%",
                    "",
                    "all"
                )
            ),
            catch      : 0, // Base catch rate is no longer listed on the page, set manually
            tradable   : (pokedexInfo["Can be traded"] ?: "") == "Allowed",
            attack     : statBars.select("div[class*=_atk] span[class*=_amount]").text(),
            defense    : statBars.select("div[class*=_def] span[class*=_amount]").text(),
            hp         : statBars.select("div[class*=_sta] span[class*=_amount]").text(),
            live       : true,
            shiny      : (pokedexInfo["Shiny released"] ?: "") == "Yes",
            generation : 0,
            shadowshiny: false,
            giga       : false,
            form       : false,
            formtype   : "",
            mega       : false,
            shadow     : false,
            gender     : "",
            sprite     : "",
            evolutions : [],
            moves      : [],
            ses        : ""
        };

        // Derived information
        pokemon.generation = getGeneration(pokemon.name, pokemon.number);

        var nameSplit = listToArray(pokemon.name, " ");
        pokemon.mega  = nameSplit[1] == "Mega";
        pokemon.giga  = nameSplit[1] == "Gigantamax";
        pokemon.form  = pokemon.mega || pokemon.giga;
        if(pokemon.form || getRegionalForms().contains(nameSplit[1])) {
            pokemon.formtype = nameSplit[1];
        }
        pokemon.tradable = !(pokemon.mega || pokemon.giga);

        pokemon.sprite = "#pokemon.number#";
        if(pokemon.form) {
            pokemon.sprite &= "-#pokemon.name#";
        }
        else if(pokemon.formtype != "") {
            // Regional forms, e.g. 570-Hisuian
            pokemon.sprite &= "-#pokemon.formtype#";
        }
        if(pokemon.gender != "") {
            pokemon.sprite &= "-#pokemon.gender#";
        }

        // Evolutions
        var evolutionChart = pokemonDoc
            .select("div[class*=_evolutionChart] > table")
            .select("tbody")
            .select("tr");
        evolutionChart.each((evolutionRow, index) => {
            var cells = evolutionRow.select("td");
            if(cells.size() < 3) return;

            // Check if this is the current pokemon
            if(cells[1].select("a > span").text() == pokemon.name) {
                var evolutionName   = cells[3].select("a > span").text();
                var evolutionNumber = cells[3]
                    .select("a")
                    .attr("href")
                    .listLast("/");

                // Regional form evolutions link to /pokemon/{number}-{form}, e.g. /pokemon/706-Hisuian
                var evolutionForm = listFirst(evolutionName, " ");
                if(getRegionalForms().contains(evolutionForm)) {
                    evolutionNumber = reReplaceNoCase(evolutionNumber, "-#evolutionForm#$", "");
                }

                // Get the evolution
                pokemon.evolutions.push({
                    condition: "",
                    number   : evolutionNumber,
                    cost     : reReplace(
                        listFirst(cells[2].select("ul > li > small").text(), " "),
                        "[^0-9]",
                        "",
                        "all"
                    ),
                    gender : "",
                    name   : evolutionName,
                    region : "",
                    stage  : "",
                    special: false
                });
            }
        });

        // Moves
        var moveLists = pokemonDoc.select("ul[class*=_movesList]");
        moveLists.each((moveList) => {
            moveList
                .select("li")
                .each((item) => {
                    var curr = uCase(
                        replace(
                            item.select("details > summary > strong[class*=_name]").text(),
                            " ",
                            "_"
                        )
                    );
                    if(curr.len() && !moveService.isDynamaxOnly(curr)) pokemon.moves.push(curr);
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
    public void function addPokemon(required struct pokemon) {
        // Add to the overrides
        var envOverrides = getOverride(name = "envpokedexoverrides");
        if(envOverrides.keyExists(pokemon.name)) {
            envOverrides.delete(pokemon.name);
        }

        envOverrides.insert(pokemon.name, pokemon);
        saveOverride(name = "envpokedexoverrides", override = envOverrides);

        // Parse the moves to add
        pokemon.moves = pokemon.moves.map((move) => {
            return {
                nameid: move,
                shadow: false,
                legacy: false
            }
        });

        updatePokemonData({"#pokemon.name#": pokemon});
        return;
    }

    /**
     * Returns query of logs from lucee and commandbox runtimes
     *
     * @includeArchives include rotated .zip archives - they can't be previewed, so only the download all zip wants them
     */
    public query function getLogs(boolean includeArchives = false) {
        // Commandbox output logs
        var cbLogs = directoryList(
            path    : "#getLogPath()#/../logs",
            recurse : false,
            listInfo: "query",
            sort    : "",
            type    : "file"
        );

        // Lucee server logs
        var serverLogs = directoryList(
            path    : "#getLogPath()#/lucee-server/context/logs",
            recurse : false,
            listInfo: "query",
            sort    : "",
            type    : "file"
        );

        // Combine results - source names the folder each log lives in (zip subfolder)
        var logs = queryExecute(
            "
            SELECT name, size, type, dateLastModified, attributes, mode, directory, 'server' AS source
            FROM cbLogs
            UNION
            SELECT name, size, type, dateLastModified, attributes, mode, directory, 'lucee' AS source
            FROM serverLogs
            ORDER BY dateLastModified DESC
        ",
            {},
            {dbtype: "query"}
        );

        // Empty logs have nothing to show or download
        var withArchives = arguments.includeArchives;
        return logs.filter((row) => {
            return row.size > 0 && (withArchives || listLast(row.name, ".") != "zip");
        });
    }

    /**
     * Log list shaped for the viewer sidebar - formatted size and modified labels per file
     */
    public array function getLogList() {
        return getLogs().reduce((logs, row) => {
            return logs.append({
                name         : row.name,
                size         : row.size,
                sizeLabel    : utilService.formatBytes(row.size),
                modifiedLabel: dateTimeFormat(row.dateLastModified, "mmm d, h:nn tt"),
                modifiedFull : dateTimeFormat(row.dateLastModified, "mmm d, yyyy h:nn tt")
            });
        }, []);
    }

    /**
     * Absolute path of a listed log file, empty when the name isn't one of getLogs()
     * Only names from the directory listing resolve, so a crafted filename can't reach outside the log folders
     *
     * @filename log file name as shown in the log viewer
     */
    public string function resolveLogPath(required string filename) {
        var logs = getLogs();
        for(var row in logs) {
            if(row.name == arguments.filename) return "#row.directory#/#row.name#";
        }
        return "";
    }

    /**
     * Read one chunk of a log file by byte offset, cut on line boundaries so no line is split between chunks
     * Seeks straight to the offset, so reading the end of a large log costs the same as reading the start
     * Carriage returns are kept so the page can count each line's exact byte length
     *
     * @path      absolute log path from resolveLogPath
     * @offset    forward: byte to start reading at; backward: byte to stop reading at (-1 = end of file)
     * @direction forward reads toward the end of the file, backward toward the start
     * @chunkSize max bytes to read
     *
     * @return { lines, start, end, size } - start/end are the byte range the lines cover, feed them back as the next offset
     */
    public struct function readLogChunk(
        required string path,
        numeric offset    = 0,
        string direction  = "forward",
        numeric chunkSize = 65536
    ) {
        var raf = createObject("java", "java.io.RandomAccessFile").init(arguments.path, "r");
        try {
            var channel = raf.getChannel();
            var size    = channel.size();

            var start = 0;
            var end   = 0;
            if(arguments.direction == "backward") {
                end   = (arguments.offset < 0 || arguments.offset > size) ? size : arguments.offset;
                start = max(0, end - arguments.chunkSize);
            }
            else {
                start = min(max(arguments.offset, 0), size);
                end   = min(start + arguments.chunkSize, size);
            }

            if(end <= start) {
                return {
                    lines: [],
                    start: start,
                    end  : start,
                    size : size
                };
            }

            var bytes = readLogBytes(channel, start, end - start);
        }
        finally {
            raf.close();
        }

        var filled    = len(bytes);
        var latin     = bytesToLatin(bytes);
        var keepStart = 0;
        var keepEnd   = filled;

        // Mid-file chunk edges land inside a line - drop the partial line so the next read picks it up whole
        // A chunk with no usable line break (one giant line) is kept as is
        if(arguments.direction == "backward" && start > 0) {
            var firstBreak = find(chr(10), latin);
            // A break only at the very end would keep nothing and the next backward read would never move
            if(firstBreak && firstBreak < filled) keepStart = firstBreak;
        }
        else if(arguments.direction == "forward" && start + filled < size) {
            var lastBreak = find(chr(10), reverse(latin));
            if(lastBreak) keepEnd = filled - lastBreak + 1;
        }

        var text = createObject("java", "java.lang.String").init(
            bytes,
            javacast("int", keepStart),
            javacast("int", keepEnd - keepStart),
            "UTF-8"
        );
        var lines = listToArray(text, chr(10), true);
        // Trailing line break leaves an empty last field
        if(lines.len() && right(text, 1) == chr(10)) lines.deleteAt(lines.len());

        return {
            lines: lines,
            start: start + keepStart,
            end  : start + keepEnd,
            size : size
        };
    }

    /**
     * Find the next or previous case-insensitive match in a log, scanning the file in 1MB chunks
     *
     * @path       absolute log path from resolveLogPath
     * @searchText text to find
     * @offset     forward: first byte a match may start at; backward: matches must start before this byte (-1 = end of file)
     * @direction  forward or backward
     * @chunkSize  bytes scanned per read
     *
     * @return { found, offset, lineStart, size } - offset is the match's first byte, lineStart the first byte of its line
     */
    public struct function searchLog(
        required string path,
        required string searchText,
        numeric offset    = 0,
        string direction  = "forward",
        numeric chunkSize = 1048576
    ) {
        // Same one-char-per-byte form as the scanned text so match positions are byte offsets
        // Lowercasing latin-1 never changes a string's length, so positions survive it
        var needle    = lCase(charsetEncode(charsetDecode(arguments.searchText, "utf-8"), "iso-8859-1"));
        var needleLen = len(needle);
        var haystack  = "";
        var hit       = 0;
        var result    = {
            found    : false,
            offset   : -1,
            lineStart: -1,
            size     : 0
        };

        var raf = createObject("java", "java.io.RandomAccessFile").init(arguments.path, "r");
        try {
            var channel = raf.getChannel();
            var size    = channel.size();
            result.size = size;

            if(arguments.direction == "backward") {
                var end = (arguments.offset < 0 || arguments.offset > size) ? size : arguments.offset;
                while(end > 0) {
                    var start   = max(0, end - arguments.chunkSize);
                    // Read past end by needleLen - 1 so a match starting just before end is still whole
                    var readEnd = min(size, end + needleLen - 1);
                    haystack    = lCase(bytesToLatin(readLogBytes(channel, start, readEnd - start)));
                    hit         = find(reverse(needle), reverse(haystack));
                    if(hit) {
                        result.offset = start + len(haystack) - hit - needleLen + 1;
                        break;
                    }
                    end = start;
                }
            }
            else {
                var position = min(max(arguments.offset, 0), size);
                while(position < size) {
                    var length = min(arguments.chunkSize, size - position);
                    haystack   = lCase(bytesToLatin(readLogBytes(channel, position, length)));
                    hit        = find(needle, haystack);
                    if(hit) {
                        result.offset = position + hit - 1;
                        break;
                    }
                    if(position + length >= size) break;
                    // Overlap the next read so a match across the chunk edge is still found
                    position += max(1, length - needleLen + 1);
                }
            }

            if(result.offset >= 0) {
                result.found     = true;
                result.lineStart = findLineStart(channel, result.offset);
            }
        }
        finally {
            raf.close();
        }

        return result;
    }

    /**
     * First byte of the line holding position - looks back at most 64KB, past that the line is too long to matter
     */
    private numeric function findLineStart(required any channel, required numeric position) {
        var start = max(0, arguments.position - 65536);
        if(arguments.position <= start) return start;

        var latin = bytesToLatin(
            readLogBytes(
                arguments.channel,
                start,
                arguments.position - start
            )
        );
        var lastBreak = find(chr(10), reverse(latin));
        return lastBreak ? start + len(latin) - lastBreak + 1 : start;
    }

    /**
     * Read length bytes from position - fewer when the file ends first
     */
    private any function readLogBytes(
        required any channel,
        required numeric position,
        required numeric length
    ) {
        var buffer = createObject("java", "java.nio.ByteBuffer").allocate(javacast("int", arguments.length));
        var cursor = arguments.position;
        while(buffer.hasRemaining()) {
            var bytesRead = arguments.channel.read(buffer, javacast("long", cursor));
            if(bytesRead <= 0) break;
            cursor += bytesRead;
        }

        var bytes = buffer.array();
        if(buffer.position() == arguments.length) return bytes;
        return createObject("java", "java.util.Arrays").copyOf(bytes, javacast("int", buffer.position()));
    }

    /**
     * ISO-8859-1 maps every byte to one char, so string positions are byte positions
     */
    private string function bytesToLatin(required any bytes) {
        return createObject("java", "java.lang.String").init(arguments.bytes, "ISO-8859-1");
    }

    /**
     * Zip every log (rotated .zip archives included) into the temp directory, server/ and lucee/ subfolders keep same-named logs apart
     * Logs are copied first so files still being written are archived as a consistent snapshot
     *
     * @return absolute path of the zip - the caller is responsible for deleting it
     */
    public string function zipLogs() {
        var workDir = "#getTempDirectory()#/logs-#createUUID()#";
        var zipPath = "#workDir#.zip";
        directoryCreate("#workDir#/server", true, true);
        directoryCreate("#workDir#/lucee", true, true);

        try {
            for(var row in getLogs(includeArchives = true)) {
                fileCopy("#row.directory#/#row.name#", "#workDir#/#row.source#/#row.name#");
            }
            cfzip(
                action    = "zip",
                file      = zipPath,
                source    = workDir,
                recurse   = true,
                overwrite = true
            );
        }
        catch(any e) {
            if(fileExists(zipPath)) fileDelete(zipPath);
            rethrow;
        }
        finally {
            directoryDelete(workDir, true);
        }

        return zipPath;
    }

    /**
     * Copy one log to the temp directory so it downloads as a snapshot
     * Streaming the live file breaks the download when the log grows past the content-length sent up front
     *
     * @path absolute log path from resolveLogPath
     *
     * @return absolute path of the copy - the caller is responsible for deleting it
     */
    public string function snapshotLog(required string path) {
        var name = getFileFromPath(arguments.path);
        // sendFile takes the extension from everything after the last dot in the path - give extensionless logs one
        if(!name.find(".")) name &= ".log";
        var copyPath = "#getTempDirectory()#/log-#createUUID()#-#name#";
        fileCopy(arguments.path, copyPath);
        return copyPath;
    }

    /**
     * Create unique ses url based on the pokemon's data
     *
     * @pokemon struct of pokemon data
     */
    private string function createSes(required struct pokemon) {
        // 1. number
        var ses = "#pokemon.number#";

        // 2. form
        if(pokemon.keyExists("formType") && pokemon.formType.len()) {
            ses &= "-#pokemon.formType#";
        }

        // 3. costume
        if(pokemon.keyExists("costumetype") && pokemon.costumetype.len()) {
            ses &= "-#pokemon.costumetype#";
        }

        // 4. Replace special characters
        ses = replaceNoCase(ses, "%", "Percent", "all");
        return ses;
    }

    /**
     * Return struct containing server metric information
     */
    public struct function getMetrics() {
        // JVM Memory
        var runtime  = createObject("java", "java.lang.Runtime").getRuntime();
        var totalMem = runtime.totalMemory();
        var freeMem  = runtime.freeMemory();
        var maxMem   = runtime.maxMemory();
        var usedMem  = totalMem - freeMem;

        // CPU
        var osBean         = createObject("java", "java.lang.management.ManagementFactory").getOperatingSystemMXBean();
        var systemCpuLoad  = "";
        var processCpuLoad = "";
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

    /**
     * Rebuilds /includes/sitemap.xml with every public, indexable page: home, the Pokedex index, pokemon detail pages, and blogs
     *
     * lastmod is the real last change from the db so search engines can trust it:
     * - detail page: newest update across the pokemon, its moves, its evolutions, and its live costumes
     * - Pokedex index: newest of all detail pages
     * - blog: updated, falling back to created
     * - home: omitted - its content is client rendered, so there is no meaningful date
     */
    public void function updateSiteMap() {
        var filePath = "#getRootPath()#/includes/sitemap.xml";
        var domain   = getDomainProd();
        var entries  = [];
        var w3cDate  = (value) => isDate(value) ? dateFormat(value, "yyyy-mm-dd") : "";

        // Pokemon detail pages - greatest() skips nulls, so a pokemon without moves/evolutions/costumes uses its own date
        var pokemonRows = queryExecute(
            "
            SELECT pokemon.ses, pokemon.name, pokemon.sprite,
                GREATEST(pokemon.updated, moves.updated, evolutions.updated, costumes.updated) AS lastmod
            FROM pokemon
            LEFT JOIN (
                SELECT pokemonid, MAX(updated) AS updated
                FROM pokemonmove
                GROUP BY pokemonid
            ) AS moves ON moves.pokemonid = pokemon.id
            LEFT JOIN (
                SELECT id, MAX(updated) AS updated
                FROM (
                    SELECT pokemonid AS id, updated FROM evolution
                    UNION ALL
                    SELECT evolutionid AS id, updated FROM evolution
                ) AS evolutionsides
                GROUP BY id
            ) AS evolutions ON evolutions.id = pokemon.id
            LEFT JOIN (
                SELECT name, number, gender, MAX(updated) AS updated
                FROM pokemon
                WHERE costume = true
                    AND live = true
                GROUP BY name, number, gender
            ) AS costumes ON costumes.name = pokemon.name AND costumes.number = pokemon.number AND costumes.gender = pokemon.gender
            WHERE pokemon.costume = false
            ORDER BY pokemon.generation ASC, pokemon.number ASC, pokemon.form ASC, pokemon.name ASC
            ",
            {},
            {returnType: "array"}
        );

        var newestPokemon = pokemonRows.reduce((newest, row) => {
            return isDate(row.lastmod)
            && (
                !isDate(newest)
                || dateCompare(row.lastmod, newest) > 0
            )
             ? row.lastmod
             : newest;
        }, "");

        var pokemonEntries = pokemonRows.map((row) => {
            return {
                loc       : "#domain#/pokemon/#row.ses#",
                lastmod   : w3cDate(row.lastmod),
                changefreq: "monthly",
                priority  : "0.8",
                image     : {loc: "#domain#/includes/images/sprites/#encodeForURL(row.sprite)##getImageExtension()#"}
            };
        });

        entries.append({
            loc       : "#domain#/",
            lastmod   : "",
            changefreq: "weekly",
            priority  : "1.0"
        });

        entries.append({
            loc       : "#domain#/pokemon",
            lastmod   : w3cDate(newestPokemon),
            changefreq: "weekly",
            priority  : "0.9"
        });

        entries.append(pokemonEntries, true);

        // Blog pages
        entries.append(
            queryExecute(
                "
                SELECT header, COALESCE(updated, created) AS lastmod
                FROM blog
                ORDER BY created DESC
                ",
                {},
                {returnType: "array"}
            ).map((row) => {
                return {
                    loc       : "#domain##blogService.getReadPath(header = row.header)#",
                    lastmod   : w3cDate(row.lastmod),
                    changefreq: "monthly",
                    priority  : "0.7"
                };
            }),
            true
        );

        // Build sitemap as a string so we can use the image namespace without
        var lines = [];
        lines.append("<?xml version=""1.0"" encoding=""UTF-8""?>");
        lines.append("<urlset xmlns=""http://www.sitemaps.org/schemas/sitemap/0.9""");
        lines.append("        xmlns:image=""http://www.google.com/schemas/sitemap-image/1.1"">");

        entries.each((entry) => {
            lines.append("  <url>");
            lines.append("    <loc>#encodeForXML(entry.loc)#</loc>");
            if(entry.lastmod.len()) lines.append("    <lastmod>#entry.lastmod#</lastmod>");
            lines.append("    <changefreq>#entry.changefreq#</changefreq>");
            lines.append("    <priority>#entry.priority#</priority>");
            if(entry.keyExists("image")) {
                lines.append("    <image:image>");
                lines.append("      <image:loc>#encodeForXML(entry.image.loc)#</image:loc>");
                lines.append("    </image:image>");
            }
            lines.append("  </url>");
        });

        lines.append("</urlset>");

        fileWrite(filePath, lines.toList(chr(10)), "UTF-8");

        auditService.auditSystem(
            event  = "adminService.updateSiteMap",
            detail = "Sitemap updated with #entries.len()# urls"
        );
        return;
    }

    /**
     * Builds the costume data
     */
    public void function buildCostumeData() {
        var costumes   = deserializeJSON(fileRead("/includes/assets/costumes.json", "UTF-8"));
        var imageStats = {
            fetched     : 0,
            shinyFetched: 0,
            existing    : 0
        };

        if(getCostumeData()) {
            costumes = {};
            var doc  = scraperService.getWikiPage(host = "pokemongo.fandom.com", page = "Event_Pokémon");

            // The page holds both tables in one poketab widget
            // First content pane is the regular
            // Second is the shiny
            var pokeTab = doc.body().selectFirst("div.poketab");
            if(isNull(pokeTab)) throw("Unable to locate the poketab container on the event Pokemon page");

            var tabPanes = pokeTab.select("div.wds-tab__content");
            if(tabPanes.size() LT 2) throw("Unable to locate both the regular and shiny tab panes");

            var regularPane = tabPanes.get(0);
            var shinyPane   = tabPanes.get(1);

            var items = regularPane.select(".pogo-list-container").select(".pogo-list-item");

            items.each((item, idx) => {
                var curr    = extractCostumeData(item);
                var costume = curr.fullcostume;

                curr = {
                    number     : curr.number,
                    name       : curr.name,
                    costume    : true,
                    costumetype: curr.costumetype,
                    sprite     : curr.filename,
                    shiny      : false,
                    spriteSrc  : curr.imgSrc,
                    generation : getGeneration(curr.name, curr.number),
                    released   : true,
                    live       : !curr.greyedOut,
                    flee       : 0,
                    catch      : 0,
                    shadowshiny: false,
                    giga       : false,
                    evolutions : [],
                    form       : false,
                    mega       : false,
                    attack     : 0,
                    hp         : 0,
                    shadow     : false,
                    gender     : "",
                    tradable   : true,
                    type       : ["Normal"],
                    formtype   : "",
                    ses        : curr.ses,
                    moves      : [],
                    defense    : 0
                };

                costumes[curr.ses] = curr;
            });

            var shinyItems = shinyPane.select(".pogo-list-container").select(".pogo-list-item");

            shinyItems.each((item, idx) => {
                var curr = extractCostumeData(item);

                // Error in table on wiki side
                if(!costumes.keyExists(curr.ses)) return;

                costumes[curr.ses].shinySpriteSrc = curr.imgSrc;
                costumes[curr.ses].shinyGreyedOut = curr.greyedOut;
            });

            // Delete keys
            costumes.delete("150-2017-Yokohama-Stadium-1");
            costumes.delete("26-Detective-2023");
            costumes.delete("25-Detective-2023");

            // Download images
            costumes.each((key, costume) => {
                var normalSprite = costume?.spriteSrc ?: "";
                var shinySprite  = costume?.shinySpriteSrc ?: "";

                // Normal sprite
                var spritePath = "/includes/images/sprites/#costume.sprite##getImageExtension()#";
                if(len(normalSprite) && normalSprite.startsWith("http")) {
                    if(fileExists("#getRootPath()##spritePath#")) {
                        imageStats.existing++;
                    }
                    else {
                        scraperService.downloadImage(targetURL = normalSprite, destination = spritePath);
                        imageStats.fetched++;
                    }
                }

                // Determine if this has a shiny
                if(shinySprite.findNoCase("none") || (costume?.shinyGreyedOut ?: false)) {
                    costume.shiny = false;
                }
                else {
                    costume.shiny = true;
                }

                // Shiny sprite
                var shinySpritePath = "/includes/images/shinysprites/#costume.sprite##getImageExtension()#";
                if(costume.shiny && len(shinySprite) && shinySprite.startsWith("http")) {
                    if(fileExists("#getRootPath()##shinySpritePath#")) {
                        imageStats.existing++;
                    }
                    else {
                        scraperService.downloadImage(targetURL = shinySprite, destination = shinySpritePath);
                        imageStats.shinyFetched++;
                    }
                }

                costume.delete("spriteSrc");
                costume.delete("shinySpriteSrc");
                costume.delete("shinyGreyedOut");
            });

            // Determine the evolution lines based on existing evolution and using the costume type
            costumes.each((key, costume) => {
                var pokemon = pokemonService.findPokemon({
                    name   : costume.name,
                    number : costume.number,
                    gender : costume.gender,
                    costume: false
                });

                if(!pokemon.len()) return;

                var evolutions = pokemonService.getEvolution(pokemon[1]);
                if(!evolutions.len()) return;

                // Check if evolution(s) has the same costume type
                evolutions.each((evolution) => {
                    var evolvedMon = evolution.evolution;

                    // Search costume records
                    var evolvedCostume = costumes.filter((key, filterCostume) => {
                        return (
                            filterCostume.name == evolvedMon.name
                            && filterCostume.number == evolvedMon.number
                            && filterCostume.gender == evolvedMon.gender
                            && filterCostume.costumeType == costume.costumeType // match base stage
                            && !evolvedMon.mega
                            && !evolvedMon.giga
                            && !evolvedMon.formtype.len()
                        );
                    });

                    if(!evolvedCostume.count()) return;

                    // Add to evolutions
                    evolvedCostume.each((key, eCostume) => {
                        costume.evolutions.append({
                            condition  : "",
                            number     : eCostume.number,
                            gender     : eCostume.gender,
                            cost       : evolution.cost,
                            name       : eCostume.name,
                            special    : false,
                            costume    : true,
                            costumetype: eCostume.costumeType
                        });
                    });
                });
            });

            // Stable evolution order - name, then gender, then costume type
            costumes.each((key, costume) => {
                costume.evolutions.sort((a, b) => {
                    var nameCompare = compareNoCase(a.name, b.name);
                    if(nameCompare != 0) return nameCompare;
                    var genderCompare = compareNoCase(a.gender, b.gender);
                    return genderCompare != 0 ? genderCompare : compareNoCase(a.costumetype, b.costumetype);
                });
            });
        }

        if(getWriteJson()) {
            utilService.writeJsonFile(
                path: "/includes/assets/costumes.json",
                data: costumes,
                name: "costumes"
            );
        }

        // Snapshot the current costumes before the update so the audit can report what changed
        var costumeDiff = utilService.diffRecords(
            keyPokemonRecords(pokemonService.findPokemon({costume: true})),
            keyPokemonRecords(costumes.keyArray().map((key) => costumes[key])),
            variables.POKEMON_DIFF_FIELDS
        );

        updatePokemonData(costumes);

        var source = getCostumeData() ? "scraped from wiki" : "read from costumes.json";
        auditService.auditSystem(
            event  = "adminService.buildCostumeData",
            detail = "Pulled #costumes.count()# costumes (#source#), fetched #imageStats.fetched# sprites and #imageStats.shinyFetched# shiny sprites (#imageStats.existing# already on disk). #describeDiff(costumeDiff)#"
        );
        return;
    }

    /**
     * Extract the custom data from the jsoup pogo-list-item object
     *
     * @item jsoup selected item
     */
    private struct function extractCostumeData(required any item) {
        var nameEl = item.selectFirst(".pogo-list-item-name");
        var numEl  = item.selectFirst(".pogo-list-item-number");
        var formEl = item.selectFirst(".pogo-list-item-form");

        if(isNull(nameEl) || isNull(numEl)) return;

        var name    = trim(nameEl.text());
        var costume = isNull(formEl) ? "" : trim(formEl.text());

        var number = val(reReplace(numEl.text(), "[^0-9]", "", "all"));

        // Every cell carries both an -image-r and -image-s sprite, but which slot actually holds the costume's own sprite isn't reliable
        // The other slot is just the base/default sprite for reference
        // The costume-specific filename always has more underscores so pick whichever side has more, regardless of which -r/-s slot it's in
        var rSrc = resolveImgSrc(item.selectFirst(".pogo-list-item-image-r img"));
        var sSrc = resolveImgSrc(item.selectFirst(".pogo-list-item-image-s img"));

        var rUnderscores = len(rSrc) - len(replace(rSrc, "_", "", "all"));
        var sUnderscores = len(sSrc) - len(replace(sSrc, "_", "", "all"));

        var imgSrc = rSrc;
        if(len(sSrc) && (sUnderscores > rUnderscores || !len(rSrc))) {
            imgSrc = sSrc;
        }

        var safeCostume = reReplace(costume, "[^A-Za-z0-9]+", "-", "all");
        safeCostume     = reReplace(safeCostume, "(^-+|-+$)", "", "all");
        var fileName    = "#number#_#name#_#safeCostume#";

        var curr = {
            number     : number,
            name       : name,
            costume    : true,
            costumetype: safeCostume,
            fullcostume: costume,
            filename   : filename,
            imgSrc     : imgSrc,
            greyedOut  : item.hasClass("greyed-out")
        };

        // Build ses using safe costume name, then replace to full costume
        curr.ses         = createSes(curr);
        curr.costumetype = utilService.capitalizeWords(costume);
        return curr;
    }

    /**
     * Resolves the full-resolution image url from a jsoup img element
     *
     * @imgEl jsoup selected img element (may be null)
     */
    private string function resolveImgSrc(any imgEl) {
        if(isNull(imgEl)) return "";

        // Lazy rows store the real url in data-src and a base64 placeholder in src - eager rows store it directly in src
        var dataSrc = imgEl.attr("data-src");
        var src     = imgEl.attr("src");
        var imgSrc  = len(dataSrc) && dataSrc.startsWith("http") ? dataSrc : src;

        // Pull full resolution instead of the 98px thumbnail
        return reReplace(imgSrc, "/scale-to-width-down/[0-9]+", "", "one");
    }

    /**
     * Returns detailed information the current cache state
     * Includes list of all keys stored in coldbox, rate, and ws caches
     */
    public struct function getCacheData() {
        var stats = cache.getStats();

        var cacheData    = formatCacheData(cache, "appCache");
        var trainerData  = formatCacheData(trainerCache, "trainerCache");
        var defaultData  = formatCacheData(defaultCache, "defaultCache");
        var templateData = formatCacheData(templateCache, "templateCache");

        var data = cacheData
            .append(trainerData, true)
            .append(defaultData, true)
            .append(templateData, true);

        var info = {
            lastReapDateTime  : stats.getLastReapDateTime(),
            hits              : stats.getHits(),
            misses            : stats.getMisses(),
            evictionCount     : stats.getEvictionCount(),
            garbageCollections: stats.getGarbageCollections(),
            maxObjects        : cache.getConfiguration().maxObjects,
            data              : data
        };

        return info;
    }

    /**
     * Format the data stored in the cached passed in
     * Returns an array of structs
     *
     * @cacheInstance cache instance
     * @name          what the cache is called
     */
    private array function formatCacheData(required component cacheInstance, required string name) {
        var data = cacheInstance.getCachedObjectMetadataMulti(cacheInstance.getKeys().toList(","));

        return data.reduce((result, key, value) => {
            return result.append({
                id               : key,
                key              : key,
                created          : dateTimeFormat(value.created, "long"),
                hits             : value.hits,
                expired          : value.isExpired,
                lastaccessed     : dateTimeFormat(value.lastAccessed, "long"),
                lastaccesstimeout: value.lastAccessTimeout,
                timeout          : value.timeout,
                storage          : name
            });
        }, []);
    }

    /**
     * Save override json to the db
     *
     * @name     The key's name
     * @override The override struct
     */
    public void function saveOverride(required string name, required struct override) {
        // Create or replace in one statement - one row per name
        queryExecute(
            "
            INSERT INTO overrides (name, override)
            VALUES (:name, CAST(:override AS jsonb))
            ON CONFLICT (name) DO UPDATE SET override = excluded.override
            ",
            {
                name    : {value: arguments.name, cfsqltype: "varchar"},
                override: {value: serializeJSON(arguments.override), cfsqltype: "varchar"}
            }
        );
        return;
    }

    /**
     * Get the override json value
     *
     * @name The key's name
     */
    public struct function getOverride(required string name) {
        var override = queryExecute(
            "SELECT override FROM overrides WHERE name = :name",
            {name: {value: arguments.name, cfsqltype: "varchar"}}
        );

        if(!override.recordCount) {
            return {};
        }

        return deserializeJSON(override.override);
    }

}
