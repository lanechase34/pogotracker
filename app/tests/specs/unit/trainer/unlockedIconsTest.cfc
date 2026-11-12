component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        trainerService = getInstance("services.trainer");
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Mark the first `count` Kanto base species caught - the partial progress register all can't give
     */
    private void function catchKanto(required component trainer, required numeric count) {
        queryExecute(
            "
            INSERT INTO pokedex (trainerid, pokemonid, caught, shiny, created, updated)
            SELECT :trainerid, pokemon.id, true, false, now(), now()
            FROM pokemon
            WHERE pokemon.generation = 1
                AND pokemon.form = false
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
            ORDER BY pokemon.number
            LIMIT :count
            ",
            {
                trainerid: {value: arguments.trainer.getId(), cfsqltype: "integer"},
                count    : {value: arguments.count, cfsqltype: "integer"}
            }
        );
    }

    function run() {
        describe("trainer.getUnlockedIcons", () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance("services.pokedex");
                trainer        = mockTrainer.make(securityLevel = 10, autoLogin = false);
            });

            afterEach(() => {
                mockTrainer.delete(trainer.getId());
            });

            it("Unlocks nothing for a new trainer", () => {
                expect(trainer.getUnlockedIcons()).toBeEmpty();
            });

            it("Unlocks the Kanto starter evolutions at 38 caught, but not the later goals", () => {
                catchKanto(trainer, 40);

                var icons = trainer.getUnlockedIcons();
                expect(icons).toBe(["Ivysaur", "Charmeleon", "Wartortle"]);
            });

            it("Unlocks the Kanto birds at 114 caught, but not Mewtwo", () => {
                catchKanto(trainer, 120);

                var icons = trainer.getUnlockedIcons();
                expect(icons).toInclude("Venusaur");
                expect(icons).toInclude("Articuno");
                expect(icons).toInclude("Zapdos");
                expect(icons).toInclude("Moltres");
                expect(icons).notToInclude("Mewtwo");
            });

            it("Unlocks Mewtwo for a complete Kanto dex - alternate forms don't stop it", () => {
                // Register all includes Alolan/Galarian forms, which used to push the count past an exact 151
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = false
                );

                var icons = trainer.getUnlockedIcons();
                expect(icons).toInclude("Mewtwo");
                expect(icons).notToInclude("Mew");
                expect(icons).notToInclude("Shiny Mew");
            });

            it("Unlocks Mew and Shiny Mew for a complete Kanto shiny dex", () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = true
                );

                var icons = trainer.getUnlockedIcons();
                expect(icons).toInclude("Mew");
                expect(icons).toInclude("Shiny Mew");
                // Shinies registered alone are not caught entries
                expect(icons).notToInclude("Ivysaur");
            });

            it("Unlocks Celebi and Shiny Celebi for a complete Johto dex", () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Johto",
                    shiny   = false
                );
                expect(trainer.getUnlockedIcons()).toBe(["Lugia", "Ho-Oh", "Celebi"]);

                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Johto",
                    shiny   = true
                );
                expect(trainer.getUnlockedIcons()).toBe(["Lugia", "Ho-Oh", "Celebi", "Shiny Celebi"]);
            });

            it("Unlocks Unown for every Unown form", () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Unown",
                    shiny   = false
                );
                expect(trainer.getUnlockedIcons()).toBe(["Unown"]);
            });

            it("Unlocks Deoxys and Shiny Deoxys for a complete Hoenn dex", () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Hoenn",
                    shiny   = false
                );
                expect(trainer.getUnlockedIcons()).toBe(["Deoxys"]);

                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Hoenn",
                    shiny   = true
                );
                expect(trainer.getUnlockedIcons()).toBe(["Deoxys", "Shiny Deoxys"]);
            });

            it("Lets the trainer pick an unlocked icon whose name has a space", () => {
                expect(trainerService.isAllowedIcon("shinymew", trainer)).toBeFalse();

                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = true
                );
                expect(trainerService.isAllowedIcon("shinymew", trainer)).toBeTrue();
            });
        });
    }

}
