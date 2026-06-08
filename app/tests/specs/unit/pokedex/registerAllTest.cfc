component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance('tests.resources.mocktrainer');
        pokemonService = getInstance('services.pokemon');
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
                // 99 because unown not included in Johto dex - has own unown dex
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(99);
            });

            it('Can register all in Hoenn which only registers normal pokemon, not costume pokemon', () => {
                // Hoenn costume pokemon
                wurmplePartyHatId = pokemonService.get({
                    number     : 265,
                    name       : 'Wurmple',
                    gender     : '',
                    costume    : true,
                    costumetype: 'Party Hat'
                })[1].getId();
                sableyeHalloweenId = pokemonService.get({
                    number     : 302,
                    name       : 'Sableye',
                    gender     : '',
                    costume    : true,
                    costumetype: 'Halloween'
                })[1].getId();

                // Register all Hoenn pokemon
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = 'Hoenn',
                    shiny   = false
                );

                // Normal Hoenn pokemon should be registered
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Hoenn',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                // 141 Hoenn pokemon + forms
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(141);

                // Costume Hoenn pokemon should not be registered at all
                costumeRegistered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Hoenn',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false,
                    costume = true
                );
                expect(pokedexHelperFunctions.countRegistered(costumeRegistered)).toBe(0);

                // Verify specific costume pokemon are absent from the registered set
                costumeIds = costumeRegistered
                    .filter((entry) => {
                        return !isNull(entry[2]); // pokedex entry is null
                    })
                    .map((entry) => entry[1].getId());
                expect(costumeIds).notToContain(wurmplePartyHatId);
                expect(costumeIds).notToContain(sableyeHalloweenId);
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
