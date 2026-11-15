component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService  = getInstance("services.pokemon");
        pokedexService  = getInstance("services.pokedex");
        mockTrainer     = getInstance("tests.resources.mockTrainer");
        kantoGeneration = getInstance("services.generation").getFromRegion("Kanto").generation;

        // Service calls only - no login needed
        // trainer never registers anything, writer is only used by the specs that register
        trainer = mockTrainer.make(autoLogin = false);
        writer  = mockTrainer.make(autoLogin = false);

        bulbasaur = pokemonService.findPokemon({
            number : 1,
            name   : "Bulbasaur",
            gender : "",
            costume: false
        })[1];

        bulbasaurPartyHat = pokemonService.findPokemon({
            number     : 1,
            name       : "Bulbasaur",
            gender     : "",
            costume    : true,
            costumetype: "Party Hat"
        })[1];

        // Torchic is Hoenn - used to verify region filter excludes non-Kanto
        torchic = pokemonService.findPokemon({
            number : 255,
            name   : "Torchic",
            gender : "",
            costume: false
        })[1];

        // Shadow-eligible pokemon (pokemon.shadow=true means it has a shadow form)
        victreebel = pokemonService.findPokemon({number: 71, shadow: true})[1];

        // Mega pokemon (pokemon.mega=true)
        megaGengar = pokemonService.findPokemon({number: 94, mega: true})[1];

        // Giga pokemon (pokemon.giga=true)
        gigaCharizard = pokemonService.findPokemon({number: 6, giga: true})[1];

        // Form variant pokemon (pokemon.form=true)
        deerlingSpring = pokemonService.findPokemon({number: 585, form: true})[1];
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(writer.id);
        mockTrainer.deleteTrainer(trainer.id);
    }

    function run() {
        describe("pokedexService.getRegistered", () => {
            it("Default call excludes costume, mega, and giga pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                var allIds = registered.map((entry) => entry.id);

                // Normal pokemon should be present
                expect(allIds).toContain(bulbasaur.id);

                // Costume, mega, and giga variants are excluded by the WHERE clause
                expect(allIds).notToContain(bulbasaurPartyHat.id);
                expect(allIds).notToContain(megaGengar.id);
                expect(allIds).notToContain(gigaCharizard.id);
            });

            it("Unregistered pokemon have a null pokedex entry", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                var bulbasaurEntry = registered.filter((entry) => entry.id == bulbasaur.id);
                expect(bulbasaurEntry).toBeArray();
                expect(bulbasaurEntry.len()).toBe(1);
                expect(bulbasaurEntry[1]).toBeStruct();
                expect(bulbasaurEntry[1].registered).toBeFalse();
                expect(bulbasaurEntry[1].dex_caught).toBeFalse();
                expect(bulbasaurEntry[1].dex_shiny).toBeFalse();
            });

            it("Filters results to the given region only", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                var allIds = registered.map((entry) => entry.id);

                // Kanto pokemon should appear
                expect(allIds).toContain(bulbasaur.id);

                // Hoenn pokemon should be absent
                expect(allIds).notToContain(torchic.id);

                // Every result should belong to Kanto
                registered.each((entry) => {
                    expect(entry.generation).toBe(kantoGeneration);
                });
            });

            it("costume=true returns only costume pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false,
                    costume        = true
                );

                var allIds = registered.map((entry) => entry.id);

                // Costume variant should be present
                expect(allIds).toContain(bulbasaurPartyHat.id);

                // Normal variant should be absent
                expect(allIds).notToContain(bulbasaur.id);

                // All results must be costume
                registered.each((entry) => {
                    expect(entry.costume).toBeTrue();
                });
            });

            it("mega=true returns only mega pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = true,
                    shadow         = false,
                    giga           = false
                );

                var allIds = registered.map((entry) => entry.id);

                // Mega Gengar should be present
                expect(allIds).toContain(megaGengar.id);

                // Normal Bulbasaur should be absent
                expect(allIds).notToContain(bulbasaur.id);

                // All results must be mega
                registered.each((entry) => {
                    expect(entry.mega).toBeTrue();
                });
            });

            it("giga=true returns only giga pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = true
                );

                var allIds = registered.map((entry) => entry.id);

                // Giga Charizard should be present
                expect(allIds).toContain(gigaCharizard.id);

                // Normal Bulbasaur should be absent
                expect(allIds).notToContain(bulbasaur.id);

                // All results must be giga
                registered.each((entry) => {
                    expect(entry.giga).toBeTrue();
                });
            });

            it("shadow=true returns only shadow-eligible pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    alternateForms = false,
                    mega           = false,
                    shadow         = true,
                    giga           = false
                );

                var allIds = registered.map((entry) => entry.id);

                // Shadow-eligible pokemon should be present
                expect(allIds).toContain(victreebel.id);

                // All results must have shadow=true
                registered.each((entry) => {
                    expect(entry.shadow).toBeTrue();
                });
            });

            it("form=true returns only form variant pokemon", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    alternateForms = true,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                var allIds = registered.map((entry) => entry.id);

                // Form variant should be present
                expect(allIds).toContain(deerlingSpring.id);

                // Normal Bulbasaur (not a form) should be absent
                expect(allIds).notToContain(bulbasaur.id);

                // All results must be form variants
                registered.each((entry) => {
                    expect(entry.form).toBeTrue();
                });
            });

            it("Results are ordered by generation, number, form, name", () => {
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                // First result should be the lowest generation and lowest number
                var firstEntry = registered[1];
                var lastEntry  = registered[registered.len()];

                expect(firstEntry.generation).toBeLTE(lastEntry.generation);
                expect(firstEntry.number).toBeLTE(lastEntry.number);
            });

            // Each spec registers what it asserts on, so they hold in any order
            describe("After registering", () => {
                it("Registered pokemon have a populated entry with correct caught and shiny status", () => {
                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = bulbasaur,
                        caught      = true,
                        shiny       = true,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    var registered = pokedexService.getRegistered(
                        trainerid      = writer.id,
                        region         = "Kanto",
                        alternateForms = false,
                        mega           = false,
                        shadow         = false,
                        giga           = false
                    );

                    var bulbasaurEntry = registered.filter((entry) => entry.id == bulbasaur.id);
                    expect(bulbasaurEntry[1].registered).toBeTrue();
                    expect(bulbasaurEntry[1].dex_caught).toBeTrue();
                    expect(bulbasaurEntry[1].dex_shiny).toBeTrue();
                });

                it("Registrations are isolated per trainer and do not affect other trainers", () => {
                    // Register Bulbasaur for the writer only
                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = bulbasaur,
                        caught      = true,
                        shiny       = false,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    // The other trainer should see Bulbasaur as unregistered
                    var registeredForOther = pokedexService.getRegistered(
                        trainerid      = trainer.id,
                        region         = "Kanto",
                        alternateForms = false,
                        mega           = false,
                        shadow         = false,
                        giga           = false
                    );

                    var bulbasaurEntryForOther = registeredForOther.filter((entry) => entry.id == bulbasaur.id);
                    expect(bulbasaurEntryForOther[1].registered).toBeFalse();

                    // The writer should still see Bulbasaur as registered
                    var registeredForWriter = pokedexService.getRegistered(
                        trainerid      = writer.id,
                        region         = "Kanto",
                        alternateForms = false,
                        mega           = false,
                        shadow         = false,
                        giga           = false
                    );

                    var bulbasaurEntryForWriter = registeredForWriter.filter((entry) => entry.id == bulbasaur.id);
                    expect(bulbasaurEntryForWriter[1].registered).toBeTrue();
                    expect(bulbasaurEntryForWriter[1].dex_caught).toBeTrue();
                });
            });
        });
    }

}
