component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        jsoup = getInstance("javaloader:org.jsoup.Jsoup");

        seedOverrides = deserializeJSON(
            fileRead(expandPath("/root/database/seeds/resources/pokedexoverrides.json"), "UTF-8")
        );

        // Every field updatePokemonData and the build's cleanup read - an override that creates a pokemon must carry them all
        requiredFields = [
            "number",
            "name",
            "generation",
            "gender",
            "live",
            "shiny",
            "type",
            "attack",
            "defense",
            "hp",
            "catch",
            "flee",
            "form",
            "mega",
            "giga",
            "sprite",
            "tradable",
            "shadow",
            "shadowshiny",
            "moves",
            "evolutions"
        ];

        // One build shared by the merge specs - each reads a different pokemon from it
        built = buildWith(
            scrapedRows(),
            {
                "Bulbasaur": {
                    "shiny"  : true,
                    "live"   : false,
                    "costume": false,
                    "moves"  : ["TACKLE", "FRENZY_PLANT*", "RETURN$", "SURF+"]
                },
                "Ivysaur"        : {"delete": true},
                "Frillish Female": {"shiny": true},
                // Base name of a gendered pokemon - the scraped key is "Frillish Female"
                "Frillish"       : {"tradable": false},
                "Ghostmon"       : {"shiny": true},
                "Gonemon"        : {"delete": true},
                "Snom"           : duplicate(seedOverrides["Snom"])
            }
        );
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * A fresh admin service, not the app's singleton, with the scrapes served from the pages given
     * updatePokemonData is stubbed so nothing is written - read what it was handed from its call log
     *
     * @scraped   rows for the pokedex table, each {number, name, type, attack, defense, hp, fast, charge}
     * @overrides the envpokedexoverrides struct the build reads
     */
    private any function buildWith(required array scraped, required struct overrides) {
        var adminService = freshAdmin();

        var pages = {
            "https://pokemondb.net/go/pokedex"  : pokedexPage(arguments.scraped),
            "https://pokemondb.net/go/shiny"    : "<html><body></body></html>",
            "https://pokemondb.net/go/evolution": "<html><body></body></html>"
        };
        var jsoupParser = variables.jsoup;
        var scraper     = createEmptyMock("models.services.scraper")
            .$(method = "getData", preserveArguments = true)
            .$callback((required string targetURL, boolean returnJSON = false) => {
                if(!pages.keyExists(arguments.targetURL)) {
                    throw(type = "MissingFixture", message = "No page for #arguments.targetURL#");
                }
                return jsoupParser.parse(pages[arguments.targetURL], arguments.targetURL);
            });

        adminService.setScraperService(scraper);
        // Shadow data comes from includes/assets/shadowdata.json instead of bulbapedia
        adminService.setShadowData(false);
        adminService.setWriteJson(false);
        adminService.$("updatePokemonData");
        adminService.$(method = "getOverride", returns = arguments.overrides);

        adminService.buildPokemonData();

        var calls = adminService.$callLog().updatePokemonData;
        expect(calls.len()).toBe(1);
        return calls[1][1];
    }

    /**
     * A new admin service wired like the app's, but not the singleton - safe to mock
     */
    private any function freshAdmin() {
        var adminService = new models.services.admin();
        application.wirebox.autowire(target = adminService, targetID = "tests.pokedexOverridesAdmin");
        return prepareMock(adminService);
    }

    /**
     * Run buildMoveData on a fresh admin service with pvpoke serving the moves given
     * updateMoveData is stubbed so nothing is written - returns the moves it was handed
     *
     * @pvpokeMoves gamemaster moves, each {moveId, name, type, power, energy, energyGain, cooldown}
     */
    private array function buildMovesWith(required array pvpokeMoves) {
        var adminService = freshAdmin();
        var gamemaster   = serializeJSON({moves: arguments.pvpokeMoves});
        var scraper      = createEmptyMock("models.services.scraper")
            .$(method = "getData", preserveArguments = true)
            .$callback((required string targetURL, boolean returnJSON = false) => {
                if(arguments.targetURL != "https://pvpoke.com/data/gamemaster.min.json") {
                    throw(type = "MissingFixture", message = "No page for #arguments.targetURL#");
                }
                return gamemaster;
            });

        adminService.setScraperService(scraper);
        adminService.setWriteJson(false);
        adminService.$("updateMoveData");

        adminService.buildMoveData();

        var calls = adminService.$callLog().updateMoveData;
        expect(calls.len()).toBe(1);
        return calls[1][1];
    }

    private struct function pvpokeMove(required string moveId, required string name) {
        return {
            "moveId"    : arguments.moveId,
            "name"      : arguments.name,
            "type"      : "water",
            "power"     : 65,
            "energy"    : 40,
            "energyGain": 0,
            "cooldown"  : 500
        };
    }

    /**
     * A pokemondb go pokedex page with just the columns the build reads
     */
    private string function pokedexPage(required array rows) {
        var body = arguments.rows
            .map((row) => {
                return "<tr><td>#row.number#</td><td>#row.name#</td><td>#row.type#</td><td>#row.attack#</td><td>#row.defense#</td><td>#row.hp#</td><td>20%</td><td>10%</td><td>#row.fast#</td><td>#row.charge#</td></tr>";
            })
            .toList("");

        return "<html><body><table id=""pokedex""><thead><tr>"
        & "<th>##</th><th>Name</th><th>Type</th><th>Attack</th><th>Defense</th><th>HP</th>"
        & "<th>Catch</th><th>Flee</th><th>Fast Moves</th><th>Charge Moves</th>"
        & "</tr></thead><tbody>#body#</tbody></table></body></html>";
    }

    private array function scrapedRows() {
        return [
            {
                number : 1,
                name   : "Bulbasaur",
                type   : "Grass Poison",
                attack : 118,
                defense: 111,
                hp     : 128,
                fast   : "Vine Whip<br>Tackle",
                charge : "Sludge Bomb<br>Seed Bomb<br>Seed Bomb+"
            },
            {
                number : 2,
                name   : "Ivysaur",
                type   : "Grass Poison",
                attack : 151,
                defense: 143,
                hp     : 155,
                fast   : "Vine Whip",
                charge : "Power Whip"
            },
            {
                number : 25,
                name   : "Pikachu",
                type   : "Electric",
                attack : 112,
                defense: 96,
                hp     : 111,
                fast   : "Thunder Shock",
                charge : "Wild Charge"
            },
            {
                number : 592,
                name   : "Frillish Female",
                type   : "Water Ghost",
                attack : 115,
                defense: 134,
                hp     : 146,
                fast   : "Bubble",
                charge : "Night Shade"
            }
        ];
    }

    private array function moveIds(required struct pokemon) {
        return arguments.pokemon.moves.map((move) => move.nameid);
    }

    function run() {
        describe("buildPokemonData applying envpokedexoverrides", () => {
            it("Overwrites scraped fields with the override's values", () => {
                expect(built["Bulbasaur"].shiny).toBeTrue();
                expect(built["Bulbasaur"].live).toBeFalse();
            });

            it("Keeps the scraped fields the override doesn't name", () => {
                expect(built["Bulbasaur"].number).toBe(1);
                expect(built["Bulbasaur"].attack).toBe(118);
                expect(built["Bulbasaur"].type).toBe(["Grass", "Poison"]);
                expect(built["Bulbasaur"].tradable).toBeTrue();
            });

            it("Adds fields the scrape doesn't have", () => {
                expect(built["Bulbasaur"]).toHaveKey("costume");
                expect(built["Bulbasaur"].costume).toBeFalse();
            });

            it("Adds override moves without duplicating scraped ones", () => {
                var ids = moveIds(built["Bulbasaur"]);
                expect(ids.filter((id) => id == "TACKLE").len()).toBe(1);
                expect(ids).toInclude("VINE_WHIP");
                expect(ids).toInclude("SLUDGE_BOMB");
                expect(ids).toInclude("SEED_BOMB");
                expect(ids).toInclude("FRENZY_PLANT");
                expect(ids).toInclude("RETURN");
            });

            it("Marks override moves ending * as legacy and $ as shadow", () => {
                var moves = {};
                built["Bulbasaur"].moves.each((move) => moves[move.nameid] = move);

                expect(moves["FRENZY_PLANT"].legacy).toBeTrue();
                expect(moves["FRENZY_PLANT"].shadow).toBeFalse();
                expect(moves["RETURN"].shadow).toBeTrue();
                expect(moves["RETURN"].legacy).toBeFalse();
                expect(moves["TACKLE"].legacy).toBeFalse();
            });

            it("Drops dynamax only plus moves, scraped or from an override", () => {
                var ids = moveIds(built["Bulbasaur"]);
                expect(ids).notToInclude("SURF+");
                expect(ids).notToInclude("SEED_BOMB+");
                // The plain move of the same name is kept
                expect(ids).toInclude("SEED_BOMB");
            });

            it("Removes a scraped pokemon marked delete (lowercase, as the saved json has it)", () => {
                expect(built).notToHaveKey("Ivysaur");
            });

            it("Ignores delete for a pokemon that wasn't scraped", () => {
                expect(built).notToHaveKey("Gonemon");
            });

            it("Applies a gendered pokemon's override under its name and gender key", () => {
                expect(built["Frillish Female"].shiny).toBeTrue();
                expect(built["Frillish Female"].name).toBe("Frillish");
                expect(built["Frillish Female"].gender).toBe("Female");
            });

            it("Doesn't create a pokemon from a partial override that matches nothing scraped", () => {
                expect(built).notToHaveKey("Ghostmon");
                // The base name override neither creates "Frillish" nor leaks onto "Frillish Female"
                expect(built).notToHaveKey("Frillish");
                expect(built["Frillish Female"].tradable).toBeTrue();
            });

            it("Creates a pokemon from a full override (one with a number)", () => {
                expect(built).toHaveKey("Snom");
                var snom = built["Snom"];
                expect(snom.number).toBe(872);
                expect(snom.name).toBe("Snom");
                expect(snom.ses).toBe("872");
                expect(moveIds(snom)).toInclude("POWDER_SNOW");
                expect(snom.evolutions.len()).toBe(1);
                expect(snom.evolutions[1].name).toBe("Frosmoth");
            });

            it("Leaves pokemon without an override as scraped", () => {
                var pikachu = built["Pikachu"];
                expect(pikachu.live).toBeTrue();
                expect(pikachu.shiny).toBeFalse();
                expect(moveIds(pikachu)).toBe(["THUNDER_SHOCK", "WILD_CHARGE"]);
            });

            it("Builds with no overrides saved", () => {
                var plain = buildWith(scrapedRows(), {});
                expect(plain.count()).toBe(4);
                [
                    "Bulbasaur",
                    "Ivysaur",
                    "Pikachu",
                    "Frillish Female"
                ].each((name) => {
                    expect(plain).toHaveKey(name);
                });
                expect(plain["Bulbasaur"].live).toBeTrue();
            });
        });

        describe("Dynamax only plus moves", () => {
            it("moveService.isDynamaxOnly matches pvpoke's _PLUS ids and the + the scrape and overrides use", () => {
                var moveService = getInstance("services.move");
                expect(moveService.isDynamaxOnly("SURF_PLUS")).toBeTrue();
                expect(moveService.isDynamaxOnly("SURF+")).toBeTrue();
                expect(moveService.isDynamaxOnly("SEED_BOMB+")).toBeTrue();
                expect(moveService.isDynamaxOnly("SURF")).toBeFalse();
                expect(moveService.isDynamaxOnly("FRENZY_PLANT*")).toBeFalse();
                expect(moveService.isDynamaxOnly("G-MAX_WILDFIRE")).toBeFalse();
                expect(moveService.isDynamaxOnly("DYNAMAX_CANNON")).toBeFalse();
            });

            it("buildMoveData doesn't import them", () => {
                var imported = buildMovesWith([
                    pvpokeMove("SURF", "Surf"),
                    pvpokeMove("SURF_PLUS", "Surf+"),
                    pvpokeMove("ACID_SPRAY_PLUS", "Acid Spray+")
                ]).map((move) => move.nameid);

                expect(imported).toInclude("SURF");
                // Hidden Power is always added
                expect(imported).toInclude("HIDDEN_POWER");
                expect(imported).notToInclude("SURF_PLUS");
                expect(imported).notToInclude("ACID_SPRAY_PLUS");
            });

            it("The seeded moves.json has none", () => {
                var moveService = getInstance("services.move");
                var plus        = deserializeJSON(fileRead(expandPath("/root/database/seeds/resources/moves.json"), "UTF-8"))
                    .filter((move) => moveService.isDynamaxOnly(move.nameid))
                    .map((move) => move.nameid);
                expect(plus).toBeEmpty("Plus moves in moves.json: #plus.toList(", ")#");
            });
        });

        describe("Seeded pokedexoverrides.json", () => {
            it("Every entry is an object", () => {
                var notStructs = seedOverrides.filter((name, entry) => !isStruct(entry)).keyArray();
                expect(notStructs).toBeEmpty("Not objects: #notStructs.toList(", ")#");
            });

            it("Delete entries carry nothing else - fields next to delete would recreate a partial pokemon", () => {
                var mixed = seedOverrides
                    .filter((name, entry) => isStruct(entry) && entry.keyExists("delete"))
                    .filter((name, entry) => entry.count() != 1 || entry["delete"] != true)
                    .keyArray();
                expect(mixed).toBeEmpty("Delete entries with other fields: #mixed.toList(", ")#");
            });

            it("Entries that create a pokemon (have a number) carry every field the build reads", () => {
                var incomplete = [];
                seedOverrides.each((name, entry) => {
                    if(!isStruct(entry) || !entry.keyExists("number")) return;
                    var missing = requiredFields.filter((field) => !entry.keyExists(field));
                    if(missing.len()) incomplete.append("#name# (#missing.toList(", ")#)");
                });
                expect(incomplete).toBeEmpty("Missing fields: #incomplete.toList("; ")#");
            });

            it("Moves and evolutions are arrays", () => {
                var bad = [];
                seedOverrides.each((name, entry) => {
                    if(!isStruct(entry)) return;
                    ["moves", "evolutions"].each((field) => {
                        if(entry.keyExists(field) && !isArray(entry[field])) bad.append("#name#.#field#");
                    });
                });
                expect(bad).toBeEmpty("Not arrays: #bad.toList(", ")#");
            });

            it("Every move resolves to a move in the database once its legacy/shadow marker is stripped", () => {
                // Same stripping as buildPokemonData's cleanup - a move that doesn't resolve is silently dropped by updatePokemonData
                // Dynamax only plus moves are dropped on purpose, so they're left out
                var moveService = getInstance("services.move");
                var known       = {};
                queryExecute(
                    "SELECT nameid FROM move",
                    {},
                    {returnType: "array"}
                ).each((move) => known[move.nameid] = true);

                var unknown = [];
                seedOverrides.each((name, entry) => {
                    if(!isStruct(entry) || !isArray(entry?.moves ?: "")) return;
                    entry.moves.each((move) => {
                        if(moveService.isDynamaxOnly(move)) return;
                        // TODO: G-Max moves aren't imported yet (pvpoke's gamemaster has none) - add them to buildMoveData
                        // and the seeded moves.json, then remove this skip so they're checked like every other move
                        if(left(move, 6) == "G-MAX_") return;
                        var nameid = move;
                        if(nameid.find("*") || nameid.find("$")) {
                            nameid = left(nameid, nameid.len() - 1);
                        }
                        if(!known.keyExists(nameid)) unknown.append("#name#: '#move#'");
                    });
                });
                expect(unknown).toBeEmpty("Moves that won't resolve: #unknown.toList("; ")#");
            });
        });
    }

}
