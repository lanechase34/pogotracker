component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.registerAll', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Can register all pokemon in Kanto Region', () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = 'Kanto',
                    shiny   = false
                );

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(151);
            });

            it('Can register all shiny pokemon in Johto Region', () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = 'Johto',
                    shiny   = true
                );

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Johto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(100);
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
