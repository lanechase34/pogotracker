component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.createSearchString', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
