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
                var allPokemon = pokemonService.getAll();
                expect(allPokemon).toBeArray();

                var countPokemon = queryExecute('select count(id) as count from pokemon');
                expect(allPokemon.len()).toBe(countPokemon.count);
            });

            describe('Retrieve pokemon', () => {
                it('Retrieve all Kanto Pokemon', () => {
                    var generation   = generationService.getFromRegion('Kanto');
                    var kantoPokemon = pokemonService.get({generation: generation});
                    expect(kantoPokemon).toBeArray();

                    var countKantoPokemon = queryExecute('
                        select count(p.id) as count
                        from pokemon p inner join generation g on p.generation = g.generation
                        where g.region = ''Kanto''
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
                        number: 1,
                        name  : 'Bulbasaur',
                        gender: ''
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
                        number: 265,
                        name  : 'Wurmple',
                        gender: ''
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
        });
    }

    private function queryPokemon(
        required numeric number,
        required string name,
        required string gender
    ) {
        return queryExecute(
            '
            select id
            from pokemon
            where name = :name
            and number = :number
            and gender = :gender
            ',
            {
                name  : {value: arguments.name, cfsqltype: 'varchar'},
                number: {value: arguments.number, cfsqltype: 'numeric'},
                gender: {value: arguments.gender, cfsqltype: 'varchar'}
            }
        );
    }

    // Validate our orm function pulls a record that matches the db
    private function validatePokemonRecord(
        required numeric number,
        required string name,
        required string gender
    ) {
        var pokemonCfc = pokemonService.get(params = arguments);
        expect(pokemonCfc).toBeArray();
        expect(pokemonCfc.len()).toBe(1);
        pokemonCfc = pokemonCfc[1];

        expect(pokemonCfc).toBeComponent();
        var pokemonQuery = queryPokemon(argumentCollection = arguments);
        expect(pokemonQuery.recordCount()).toBe(1);
        expect(pokemonCfc.getId()).toBe(pokemonQuery.id);
    }

}
