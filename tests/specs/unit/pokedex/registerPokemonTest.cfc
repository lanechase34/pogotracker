component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
        mockTrainer    = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.register', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Can register a pokemon (gyarados)', () => {
                gyaradosCfc = pokemonService.get({
                    number: 130,
                    name  : 'Gyarados',
                    gender: ''
                })[1];
                expect(gyaradosCfc).toBeComponent();
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = gyaradosCfc,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);
            });

            it('Can register a pokemon (mewtwo) normal and then also shiny', () => {
                mewtwoCfc = pokemonService.get({
                    number: 150,
                    name  : 'Mewtwo',
                    gender: ''
                })[1];
                expect(mewtwoCfc).toBeComponent();
                // Normal entry
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = mewtwoCfc,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );
                // Update to shiny too
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = mewtwoCfc,
                    caught      = true,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(1);
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
