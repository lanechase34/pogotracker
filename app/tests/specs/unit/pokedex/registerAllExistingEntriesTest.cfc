component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        pokemonService = getInstance("services.pokemon");
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("pokedexService.registerAll with existing entries", () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance("services.pokedex");
                trainer        = mockTrainer.make();
            });

            afterEach(() => {
                mockTrainer.delete();
            });

            it("Keeps existing flags, fills in missing entries, and invalidates the cached pokedex", () => {
                var bulbasaur  = getPokemon(1, "Bulbasaur");
                var charmander = getPokemon(4, "Charmander");

                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaur,
                    caught      = false,
                    shiny       = true,
                    hundo       = true,
                    shadow      = true,
                    shadowshiny = false
                );
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = charmander,
                    caught      = true,
                    shiny       = false,
                    hundo       = true,
                    shadow      = false,
                    shadowshiny = true
                );

                // Warm the cache so this also proves registerAll clears it
                pokedexService.getRegistered(trainer = trainer, region = "Kanto");

                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = false
                );

                // Existing uncaught entry is flipped, every other flag is preserved
                var bulbasaurRow = getRow(bulbasaur.getId());
                expect(bulbasaurRow.caught).toBeTrue();
                expect(bulbasaurRow.shiny).toBeTrue();
                expect(bulbasaurRow.hundo).toBeTrue();
                expect(bulbasaurRow.shadow).toBeTrue();
                expect(bulbasaurRow.shadowshiny).toBeFalse();

                // Already caught entry is left exactly as it was
                var charmanderRow = getRow(charmander.getId());
                expect(charmanderRow.caught).toBeTrue();
                expect(charmanderRow.shiny).toBeFalse();
                expect(charmanderRow.hundo).toBeTrue();
                expect(charmanderRow.shadowshiny).toBeTrue();

                expect(duplicateCount()).toBe(0);
                expect(uncaughtCount("Kanto", false)).toBe(0);

                // Fresh read (not the stale cached array, not stale session entities)
                ormClearSession();
                var registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = "Kanto",
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(151);

                // Running it again is a no-op - no new rows, no duplicates
                var rowsAfterFirst = rowCount();
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = false
                );
                expect(rowCount()).toBe(rowsAfterFirst);
                expect(duplicateCount()).toBe(0);
            });

            it("Shiny register only flags pokemon whose shiny is live and does not mark them caught", () => {
                pokedexService.registerAll(
                    trainer = trainer,
                    region  = "Johto",
                    shiny   = true
                );

                var rows = queryExecute(
                    "
                    SELECT pokemon.shiny AS liveshiny, pokedex.shiny, pokedex.caught
                    FROM pokedex
                    INNER JOIN pokemon ON pokemon.id = pokedex.pokemonid
                    WHERE pokedex.trainerid = :trainerid
                    ",
                    {trainerid: {value: trainer.getId(), cfsqltype: "integer"}}
                );

                // Matches registerAllTest - 99 live Johto shinies
                expect(rows.recordCount).toBe(99);
                rows.each((row) => {
                    expect(row.liveshiny).toBeTrue();
                    expect(row.shiny).toBeTrue();
                    expect(row.caught).toBeFalse();
                });
                expect(uncaughtCount("Johto", true)).toBe(0);
            });
        });
    }

    private component function getPokemon(required numeric number, required string name) {
        return pokemonService.get({
            number : arguments.number,
            name   : arguments.name,
            gender : "",
            costume: false
        })[1];
    }

    private query function getRow(required numeric pokemonid) {
        var row = queryExecute(
            "
            SELECT caught, shiny, hundo, shadow, shadowshiny
            FROM pokedex
            WHERE trainerid = :trainerid AND pokemonid = :pokemonid
            ",
            {
                trainerid: {value: trainer.getId(), cfsqltype: "integer"},
                pokemonid: {value: arguments.pokemonid, cfsqltype: "integer"}
            }
        );
        expect(row.recordCount).toBe(1);
        return row;
    }

    private numeric function rowCount() {
        return queryExecute(
            "SELECT COUNT(*) AS total FROM pokedex WHERE trainerid = :trainerid",
            {trainerid: {value: trainer.getId(), cfsqltype: "integer"}}
        ).total;
    }

    private numeric function duplicateCount() {
        return queryExecute(
            "
            SELECT pokemonid
            FROM pokedex
            WHERE trainerid = :trainerid
            GROUP BY pokemonid
            HAVING COUNT(*) > 1
            ",
            {trainerid: {value: trainer.getId(), cfsqltype: "integer"}}
        ).recordCount;
    }

    /**
     * Eligible pokemon in the region (same set registerAll targets) that still aren't caught/shiny
     */
    private numeric function uncaughtCount(required string region, required boolean shiny) {
        var flag = arguments.shiny ? "shiny" : "caught";
        return queryExecute(
            "
            SELECT COUNT(*) AS total
            FROM pokemon
            INNER JOIN generation ON generation.id = pokemon.generation
            LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id AND pokedex.trainerid = :trainerid
            WHERE generation.region = :region
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
                #arguments.shiny ? "AND pokemon.shiny = true" : ""#
                AND COALESCE(pokedex.#flag#, false) = false
            ",
            {
                trainerid: {value: trainer.getId(), cfsqltype: "integer"},
                region   : {value: arguments.region, cfsqltype: "varchar"}
            }
        ).total;
    }

}
