component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        generationService = getInstance("services.generation");
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("Pokemon Service", () => {
            beforeEach(() => {
                setup();
                pokemonService = getInstance("services.pokemon");
            });

            it("Retrieve all pokemon", () => {
                var allPokemon = pokemonService.getAll(); // Costume forms aren't included as unique pokemon in getAll()
                expect(allPokemon).toBeArray();

                expect(allPokemon.len()).toBe(testData.countRows("pokemon", {costume: false}));
            });

            describe("Retrieve pokemon", () => {
                it("Retrieve all Kanto Pokemon", () => {
                    var generation   = generationService.getFromRegion("Kanto");
                    var kantoPokemon = pokemonService.findPokemon({generation: generation, costume: false});
                    expect(kantoPokemon).toBeArray();

                    var countKantoPokemon = queryExecute("
                        SELECT COUNT(pokemon.id) AS count
                        FROM pokemon
                        INNER JOIN generation ON generation.generation = pokemon.generation
                        WHERE generation.region = 'Kanto'
                            AND pokemon.costume = false
                    ");

                    expect(kantoPokemon.len()).toBe(countKantoPokemon.count);
                });

                it("Retrieve Charizard record", () => {
                    validatePokemonRecord(number = 6, name = "Charizard", gender = "");
                });

                it("Retrieve West Shellos", () => {
                    validatePokemonRecord(
                        number = 422,
                        name   = "Shellos West Sea",
                        gender = ""
                    );
                });

                it("Retrieve Trash Burmy", () => {
                    validatePokemonRecord(
                        number = 412,
                        name   = "Burmy Trash Cloak",
                        gender = ""
                    );
                });

                it("Retrieve Mr. Rime", () => {
                    validatePokemonRecord(number = 866, name = "Mr. Rime", gender = "");
                });

                it("Retrieve Male Jellicent", () => {
                    validatePokemonRecord(
                        number = 593,
                        name   = "Jellicent",
                        gender = "Male"
                    );
                });
            });

            describe("getSearchArray()", () => {
                it("Has one entry per non-costume pokemon in the database", () => {
                    var arr           = pokemonService.getSearchArray(); // Costume pokemon excluded from search array
                    var expectedCount = testData.countRows("pokemon", {costume: false});
                    expect(arr).toBeArray();
                    expect(arr.len()).toBeGT(0);
                    expect(arr.len()).toBe(expectedCount);
                });

                it("Each entry has the five fields required by select2 (id, text, image, alt, ses)", () => {
                    var entry = pokemonService.getSearchArray()[1];
                    expect(entry).toHaveKey("id");
                    expect(entry).toHaveKey("text");
                    expect(entry).toHaveKey("image");
                    expect(entry).toHaveKey("alt");
                    expect(entry).toHaveKey("ses");

                    expect(entry.id).toBeNumeric();
                    expect(entry.text).toBeString();
                    expect(entry.text.len()).toBeGT(0);

                    // Used to build the detail URL
                    expect(entry.ses).toBeString();
                    expect(entry.ses.len()).toBeGT(0);
                });

                it("Returns the same data on a second call (cached)", () => {
                    var arr1 = pokemonService.getSearchArray();
                    var arr2 = pokemonService.getSearchArray();
                    expect(arr1.len()).toBe(arr2.len());
                    expect(arr1[1].id).toBe(arr2[1].id);
                });
            });

            describe("searchPokemon()", () => {
                it("Finds Bulbasaur by its exact name in a single page of select2 results", () => {
                    var result = pokemonService.searchPokemon(search = "Bulbasaur", page = 1);
                    expect(result).toBeStruct();
                    expect(result).toHaveKey("results");
                    expect(result).toHaveKey("pagination");
                    expect(result.results).toBeArray();
                    expect(result.pagination).toBeStruct();
                    expect(result.pagination).toHaveKey("more");

                    // Each entry carries all five select2 fields
                    expect(result.results.len()).toBeGT(0);
                    var entry = result.results[1];
                    expect(entry).toHaveKey("id");
                    expect(entry).toHaveKey("text");
                    expect(entry).toHaveKey("image");
                    expect(entry).toHaveKey("alt");
                    expect(entry).toHaveKey("ses");

                    // ses is needed for client-side navigation
                    result.results.each((r) => {
                        expect(r.ses.len()).toBeGT(0);
                    });

                    var matched = result.results.filter((r) => r.text == "Bulbasaur");
                    expect(matched.len()).toBe(1);

                    // The full result set fits on one page
                    expect(result.pagination.more).toBeFalse();
                });

                it("Returns empty results with more:false when nothing matches", () => {
                    for(var search in ["NotARealPokemon", "xQzJkWpLmN"]) {
                        var result = pokemonService.searchPokemon(search = search, page = 1);
                        expect(result.results).toBeArray();
                        expect(result.results.len()).toBe(0);
                        expect(result.pagination.more).toBeFalse();
                    }
                });

                it("A generic term 'a' returns at most the default page size of 20 and has more", () => {
                    var result = pokemonService.searchPokemon(search = "a", page = 1);
                    expect(result.results).toBeArray();
                    expect(result.results.len()).toBeGT(0);
                    expect(result.results.len()).toBeLTE(20);

                    // Hundreds of pokemon contain 'a'
                    expect(result.pagination.more).toBeTrue();
                });

                describe("Case insensitivity", () => {
                    it("Uppercase 'BULBASAUR' matches the same pokemon as lowercase", () => {
                        var upper = pokemonService.searchPokemon(search = "BULBASAUR", page = 1);
                        var lower = pokemonService.searchPokemon(search = "bulbasaur", page = 1);
                        expect(upper.results.len()).toBe(lower.results.len());

                        var matched = upper.results.filter((r) => r.text == "Bulbasaur");
                        expect(matched.len()).toBe(1);
                    });

                    it("Mixed-case 'ChArIzArD' still matches Charizard", () => {
                        var result  = pokemonService.searchPokemon(search = "ChArIzArD", page = 1);
                        var matched = result.results.filter((r) => r.text == "Charizard");
                        expect(matched.len()).toBe(1);
                    });
                });

                describe("Substring (mid-string) matching", () => {
                    it("'saur' matches Bulbasaur, Ivysaur, and Venusaur", () => {
                        var result = pokemonService.searchPokemon(search = "saur", page = 1);
                        expect(result.results.len()).toBeGT(1);

                        var names = result.results.map((r) => r.text);
                        expect(names.find("Bulbasaur")).toBeGT(0);
                        expect(names.find("Ivysaur")).toBeGT(0);
                        expect(names.find("Venusaur")).toBeGT(0);
                    });

                    it("Search term at the end of a name still matches", () => {
                        // 'zard' is the suffix of Charizard
                        var result  = pokemonService.searchPokemon(search = "zard", page = 1);
                        var matched = result.results.filter((r) => r.text == "Charizard");
                        expect(matched.len()).toBe(1);
                    });
                });

                describe("Pagination", () => {
                    it("Page 2 returns different results than page 1 (no overlap)", () => {
                        var page1 = pokemonService.searchPokemon(search = "a", page = 1, pageSize = 5);
                        var page2 = pokemonService.searchPokemon(search = "a", page = 2, pageSize = 5);

                        expect(page1.results.len()).toBe(5);
                        expect(page2.results.len()).toBeGT(0);

                        var ids1    = page1.results.map((r) => r.id);
                        var overlap = page2.results.filter((r) => ids1.contains(r.id));
                        expect(overlap.len()).toBe(0);
                    });

                    it("pagination.more is false on the final page", () => {
                        // 'Bulbasaur' matches 1 pokemon; with pageSize=1, page 1 has more=false
                        var page1 = pokemonService.searchPokemon(search = "Bulbasaur", page = 1, pageSize = 1);
                        expect(page1.results.len()).toBe(1);
                        expect(page1.pagination.more).toBeFalse();
                    });

                    it("pagination.more is true when results exceed pageSize", () => {
                        // 'saur' matches at least 3 pokemon; pageSize=1 forces more=true on page 1
                        var page1 = pokemonService.searchPokemon(search = "saur", page = 1, pageSize = 1);
                        expect(page1.results.len()).toBe(1);
                        expect(page1.pagination.more).toBeTrue();
                    });

                    it("Paginating through all results yields no duplicates and all match the term", () => {
                        var allResults = [];
                        var page       = 1;
                        var hasMore    = true;

                        while(hasMore) {
                            var curr = pokemonService.searchPokemon(search = "saur", page = page, pageSize = 2);
                            curr.results.each((r) => allResults.append(r));
                            hasMore = curr.pagination.more;
                            page++;
                        }

                        // Every result must contain 'saur'
                        var allContainTerm = allResults.every((r) => {
                            return lCase(r.text).find("saur") > 0;
                        });
                        expect(allContainTerm).toBeTrue();

                        // No duplicate ids across pages
                        var seenIds = {};
                        var hasDupe = false;
                        allResults.each((r) => {
                            if(seenIds.keyExists(r.id)) {
                                hasDupe = true;
                            }
                            seenIds[r.id] = true;
                        });
                        expect(hasDupe).toBeFalse();
                    });

                    it("An out-of-bounds page returns empty results with more:false", () => {
                        var result = pokemonService.searchPokemon(search = "Bulbasaur", page = 9999);
                        expect(result.results).toBeArray();
                        expect(result.results.len()).toBe(0);
                        expect(result.pagination.more).toBeFalse();
                    });
                });
            });

            describe("getCostumes()", () => {
                it("Can retrieve Charmander's costumes", () => {
                    var charmander = validatePokemonRecord(number = 4, name = "Charmander", gender = "");

                    var costumes = pokemonService.getCostumes(charmander);
                    expect(costumes).toBeArray();
                    expect(costumes.len()).toBeGTE(3); // at least 3 costumes

                    // Check each individual costume form
                    var loadedCostumes = {};
                    costumes.each((costume) => {
                        loadedCostumes[costume.costumetype] = true;

                        validatePokemonRecord(
                            number      = 4,
                            name        = "Charmander",
                            gender      = "",
                            costume     = true,
                            costumeType = costume.costumetype
                        );
                    });

                    var expected = ["Party Hat", "Halloween", "Pikachu Visor"];
                    expected.each((item) => {
                        expect(loadedCostumes).toHaveKey(item);
                    });
                });

                it("Can retrieve Tropius's costumes", () => {
                    var tropius = validatePokemonRecord(number = 357, name = "Tropius", gender = "");

                    var costumes = pokemonService.getCostumes(tropius);
                    expect(costumes).toBeArray();
                    expect(costumes.len()).toBe(0); // has no costumes
                });
            });

            describe("getEvolvers()", () => {
                it("Can retrieve Persian's evolvers", () => {
                    var persian = validatePokemonRecord(number = 53, name = "Persian", gender = "");

                    var evolvers = pokemonService.getEvolvers(persian);
                    expect(evolvers).toBeArray();
                    expect(evolvers.len()).toBe(1);
                    expect(evolvers[1].name).toBe("Meowth");
                    expect(evolvers[1].number).toBe(52);
                });

                it("Can retrieve Gigantamax Meowth's evolvers", () => {
                    var gmaxMeowth = validatePokemonRecord(
                        number = 52,
                        name   = "Gigantamax Meowth",
                        gender = ""
                    );

                    var evolvers = pokemonService.getEvolvers(gmaxMeowth);
                    expect(evolvers).toBeArray();
                    expect(evolvers.len()).toBe(1);
                    expect(evolvers[1].name).toBe("Meowth");
                    expect(evolvers[1].number).toBe(52);
                });

                it("Can retrieve Mega Charizard Y evolvers", () => {
                    var megaZard = validatePokemonRecord(
                        number = 6,
                        name   = "Mega Charizard Y",
                        gender = ""
                    );

                    var evolvers = pokemonService.getEvolvers(megaZard);
                    expect(evolvers).toBeArray();
                    expect(evolvers.len()).toBe(1);
                    expect(evolvers[1].name).toBe("Charizard");
                    expect(evolvers[1].number).toBe(6);
                });
            });
        });
    }

    private function queryPokemon(
        required numeric number,
        required string name,
        required string gender,
        boolean costume    = false,
        string costumeType = ""
    ) {
        return queryExecute(
            "
            SELECT id
            FROM pokemon
            WHERE name = :name
                AND number = :number
                AND gender = :gender
                AND costume = :costume
                AND costumetype = :costumetype
            ",
            {
                name       : {value: arguments.name, cfsqltype: "varchar"},
                number     : {value: arguments.number, cfsqltype: "integer"},
                gender     : {value: arguments.gender, cfsqltype: "varchar"},
                costume    : {value: arguments.costume, cfsqltype: "boolean"},
                costumetype: {value: arguments.costumetype, cfsqltype: "varchar"}
            }
        );
    }

    // Validate the service pulls a record that matches the db
    private struct function validatePokemonRecord(
        required numeric number,
        required string name,
        required string gender,
        boolean costume    = false,
        string costumeType = ""
    ) {
        var matches = pokemonService.findPokemon(params = arguments);
        expect(matches).toBeArray();
        expect(matches.len()).toBe(1);

        var pokemon = matches[1];
        expect(pokemon).toBeStruct();
        var pokemonQuery = queryPokemon(argumentCollection = arguments);
        expect(pokemonQuery.recordCount()).toBe(1);
        expect(pokemon.id).toBe(pokemonQuery.id);

        return pokemon;
    }

}
