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

            afterEach(() => {
                mockTrainer.delete();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Can register a pokemon (gyarados)', () => {
                gyaradosCfc = pokemonService.get({
                    number : 130,
                    name   : 'Gyarados',
                    gender : '',
                    costume: false
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
                    number : 150,
                    name   : 'Mewtwo',
                    gender : '',
                    costume: false
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

            it('Can register a costume form (charizard party hat) and also a shiny and will not collide with other forms', () => {
                charizard = pokemonService.get({
                    number : 6,
                    name   : 'Charizard',
                    gender : '',
                    costume: false
                })[1];

                charizardPartyHat = pokemonService.get({
                    number     : 6,
                    name       : 'Charizard',
                    gender     : '',
                    costume    : true,
                    costumetype: 'Party Hat'
                })[1];

                charizardPikaVisor = pokemonService.get({
                    number     : 6,
                    name       : 'Charizard',
                    gender     : '',
                    costume    : true,
                    costumetype: 'Pikachu Visor'
                })[1];

                // Register party hat
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = charizardPartyHat,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Normal charizard should not be affected
                // Normal kanto dex should be 0 registered
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(0);

                // Costume dex should have 1 entry
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false,
                    costume = true
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);

                // Register normal charizard
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = charizard,
                    caught      = true,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Register pika visor
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = charizardPikaVisor,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Register shiny party hat
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = charizardPartyHat,
                    caught      = false,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Costume dex should have 2 entries
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false,
                    costume = true
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(2);

                // Shiny costume dex should have 1 entry
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false,
                    costume = true
                );
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(1);
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
