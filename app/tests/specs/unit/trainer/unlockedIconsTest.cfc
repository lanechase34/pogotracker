component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        pokedexService = getInstance("services.pokedex");
        trainerService = getInstance("services.trainer");
        // Unlocks are read straight from the pokedex table, so one trainer with its pokedex cleared per spec is enough
        trainer        = mockTrainer.make(securityLevel = 10, autoLogin = false);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);
    }

    /**
     * Mark the first `caughtCount` Kanto base species caught - the partial progress register all can't give
     */
    private void function catchKanto(required struct trainer, required numeric caughtCount) {
        queryExecute(
            "
            INSERT INTO pokedex (trainerid, pokemonid, caught, shiny)
            SELECT :trainerid, pokemon.id, true, false
            FROM pokemon
            WHERE pokemon.generation = 1
                AND pokemon.form = false
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
            ORDER BY pokemon.number ASC
            LIMIT :caughtCount
            ",
            {
                trainerid  : {value: arguments.trainer.id, cfsqltype: "integer"},
                caughtCount: {value: arguments.caughtCount, cfsqltype: "integer"}
            }
        );
    }

    function run() {
        describe("trainer.getUnlockedIcons", () => {
            beforeEach(() => {
                setup();
                testData.deleteRows("pokedex", {trainerid: trainer.id});
            });

            it("Unlocks nothing for a new trainer", () => {
                expect(trainerService.getUnlockedIcons(trainer.id)).toBeEmpty();
            });

            it("Unlocks the Kanto starter evolutions at 38 caught, but not the later goals", () => {
                catchKanto(trainer, 40);

                var icons = trainerService.getUnlockedIcons(trainer.id);
                expect(icons).toBe(["Ivysaur", "Charmeleon", "Wartortle"]);
            });

            it("Unlocks the Kanto birds at 114 caught, but not Mewtwo", () => {
                catchKanto(trainer, 120);

                var icons = trainerService.getUnlockedIcons(trainer.id);
                expect(icons).toInclude("Venusaur");
                expect(icons).toInclude("Articuno");
                expect(icons).toInclude("Zapdos");
                expect(icons).toInclude("Moltres");
                expect(icons).notToInclude("Mewtwo");
            });

            it("Unlocks Mewtwo for a complete Kanto dex - alternate forms don't stop it", () => {
                // Register all includes Alolan/Galarian forms, which used to push the count past an exact 151
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Kanto",
                    shiny     = false
                );

                var icons = trainerService.getUnlockedIcons(trainer.id);
                expect(icons).toInclude("Mewtwo");
                expect(icons).notToInclude("Mew");
                expect(icons).notToInclude("Shiny Mew");
            });

            it("Unlocks Mew and Shiny Mew for a complete Kanto shiny dex - and lets the trainer pick Shiny Mew", () => {
                // An unlocked icon whose name has a space
                expect(trainerService.isAllowedIcon("shinymew", trainer.id)).toBeFalse();

                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Kanto",
                    shiny     = true
                );

                var icons = trainerService.getUnlockedIcons(trainer.id);
                expect(icons).toInclude("Mew");
                expect(icons).toInclude("Shiny Mew");
                // Shinies registered alone are not caught entries
                expect(icons).notToInclude("Ivysaur");

                expect(trainerService.isAllowedIcon("shinymew", trainer.id)).toBeTrue();
            });

            it("Unlocks Celebi and Shiny Celebi for a complete Johto dex", () => {
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Johto",
                    shiny     = false
                );
                expect(trainerService.getUnlockedIcons(trainer.id)).toBe(["Lugia", "Ho-Oh", "Celebi"]);

                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Johto",
                    shiny     = true
                );
                expect(trainerService.getUnlockedIcons(trainer.id)).toBe(["Lugia", "Ho-Oh", "Celebi", "Shiny Celebi"]);
            });

            it("Unlocks Unown for every Unown form", () => {
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Unown",
                    shiny     = false
                );
                expect(trainerService.getUnlockedIcons(trainer.id)).toBe(["Unown"]);
            });

            it("Unlocks Deoxys and Shiny Deoxys for a complete Hoenn dex", () => {
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Hoenn",
                    shiny     = false
                );
                expect(trainerService.getUnlockedIcons(trainer.id)).toBe(["Deoxys"]);

                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Hoenn",
                    shiny     = true
                );
                expect(trainerService.getUnlockedIcons(trainer.id)).toBe(["Deoxys", "Shiny Deoxys"]);
            });
        });
    }

}
