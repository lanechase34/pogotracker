component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
        pokedexService = getInstance("services.pokedex");
        mockTrainer    = getInstance("tests.resources.mockTrainer");

        // Service calls only - no login needed. Never registers anything, shared by the read only specs
        trainer = mockTrainer.make(autoLogin = false);

        // Plain, live, tradable, non-form pokemon
        bulbasaur = pokemonService.findPokemon({
            number : 1,
            mega   : false,
            giga   : false,
            costume: false
        })[1];
        victreebel = pokemonService.findPokemon({number: 71, mega: false})[1];
        torchic    = pokemonService.findPokemon({number: 255, costume: false})[1];

        // Form variant pokemon (form=true) - number should be used instead of name
        deerlingSpring = pokemonService.findPokemon({number: 585, form: true})[1];

        // Mega/giga variants have their own distinct name and are always tradable=false,
        // but are also excluded outright by the WHERE clause (mega=false/giga=false)
        megaGengar    = pokemonService.findPokemon({number: 94, mega: true})[1];
        gigaCharizard = pokemonService.findPokemon({number: 6, giga: true})[1];

        // Costume variant shares its name with the base pokemon, but is excluded via costume=false
        bulbasaurPartyHat = pokemonService.findPokemon({
            number     : 1,
            name       : "Bulbasaur",
            gender     : "",
            costume    : true,
            costumetype: "Party Hat"
        })[1];

        // Mythical - tradable=false, otherwise a normal live/non-form pokemon
        mew = pokemonService.findPokemon({number: 151})[1];

        // Not yet live in-game
        zeraora = pokemonService.findPokemon({number: 807})[1];

        // Live and tradable, but shiny is not yet released
        morpeko = pokemonService.findPokemon({number: 877})[1];
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);
    }

    function run() {
        describe("pokedexService.getMissingString", () => {
            it("Prefixes non-form pokemon with + when missing from the caught dex", () => {
                var missingCaught = pokedexService.getMissingString(trainer.id, false);
                var items         = listToArray(missingCaught, ",");

                expect(items).toContain("+#bulbasaur.name#");
                expect(items).toContain("+#victreebel.name#");
            });

            it("Uses the plain number (no +) for form-variant pokemon that are missing", () => {
                var missingCaught = pokedexService.getMissingString(trainer.id, false);
                var items         = listToArray(missingCaught, ",");

                expect(items).toContain("#deerlingSpring.number#");
                // No '+' for numbers
                expect(items.some((item) => compare(item, "+#deerlingSpring.number#") == 0)).toBeFalse();
            });

            it("Excludes pokemon that are not yet live even if uncaught", () => {
                var missingCaught = pokedexService.getMissingString(trainer.id, false);
                var items         = listToArray(missingCaught, ",");

                expect(items).notToContain("+#zeraora.name#");
            });

            it("Excludes pokemon that are not tradable even if uncaught", () => {
                var missingCaught = pokedexService.getMissingString(trainer.id, false);
                var items         = listToArray(missingCaught, ",");

                expect(items).notToContain("+#mew.name#");
            });

            it("Excludes mega, giga, and unown regardless of catch status", () => {
                var missingCaught = pokedexService.getMissingString(trainer.id, false);
                var items         = listToArray(missingCaught, ",");

                expect(items).notToContain("+#megaGengar.name#");
                expect(items).notToContain("+#gigaCharizard.name#");
                expect(items).notToContain("201");
            });

            it("Returns the shiny missing string prefixed with 'shiny&' and excludes pokemon without a shiny release", () => {
                var missingShiny = pokedexService.getMissingString(trainer.id, true);

                expect(left(missingShiny, 6)).toBe("shiny&");

                var items = listToArray(replace(missingShiny, "shiny&", "", "one"), ",");
                expect(items).notToContain("+#morpeko.name#");
                expect(items).toContain("+#bulbasaur.name#");
            });

            // These register pokemon, so each gets a fresh trainer
            describe("After registering", () => {
                beforeEach(() => {
                    writer = mockTrainer.make(autoLogin = false);
                });

                afterEach(() => {
                    mockTrainer.deleteTrainer(writer.id);
                });

                it("Excludes pokemon the trainer has already caught", () => {
                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = bulbasaur,
                        caught      = true,
                        shiny       = false,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    var missingCaught = pokedexService.getMissingString(writer.id, false);
                    var items         = listToArray(missingCaught, ",");

                    expect(items).notToContain("+#bulbasaur.name#");
                    // Still-uncaught pokemon should remain, proving the list isn't just empty
                    expect(items).toContain("+#victreebel.name#");
                });

                it("Excludes costume pokemon and catching a costume does not affect the base pokemon", () => {
                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = bulbasaurPartyHat,
                        caught      = true,
                        shiny       = false,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    var missingCaught = pokedexService.getMissingString(writer.id, false);
                    var items         = listToArray(missingCaught, ",");

                    // Base Bulbasaur is unaffected by registering its costume variant
                    expect(items).toContain("+#bulbasaur.name#");
                });

                it("Excludes pokemon whose shiny has already been registered", () => {
                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = bulbasaur,
                        caught      = false,
                        shiny       = true,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    var missingShiny = pokedexService.getMissingString(writer.id, true);
                    var items        = listToArray(replace(missingShiny, "shiny&", "", "one"), ",");

                    expect(items).notToContain("+#bulbasaur.name#");
                    expect(items).toContain("+#victreebel.name#");
                });

                it("Caches the result and invalidates the cache after a new registration", () => {
                    var first      = pokedexService.getMissingString(writer.id, false);
                    var secondCall = pokedexService.getMissingString(writer.id, false);
                    expect(secondCall).toBe(first);

                    pokedexService.register(
                        trainerid   = writer.id,
                        pokemon     = torchic,
                        caught      = true,
                        shiny       = false,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );

                    var third = pokedexService.getMissingString(writer.id, false);
                    expect(third).notToBe(first);
                    expect(listToArray(third, ",")).notToContain("+#torchic.name#");
                });
            });
        });
    }

}
