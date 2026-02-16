component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService    = getInstance('services.pokemon');
        pokedexService    = getInstance('services.pokedex');
        generationService = getInstance('services.generation');

        kanto = generationService.getFromRegion(region = 'Kanto');

        mockTrainer    = getInstance('tests.resources.mocktrainer');
        mocktrainerids = []; // 1 - friend, 2 - trainer

        // Set up trainer + friend
        friend = mockTrainer.make(securityLevel = 10, autoLogin = false);
        mocktrainerids.append(session.mocktrainerid);
        trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
        mocktrainerids.append(session.mocktrainerid);
    }

    function afterAll() {
        super.afterAll();
        mocktrainerids.each((id) => {
            mockTrainer.delete(id);
        });
    }

    function run() {
        describe('Trade service tests', () => {
            beforeEach(() => {
                setup();
                tradeService = getInstance('services.trade');
            });

            it('Can be created', () => {
                expect(tradeService).toBeComponent();
            });

            describe('Creating trade plan', () => {
                it('Is empty to start', () => {
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(trainerOnly).toBeArray();
                    expect(trainerOnly.len()).toBe(0);

                    friendOnly = tradeService.findExclusive(
                        leftTrainer  = friend,
                        rightTrainer = trainer,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(friendOnly).toBeArray();
                    expect(friendOnly.len()).toBe(0);
                });

                it('Can generate trade plan for trainer only', () => {
                    // Trainer will register a pokemon
                    registerHelper(trainer, 1, 'Bulbasaur', false);

                    // traineronly should now be 1 with Bulbasaur
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(trainerOnly).toBeArray();
                    expect(trainerOnly.len()).toBe(1);
                    expect(trainerOnly[1].getName()).toBe('Bulbasaur');

                    // friendOnly should still be empty
                    friendOnly = tradeService.findExclusive(
                        leftTrainer  = friend,
                        rightTrainer = trainer,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(friendOnly).toBeArray();
                    expect(friendOnly.len()).toBe(0);
                });

                it('Can generate trade plan for friend only', () => {
                    // Friend will register Bulbasaur and another pokemon
                    registerHelper(friend, 1, 'Bulbasaur', false);
                    registerHelper(friend, 4, 'Charmander', false);

                    // trainerOnly should now be empty
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(trainerOnly).toBeArray();
                    expect(trainerOnly.len()).toBe(0);

                    // friendOnly should now be 1 with Charmander
                    friendOnly = tradeService.findExclusive(
                        leftTrainer  = friend,
                        rightTrainer = trainer,
                        shiny        = false,
                        generation   = kanto
                    );
                    expect(friendOnly).toBeArray();
                    expect(friendOnly.len()).toBe(1);
                    expect(friendOnly[1].getName()).toBe('Charmander');
                });

                it('Can generate shiny trade plan for both trainer and friend', () => {
                    // Trainer registers shiny Bulbasaur, Friend registers shiny Charmander
                    registerHelper(trainer, 1, 'Bulbasaur', true);
                    registerHelper(friend, 4, 'Charmander', true);

                    // trainerOnly should now be 1 with Shiny Bulbasaur
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = true,
                        generation   = kanto
                    );
                    expect(trainerOnly).toBeArray();
                    expect(trainerOnly.len()).toBe(1);
                    expect(trainerOnly[1].getName()).toBe('Bulbasaur');

                    // friendOnly should now be 1 with Shiny Charmander
                    friendOnly = tradeService.findExclusive(
                        leftTrainer  = friend,
                        rightTrainer = trainer,
                        shiny        = true,
                        generation   = kanto
                    );
                    expect(friendOnly).toBeArray();
                    expect(friendOnly.len()).toBe(1);
                    expect(friendOnly[1].getName()).toBe('Charmander');
                });
            });
        });
    }

    public void function registerHelper(
        required component trainer,
        required numeric number,
        required string name,
        boolean shiny = false
    ) {
        var pokemon = pokemonService.get({
            number: arguments.number,
            name  : arguments.name,
            gender: ''
        });

        expect(pokemon).toBeArray();
        expect(pokemon.len()).toBe(1);
        pokemon = pokemon[1];

        pokedexService.register(
            trainer     = arguments.trainer,
            pokemon     = pokemon,
            caught      = !arguments.shiny,
            shiny       = arguments.shiny,
            hundo       = false,
            shadow      = false,
            shadowshiny = false
        )
    }

}
