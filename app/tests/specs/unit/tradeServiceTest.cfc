component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService    = getInstance('services.pokemon');
        pokedexService    = getInstance('services.pokedex');
        generationService = getInstance('services.generation');
        customService     = getInstance('services.custom');

        kanto = generationService.getFromRegion(region = 'Kanto');

        mockTrainer    = getInstance('tests.resources.mocktrainer');
        mocktrainerids = []; // 1 - friend, 2 - trainer

        // Set up trainer + friend
        friend = mockTrainer.make(securityLevel = 10, autoLogin = false);
        mocktrainerids.append(session.mocktrainerid);
        trainer = mockTrainer.make(securityLevel = 10, autoLogin = false);
        mocktrainerids.append(session.mocktrainerid);

        // Kanto costume pokemon (Party Hat Bulbasaur) - excluded from region trade plans
        partyHatBulbasaur = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Party Hat'
        })[1];

        // Kanto normal pokemon not used in prior tests - used to confirm non-costume pokemon still appear
        squirtle = pokemonService.get({
            number : 7,
            name   : 'Squirtle',
            gender : '',
            costume: false
        })[1];

        // Non-tradable mythical - verifies the tradable=true WHERE filter
        mew = pokemonService.get({
            number : 151,
            name   : 'Mew',
            gender : '',
            costume: false
        })[1];
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

                it('Can only generate trade plans without costumes when region is selected', () => {
                    // Trainer registers a costume Kanto pokemon and a normal Kanto pokemon not held by friend
                    registerHelper(
                        trainer,
                        1,
                        'Bulbasaur',
                        false,
                        true,
                        'Party Hat'
                    );
                    registerHelper(trainer, 7, 'Squirtle', false);

                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        generation   = kanto
                    );

                    // Normal Squirtle (#7) is exclusive to trainer and must appear
                    expect(trainerOnly.filter((p) => p.getName() == 'Squirtle').len()).toBe(1);

                    // No costume pokemon should be present regardless of number or tradability
                    expect(trainerOnly.filter((p) => p.getCostume()).len()).toBe(0);
                });

                it('Can generate trade plans with costumes if the custom selected has costumes', () => {
                    // Trainer already has Party Hat Bulbasaur and Squirtle from previous test.
                    // Create a custom pokedex that explicitly lists both - including the costume variant.
                    registerHelper(
                        trainer,
                        1,
                        'Bulbasaur',
                        false,
                        true,
                        'Party Hat'
                    );
                    registerHelper(trainer, 7, 'Squirtle', false);

                    var customid = customService.create(
                        trainer = trainer,
                        name    = 'Trade Test Custom #left(createUUID(), 20)#',
                        public  = false
                    );
                    var custom = customService.getFromId(customid);
                    customService.createCustomPokedex(
                        custom  = custom,
                        pokemon = [squirtle.getId(), partyHatBulbasaur.getId()]
                    );

                    // Friend has neither, so both are exclusive to trainer
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        custom       = custom
                    );

                    // Both entries must appear - costume pokemon are not suppressed in custom mode
                    expect(trainerOnly.len()).toBe(2);
                    expect(trainerOnly.filter((p) => p.getName() == 'Squirtle').len()).toBe(1);
                    expect(trainerOnly.filter((p) => p.getCostume() && p.getCostumetype() == 'Party Hat').len()).toBe(1);

                    customService.delete(custom);
                });

                it('Non-tradable pokemon are excluded from all trade plans', () => {
                    expect(mew.getTradable()).toBeFalse();

                    // Trainer registers non-tradable Mew; Squirtle is re-registered to ensure a tradable
                    // exclusive exists so the query is verifiably working
                    registerHelper(trainer, 151, 'Mew', false);
                    registerHelper(trainer, 7, 'Squirtle', false);

                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        generation   = kanto
                    );

                    // Mew must be absent - tradable=false filters it unconditionally
                    expect(trainerOnly.filter((p) => p.getName() == 'Mew').len()).toBe(0);

                    // Squirtle must appear - confirms the query is returning results, not silently empty
                    expect(trainerOnly.filter((p) => p.getName() == 'Squirtle').len()).toBe(1);
                });

                it('Custom trade plan excludes pokemon that both trainers have', () => {
                    // Trainer has Squirtle and Party Hat Bulbasaur; give friend Squirtle too
                    registerHelper(trainer, 7, 'Squirtle', false);
                    registerHelper(
                        trainer,
                        1,
                        'Bulbasaur',
                        false,
                        true,
                        'Party Hat'
                    );
                    registerHelper(friend, 7, 'Squirtle', false);

                    var customid = customService.create(
                        trainer = trainer,
                        name    = 'Mutual Test Custom #left(createUUID(), 20)#',
                        public  = false
                    );
                    var custom = customService.getFromId(customid);
                    customService.createCustomPokedex(
                        custom  = custom,
                        pokemon = [squirtle.getId(), partyHatBulbasaur.getId()]
                    );

                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = false,
                        custom       = custom
                    );

                    // Squirtle is mutual - must not appear as exclusive
                    expect(trainerOnly.filter((p) => p.getName() == 'Squirtle').len()).toBe(0);

                    // Party Hat Bulbasaur is only held by trainer - must appear
                    expect(trainerOnly.len()).toBe(1);
                    expect(trainerOnly[1].getCostume()).toBeTrue();
                    expect(trainerOnly[1].getCostumetype()).toBe('Party Hat');

                    customService.delete(custom);
                });

                it('Can generate a shiny trade plan using a custom pokedex', () => {
                    // Squirtle must be shiny-eligible for the pokemon.shiny=true WHERE clause to pass it through
                    expect(squirtle.getShiny()).toBeTrue();

                    // Trainer gets shiny Squirtle; friend gets caught-only Squirtle (no shiny)
                    registerHelper(trainer, 7, 'Squirtle', true);
                    registerHelper(friend, 7, 'Squirtle', false);

                    var customid = customService.create(
                        trainer = trainer,
                        name    = 'Shiny Custom Test #left(createUUID(), 20)#',
                        public  = false
                    );
                    var custom = customService.getFromId(customid);
                    customService.createCustomPokedex(custom = custom, pokemon = [squirtle.getId()]);

                    // Trainer has shiny Squirtle; friend's Squirtle is not shiny → exclusive to trainer
                    trainerOnly = tradeService.findExclusive(
                        leftTrainer  = trainer,
                        rightTrainer = friend,
                        shiny        = true,
                        custom       = custom
                    );
                    expect(trainerOnly.len()).toBe(1);
                    expect(trainerOnly[1].getName()).toBe('Squirtle');

                    // Friend has no shiny Squirtle → nothing exclusive from friend's side
                    friendOnly = tradeService.findExclusive(
                        leftTrainer  = friend,
                        rightTrainer = trainer,
                        shiny        = true,
                        custom       = custom
                    );
                    expect(friendOnly.len()).toBe(0);

                    customService.delete(custom);
                });
            });
        });
    }

    public void function registerHelper(
        required component trainer,
        required numeric number,
        required string name,
        boolean shiny      = false,
        boolean costume    = false,
        string costumetype = ''
    ) {
        var lookupParams = {
            number : arguments.number,
            name   : arguments.name,
            gender : '',
            costume: arguments.costume
        };
        if(arguments.costume && arguments.costumetype.len()) {
            lookupParams.insert('costumetype', arguments.costumetype);
        }
        var pokemon = pokemonService.get(lookupParams);

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
