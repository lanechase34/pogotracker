component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
        mockTrainer    = getInstance('tests.resources.mocktrainer');

        bulbasaur = pokemonService.get({
            number : 1,
            name   : 'Bulbasaur',
            gender : '',
            costume: false
        })[1];

        bulbasaurPartyHat = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Party Hat'
        })[1];

        // Torchic is Hoenn — used to verify region filter excludes non-Kanto
        torchic = pokemonService.get({
            number : 255,
            name   : 'Torchic',
            gender : '',
            costume: false
        })[1];

        // Shadow-eligible pokemon (pokemon.shadow=true means it has a shadow form)
        victreebel = pokemonService.get({number: 71, shadow: true})[1];

        // Mega pokemon (mega=true on the entity)
        megaGengar = pokemonService.get({number: 94, mega: true})[1];

        // Giga pokemon (giga=true on the entity)
        gigaCharizard = pokemonService.get({number: 6, giga: true})[1];

        // Form variant pokemon (form=true on the entity)
        deerlingSpring = pokemonService.get({number: 585, form: true})[1];
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.getRegistered', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make(autoLogin = false);
            });

            afterEach(() => {
                mockTrainer.delete();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Default call excludes costume, mega, and giga pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Normal pokemon should be present
                expect(allIds).toContain(bulbasaur.getId());

                // Costume, mega, and giga variants are excluded by the WHERE clause
                expect(allIds).notToContain(bulbasaurPartyHat.getId());
                expect(allIds).notToContain(megaGengar.getId());
                expect(allIds).notToContain(gigaCharizard.getId());
            });

            it('Unregistered pokemon have a null pokedex entry', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                bulbasaurEntry = registered.filter((entry) => entry[1].getId() == bulbasaur.getId());
                expect(bulbasaurEntry).toBeArray();
                expect(bulbasaurEntry.len()).toBe(1);
                expect(bulbasaurEntry[1]).toBeArray();
                expect(len(bulbasaurEntry[1])).toBe(2);
                expect(isNull(bulbasaurEntry[1][2])).toBeTrue();
            });

            it('Registered pokemon have a populated entry with correct caught and shiny status', () => {
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaur,
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

                bulbasaurEntry = registered.filter((entry) => entry[1].getId() == bulbasaur.getId());
                expect(bulbasaurEntry[1][2]).notToBeNull();
                expect(bulbasaurEntry[1][2].getCaught()).toBeTrue();
                expect(bulbasaurEntry[1][2].getShiny()).toBeTrue();
            });

            it('Filters results to the given region only', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Kanto pokemon should appear
                expect(allIds).toContain(bulbasaur.getId());

                // Hoenn pokemon should be absent
                expect(allIds).notToContain(torchic.getId());

                // Every result should belong to Kanto
                registered.each((entry) => {
                    expect(entry[1].getGeneration().getRegion()).toBe('Kanto');
                });
            });

            it('costume=true returns only costume pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false,
                    costume = true
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Costume variant should be present
                expect(allIds).toContain(bulbasaurPartyHat.getId());

                // Normal variant should be absent
                expect(allIds).notToContain(bulbasaur.getId());

                // All results must be costume
                registered.each((entry) => {
                    expect(entry[1].getCostume()).toBeTrue();
                });
            });

            it('mega=true returns only mega pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = true,
                    shadow  = false,
                    giga    = false
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Mega Gengar should be present
                expect(allIds).toContain(megaGengar.getId());

                // Normal Bulbasaur should be absent
                expect(allIds).notToContain(bulbasaur.getId());

                // All results must be mega
                registered.each((entry) => {
                    expect(entry[1].getMega()).toBeTrue();
                });
            });

            it('giga=true returns only giga pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = true
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Giga Charizard should be present
                expect(allIds).toContain(gigaCharizard.getId());

                // Normal Bulbasaur should be absent
                expect(allIds).notToContain(bulbasaur.getId());

                // All results must be giga
                registered.each((entry) => {
                    expect(entry[1].getGiga()).toBeTrue();
                });
            });

            it('shadow=true returns only shadow-eligible pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    form    = false,
                    mega    = false,
                    shadow  = true,
                    giga    = false
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Shadow-eligible pokemon should be present
                expect(allIds).toContain(victreebel.getId());

                // All results must have shadow=true
                registered.each((entry) => {
                    expect(entry[1].getShadow()).toBeTrue();
                });
            });

            it('form=true returns only form variant pokemon', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    form    = true,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                allIds = registered.map((entry) => entry[1].getId());

                // Form variant should be present
                expect(allIds).toContain(deerlingSpring.getId());

                // Normal Bulbasaur (not a form) should be absent
                expect(allIds).notToContain(bulbasaur.getId());

                // All results must be form variants
                registered.each((entry) => {
                    expect(entry[1].getForm()).toBeTrue();
                });
            });

            it('Results are ordered by generation, number, form, name', () => {
                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                // First result should be the lowest generation and lowest number
                firstEntry = registered[1][1];
                lastEntry  = registered[registered.len()][1];

                expect(firstEntry.getGeneration().getGeneration()).toBeLTE(lastEntry.getGeneration().getGeneration());
                expect(firstEntry.getNumber()).toBeLTE(lastEntry.getNumber());
            });

            it('Registrations are isolated per trainer and do not affect other trainers', () => {
                trainerAId = trainer.getId();
                trainerB   = mockTrainer.make(autoLogin = false);
                trainerBId = trainerB.getId();

                // Register Bulbasaur for trainer A only
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaur,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Trainer B should see Bulbasaur as unregistered
                registeredForB = pokedexService.getRegistered(
                    trainer = trainerB,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                bulbasaurEntryForB = registeredForB.filter((entry) => entry[1].getId() == bulbasaur.getId());
                expect(isNull(bulbasaurEntryForB[1][2])).toBeTrue();

                // Trainer A should still see Bulbasaur as registered
                registeredForA = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );

                bulbasaurEntryForA = registeredForA.filter((entry) => entry[1].getId() == bulbasaur.getId());
                expect(bulbasaurEntryForA[1][2]).notToBeNull();
                expect(bulbasaurEntryForA[1][2].getCaught()).toBeTrue();

                // Clean up trainer B and restore session so afterEach can clean up trainer A
                mockTrainer.delete(trainerBId);
                session.mocktrainerid = trainerAId;
            });
        });
    }

}
