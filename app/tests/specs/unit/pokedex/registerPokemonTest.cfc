component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
        pokedexService = getInstance("services.pokedex");
        mockTrainer    = getInstance("tests.resources.mockTrainer");
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("pokedexService.register", () => {
            // Each spec counts the trainer's whole dex, so each gets a fresh trainer - service calls only, no login needed
            beforeEach(() => {
                trainer = mockTrainer.make(autoLogin = false);
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });

            it("Can register a pokemon (gyarados)", () => {
                var gyaradosCfc = pokemonService.findPokemon({
                    number : 130,
                    name   : "Gyarados",
                    gender : "",
                    costume: false
                })[1];
                expect(gyaradosCfc).toBeStruct();
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = gyaradosCfc,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);
            });

            it("Only writes the flags passed, so a stale page can't undo another change", () => {
                var dragonite = pokemonService.findPokemon({
                    number : 149,
                    name   : "Dragonite",
                    gender : "",
                    costume: false
                })[1];

                // First write creates the entry - flags not passed start false
                pokedexService.register(
                    trainerid = trainer.id,
                    pokemon   = dragonite,
                    shiny     = true
                );
                var entry = testData.findRow("pokedex", {trainerid: trainer.id, pokemonid: dragonite.id});
                expect(entry.shiny).toBeTrue();
                expect(entry.caught).toBeFalse();

                // Marking caught from another view keeps the shiny
                pokedexService.register(
                    trainerid = trainer.id,
                    pokemon   = dragonite,
                    caught    = true
                );
                entry = testData.findRow("pokedex", {trainerid: trainer.id, pokemonid: dragonite.id});
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeTrue();
            });

            it("Can register a pokemon (mewtwo) normal and then also shiny", () => {
                var mewtwoCfc = pokemonService.findPokemon({
                    number : 150,
                    name   : "Mewtwo",
                    gender : "",
                    costume: false
                })[1];
                expect(mewtwoCfc).toBeStruct();
                // Normal entry
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = mewtwoCfc,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );
                // Update to shiny too
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = mewtwoCfc,
                    caught      = true,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );

                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(1);
            });

            it("Can register a costume form (charizard party hat) and also a shiny and will not collide with other forms", () => {
                var charizard = pokemonService.findPokemon({
                    number : 6,
                    name   : "Charizard",
                    gender : "",
                    costume: false
                })[1];

                var charizardPartyHat = pokemonService.findPokemon({
                    number     : 6,
                    name       : "Charizard",
                    gender     : "",
                    costume    : true,
                    costumetype: "Party Hat"
                })[1];

                var charizardPikaVisor = pokemonService.findPokemon({
                    number     : 6,
                    name       : "Charizard",
                    gender     : "",
                    costume    : true,
                    costumetype: "Pikachu Visor"
                })[1];

                // Register party hat
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = charizardPartyHat,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Normal charizard should not be affected
                // Normal kanto dex should be 0 registered
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(0);

                // Costume dex should have 1 entry
                registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false,
                    costume        = true
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(1);

                // Register normal charizard
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = charizard,
                    caught      = true,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Register pika visor
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = charizardPikaVisor,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Register shiny party hat
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = charizardPartyHat,
                    caught      = false,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                // Costume dex should have 2 entries
                registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false,
                    costume        = true
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(2);

                // Shiny costume dex should have 1 entry
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(1);
            });
        });
    }

}
