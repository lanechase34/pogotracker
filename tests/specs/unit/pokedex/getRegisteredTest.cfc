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
        describe('pokedexService.getRegistered', () => {
            beforeEach(() => {
                setup();

                mockGenerationService = {
                    getFromRegion: function(region) {
                        return 'gen1';
                    }
                };
                mockPokedexService = createMock('models.services.pokedex')
                    .setGenerationService(mockGenerationService)
                    .setCacheService(getInstance('services.cache'));

                trainer = mockTrainer.make();
            });

            it('Can be created', () => {
                expect(mockPokedexService).toBeComponent();
            });

            it('Executes correct query and returns result for default args', () => {
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
