component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        generationService = getInstance('services.generation');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Pokemon Service', () => {
            beforeEach(() => {
                setup();
                pokemonService = getInstance('services.pokemon');
            });

            it('Can be created', () => {
                expect(pokemonService).toBeComponent();
            });

            it('Retrieve all pokemon', () => {
                var allPokemon = pokemonService.getAll(); // Costume forms aren't included as unique pokemon in getAll()
                expect(allPokemon).toBeArray();

                var countPokemon = queryExecute('select count(id) as count from pokemon where costume = false');
                expect(allPokemon.len()).toBe(countPokemon.count);
            });

            describe('Retrieve pokemon', () => {
                it('Retrieve all Kanto Pokemon', () => {
                    var generation   = generationService.getFromRegion('Kanto');
                    var kantoPokemon = pokemonService.get({generation: generation, costume: false});
                    expect(kantoPokemon).toBeArray();

                    var countKantoPokemon = queryExecute('
                        select count(p.id) as count
                        from pokemon p inner join generation g on p.generation = g.generation
                        where g.region = ''Kanto'' and p.costume = false
                    ');

                    expect(kantoPokemon.len()).toBe(countKantoPokemon.count);
                });

                it('Retrieve Charizard record', () => {
                    validatePokemonRecord(number = 6, name = 'Charizard', gender = '');
                });

                it('Retrieve West Shellos', () => {
                    validatePokemonRecord(
                        number = 422,
                        name   = 'Shellos West Sea',
                        gender = ''
                    );
                });

                it('Retrieve Trash Burmy', () => {
                    validatePokemonRecord(
                        number = 412,
                        name   = 'Burmy Trash Cloak',
                        gender = ''
                    );
                });

                it('Retrieve Mr. Rime', () => {
                    validatePokemonRecord(number = 866, name = 'Mr. Rime', gender = '');
                });

                it('Retrieve Male Jellicent', () => {
                    validatePokemonRecord(
                        number = 593,
                        name   = 'Jellicent',
                        gender = 'Male'
                    );
                });
            });

            describe('Retrieve evolutions', () => {
                it('Retrieve Bulbasaur''s Evolutions', () => {
                    var bulbasaur = pokemonService.get({
                        number : 1,
                        name   : 'Bulbasaur',
                        gender : '',
                        costume: false
                    });
                    expect(bulbasaur).toBeArray();
                    expect(bulbasaur.len()).toBe(1);
                    bulbasaur = bulbasaur[1];
                    expect(bulbasaur).toBeComponent();

                    var evolutions = pokemonService.getEvolution(bulbasaur);
                    expect(evolutions).toBeArray();
                    expect(evolutions.len()).toBe(1);

                    expect(evolutions[1].getEvolution().getName()).toBe('Ivysaur');
                });

                it('Retrieve Wurmple''s Evolutions', () => {
                    var wurmple = pokemonService.get({
                        number : 265,
                        name   : 'Wurmple',
                        gender : '',
                        costume: false
                    });
                    expect(wurmple).toBeArray();
                    expect(wurmple.len()).toBe(1);
                    wurmple = wurmple[1];
                    expect(wurmple).toBeComponent();

                    var evolutions = pokemonService.getEvolution(wurmple);
                    expect(evolutions).toBeArray();
                    expect(evolutions.len()).toBe(2);

                    var checkStage1 = ['Cascoon', 'Silcoon'];
                    var checkStage2 = ['Dustox', 'Beautifly'];
                    evolutions.each((evolution) => {
                        checkStage1.delete(evolution.getEvolution().getName());

                        var nextStage = pokemonService.getEvolution(evolution.getEvolution());
                        expect(nextStage).toBeArray();
                        expect(nextStage.len()).toBe(1);
                        checkStage2.delete(nextStage[1].getEvolution().getName());
                    });

                    expect(checkStage1.len()).toBe(0);
                    expect(checkStage2.len()).toBe(0);
                });
            });

            describe('getSearchArray()', () => {
                it('Returns a non-empty array', () => {
                    var arr = pokemonService.getSearchArray();
                    expect(arr).toBeArray();
                    expect(arr.len()).toBeGT(0);
                });

                it('Array length matches the total pokemon count in the database', () => {
                    var arr   = pokemonService.getSearchArray(); // Costume pokemon excluded from search array
                    var count = queryExecute('select count(id) as c from pokemon where costume = false').c;
                    expect(arr.len()).toBe(count);
                });

                it('Each entry has the five fields required by select2 (id, text, image, alt, ses)', () => {
                    var arr   = pokemonService.getSearchArray();
                    var entry = arr[1];
                    expect(entry).toHaveKey('id');
                    expect(entry).toHaveKey('text');
                    expect(entry).toHaveKey('image');
                    expect(entry).toHaveKey('alt');
                    expect(entry).toHaveKey('ses');
                });

                it('id is numeric', () => {
                    var arr = pokemonService.getSearchArray();
                    expect(arr[1].id).toBeNumeric();
                });

                it('text is a non-empty string', () => {
                    var arr = pokemonService.getSearchArray();
                    expect(arr[1].text).toBeString();
                    expect(arr[1].text.len()).toBeGT(0);
                });

                it('ses is a non-empty string (used to build the detail URL)', () => {
                    var arr = pokemonService.getSearchArray();
                    expect(arr[1].ses).toBeString();
                    expect(arr[1].ses.len()).toBeGT(0);
                });

                it('Returns the same data on a second call (cached)', () => {
                    var arr1 = pokemonService.getSearchArray();
                    var arr2 = pokemonService.getSearchArray();
                    expect(arr1.len()).toBe(arr2.len());
                    expect(arr1[1].id).toBe(arr2[1].id);
                });
            });

            describe('searchPokemon()', () => {
                describe('Return structure', () => {
                    it('Always returns a struct with results and pagination keys', () => {
                        var result = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1);
                        expect(result).toBeStruct();
                        expect(result).toHaveKey('results');
                        expect(result).toHaveKey('pagination');
                        expect(result.results).toBeArray();
                        expect(result.pagination).toBeStruct();
                        expect(result.pagination).toHaveKey('more');
                    });

                    it('Each result entry carries all five select2 fields', () => {
                        var result = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1);
                        expect(result.results.len()).toBeGT(0);
                        var entry = result.results[1];
                        expect(entry).toHaveKey('id');
                        expect(entry).toHaveKey('text');
                        expect(entry).toHaveKey('image');
                        expect(entry).toHaveKey('alt');
                        expect(entry).toHaveKey('ses');
                    });

                    it('ses is non-empty on every result (needed for client-side navigation)', () => {
                        var result = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1);
                        result.results.each((r) => {
                            expect(r.ses.len()).toBeGT(0);
                        });
                    });
                });

                describe('Exact name match', () => {
                    it('Finds Bulbasaur by its exact name', () => {
                        var result  = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1);
                        var matched = result.results.filter((r) => r.text == 'Bulbasaur');
                        expect(matched.len()).toBe(1);
                    });

                    it('pagination.more is false when the full result set fits on one page', () => {
                        var result = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1);
                        expect(result.pagination.more).toBeFalse();
                    });
                });

                describe('No-match search', () => {
                    it('Returns an empty results array for a nonexistent name', () => {
                        var result = pokemonService.searchPokemon(search = 'NotARealPokemon', page = 1);
                        expect(result.results).toBeArray();
                        expect(result.results.len()).toBe(0);
                    });

                    it('pagination.more is false when there are no results', () => {
                        var result = pokemonService.searchPokemon(search = 'NotARealPokemon', page = 1);
                        expect(result.pagination.more).toBeFalse();
                    });

                    it('Random gibberish returns no results', () => {
                        var result = pokemonService.searchPokemon(search = 'xQzJkWpLmN', page = 1);
                        expect(result.results.len()).toBe(0);
                        expect(result.pagination.more).toBeFalse();
                    });
                });

                describe('Broad match (generic term)', () => {
                    it('Returns results for the generic term ''a''', () => {
                        var result = pokemonService.searchPokemon(search = 'a', page = 1);
                        expect(result.results).toBeArray();
                        expect(result.results.len()).toBeGT(0);
                    });

                    it('pagination.more is true because hundreds of pokemon contain ''a''', () => {
                        var result = pokemonService.searchPokemon(search = 'a', page = 1);
                        expect(result.pagination.more).toBeTrue();
                    });

                    it('Default page size returns at most 20 results', () => {
                        var result = pokemonService.searchPokemon(search = 'a', page = 1);
                        expect(result.results.len()).toBeLTE(20);
                    });
                });

                describe('Case insensitivity', () => {
                    it('Uppercase ''BULBASAUR'' matches the same pokemon as lowercase', () => {
                        var upper = pokemonService.searchPokemon(search = 'BULBASAUR', page = 1);
                        var lower = pokemonService.searchPokemon(search = 'bulbasaur', page = 1);
                        expect(upper.results.len()).toBe(lower.results.len());
                    });

                    it('Uppercase result confirms Bulbasaur is found', () => {
                        var result  = pokemonService.searchPokemon(search = 'BULBASAUR', page = 1);
                        var matched = result.results.filter((r) => r.text == 'Bulbasaur');
                        expect(matched.len()).toBe(1);
                    });

                    it('Mixed-case ''ChArIzArD'' still matches Charizard', () => {
                        var result  = pokemonService.searchPokemon(search = 'ChArIzArD', page = 1);
                        var matched = result.results.filter((r) => r.text == 'Charizard');
                        expect(matched.len()).toBe(1);
                    });
                });

                describe('Substring (mid-string) matching', () => {
                    it('''saur'' matches Bulbasaur, Ivysaur, and Venusaur', () => {
                        var result = pokemonService.searchPokemon(search = 'saur', page = 1);
                        expect(result.results.len()).toBeGT(1);

                        var names = result.results.map((r) => r.text);
                        expect(names.find('Bulbasaur')).toBeGT(0);
                        expect(names.find('Ivysaur')).toBeGT(0);
                        expect(names.find('Venusaur')).toBeGT(0);
                    });

                    it('Search term at the end of a name still matches', () => {
                        // ''zard'' is the suffix of Charizard and Charmeleon-adjacent, but definitely Charizard
                        var result  = pokemonService.searchPokemon(search = 'zard', page = 1);
                        var matched = result.results.filter((r) => r.text == 'Charizard');
                        expect(matched.len()).toBe(1);
                    });
                });

                describe('Pagination', () => {
                    it('Page 2 returns different results than page 1 (no overlap)', () => {
                        var page1 = pokemonService.searchPokemon(search = 'a', page = 1, pageSize = 5);
                        var page2 = pokemonService.searchPokemon(search = 'a', page = 2, pageSize = 5);

                        expect(page1.results.len()).toBe(5);
                        expect(page2.results.len()).toBeGT(0);

                        var ids1    = page1.results.map((r) => r.id);
                        var overlap = page2.results.filter((r) => ids1.contains(r.id));
                        expect(overlap.len()).toBe(0);
                    });

                    it('pagination.more is false on the final page', () => {
                        // 'Bulbasaur' matches 1 pokemon; with pageSize=1, page 1 has more=false
                        var page1 = pokemonService.searchPokemon(search = 'Bulbasaur', page = 1, pageSize = 1);
                        expect(page1.results.len()).toBe(1);
                        expect(page1.pagination.more).toBeFalse();
                    });

                    it('pagination.more is true when results exceed pageSize', () => {
                        // 'saur' matches at least 3 pokemon; pageSize=1 forces more=true on page 1
                        var page1 = pokemonService.searchPokemon(search = 'saur', page = 1, pageSize = 1);
                        expect(page1.results.len()).toBe(1);
                        expect(page1.pagination.more).toBeTrue();
                    });

                    it('Paginating through all results yields no duplicates and all match the term', () => {
                        var allResults = [];
                        var page       = 1;
                        var hasMore    = true;

                        while(hasMore) {
                            var curr = pokemonService.searchPokemon(search = 'saur', page = page, pageSize = 2);
                            curr.results.each((r) => allResults.append(r));
                            hasMore = curr.pagination.more;
                            page++;
                        }

                        // Every result must contain 'saur'
                        var allContainTerm = allResults.every((r) => {
                            return lCase(r.text).find('saur') > 0;
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

                    it('An out-of-bounds page returns empty results with more:false', () => {
                        var result = pokemonService.searchPokemon(search = 'Bulbasaur', page = 9999);
                        expect(result.results).toBeArray();
                        expect(result.results.len()).toBe(0);
                        expect(result.pagination.more).toBeFalse();
                    });
                });
            });

            describe('getCostumes()', () => {
                it('Can retrieve Charmander''s costumes', () => {
                    var charmander = validatePokemonRecord(number = 4, name = 'Charmander', gender = '');

                    var costumes = pokemonService.getCostumes(charmander);
                    expect(costumes).toBeArray();
                    expect(costumes.len()).toBeGTE(3); // at least 3 costumes

                    // Check each individual costume form
                    var loadedCostumes = {};
                    costumes.each((costume) => {
                        loadedCostumes[costume.getCostumeType()] = true;

                        validatePokemonRecord(
                            number      = 4,
                            name        = 'Charmander',
                            gender      = '',
                            costume     = true,
                            costumeType = costume.getCostumeType()
                        );
                    });

                    var expected = ['Party Hat', 'Halloween', 'Pikachu Visor'];
                    expected.each((item) => {
                        expect(loadedCostumes).toHaveKey(item);
                    });
                });

                it('Can retrieve Tropius''s costumes', () => {
                    var tropius = validatePokemonRecord(number = 357, name = 'Tropius', gender = '');

                    var costumes = pokemonService.getCostumes(tropius);
                    expect(costumes).toBeArray();
                    expect(costumes.len()).toBe(0); // has no costumes
                });
            });
        });
    }

    private function queryPokemon(
        required numeric number,
        required string name,
        required string gender,
        boolean costume    = false,
        string costumeType = ''
    ) {
        return queryExecute(
            '
            select id
            from pokemon
            where name = :name
            and number = :number
            and gender = :gender
            and costume = :costume
            and costumetype = :costumetype
            ',
            {
                name       : {value: arguments.name, cfsqltype: 'varchar'},
                number     : {value: arguments.number, cfsqltype: 'numeric'},
                gender     : {value: arguments.gender, cfsqltype: 'varchar'},
                costume    : {value: arguments.costume, cfsqltype: 'boolean'},
                costumetype: {value: arguments.costumetype, cfsqltype: 'varchar'}
            }
        );
    }

    // Validate our orm function pulls a record that matches the db
    private component function validatePokemonRecord(
        required numeric number,
        required string name,
        required string gender,
        boolean costume    = false,
        string costumeType = ''
    ) {
        var pokemonCfc = pokemonService.get(params = arguments);
        expect(pokemonCfc).toBeArray();
        expect(pokemonCfc.len()).toBe(1);
        pokemonCfc = pokemonCfc[1];

        expect(pokemonCfc).toBeComponent();
        var pokemonQuery = queryPokemon(argumentCollection = arguments);
        expect(pokemonQuery.recordCount()).toBe(1);
        expect(pokemonCfc.getId()).toBe(pokemonQuery.id);

        return pokemonCfc;
    }

}
