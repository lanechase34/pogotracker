component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        pokemonService = getInstance("services.pokemon");
        pokedexService = getInstance("services.pokedex");
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("pokedexService.registerAll", () => {
            // Every spec counts the trainer's whole pokedex, so each gets a fresh trainer - service calls only, no login needed
            beforeEach(() => {
                trainer = mockTrainer.make(autoLogin = false);
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });

            it("Keeps existing flags, fills in missing entries, and invalidates the cached pokedex", () => {
                var bulbasaur  = getPokemon(1, "Bulbasaur");
                var charmander = getPokemon(4, "Charmander");

                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = bulbasaur,
                    caught      = false,
                    shiny       = true,
                    hundo       = true,
                    shadow      = true,
                    shadowshiny = false
                );
                pokedexService.register(
                    trainerid   = trainer.id,
                    pokemon     = charmander,
                    caught      = true,
                    shiny       = false,
                    hundo       = true,
                    shadow      = false,
                    shadowshiny = true
                );

                // Warm the cache so this also proves registerAll clears it
                pokedexService.getRegistered(trainerid = trainer.id, region = "Kanto");

                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Kanto",
                    shiny     = false
                );

                // Existing uncaught entry is flipped, every other flag is preserved
                var bulbasaurRow = getRow(bulbasaur.id);
                expect(bulbasaurRow.caught).toBeTrue();
                expect(bulbasaurRow.shiny).toBeTrue();
                expect(bulbasaurRow.hundo).toBeTrue();
                expect(bulbasaurRow.shadow).toBeTrue();
                expect(bulbasaurRow.shadowshiny).toBeFalse();

                // Already caught entry is left exactly as it was
                var charmanderRow = getRow(charmander.id);
                expect(charmanderRow.caught).toBeTrue();
                expect(charmanderRow.shiny).toBeFalse();
                expect(charmanderRow.hundo).toBeTrue();
                expect(charmanderRow.shadowshiny).toBeTrue();

                expect(duplicateCount()).toBe(0);
                expect(uncaughtCount("Kanto", false)).toBe(0);

                // Same cache key as the warm read above - registerAll must have cleared it
                var registered = pokedexService.getRegistered(
                    trainerid      = trainer.id,
                    region         = "Kanto",
                    alternateForms = false,
                    mega           = false,
                    shadow         = false,
                    giga           = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(151);

                // Running it again is a no-op - no new rows, no duplicates
                var rowsAfterFirst = testData.countRows("pokedex", {trainerid: trainer.id});
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Kanto",
                    shiny     = false
                );
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(rowsAfterFirst);
                expect(duplicateCount()).toBe(0);
            });

            it("Shiny register only flags pokemon whose shiny is live and does not mark them caught", () => {
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Johto",
                    shiny     = true
                );

                var rows = queryExecute(
                    "
                    SELECT pokemon.shiny AS liveshiny, pokedex.shiny, pokedex.caught
                    FROM pokedex
                    INNER JOIN pokemon ON pokemon.id = pokedex.pokemonid
                    WHERE pokedex.trainerid = :trainerid
                    ",
                    {trainerid: {value: trainer.id, cfsqltype: "integer"}}
                );

                // 99 live Johto shinies - unown is not in the Johto dex, it has its own unown dex
                expect(rows.recordCount).toBe(99);
                rows.each((row) => {
                    expect(row.liveshiny).toBeTrue();
                    expect(row.shiny).toBeTrue();
                    expect(row.caught).toBeFalse();
                });
                expect(uncaughtCount("Johto", true)).toBe(0);

                // And the pokedex read sees them as shiny
                var registered = pokedexService.getRegistered(trainerid = trainer.id, region = "Johto");
                expect(pokedexHelperFunctions.countRegistered(registered, true)).toBe(99);
            });

            it("Registers only normal pokemon, not costume pokemon", () => {
                pokedexService.registerAll(
                    trainerid = trainer.id,
                    region    = "Hoenn",
                    shiny     = false
                );

                // 141 Hoenn pokemon + forms
                var registered = pokedexService.getRegistered(trainerid = trainer.id, region = "Hoenn");
                expect(pokedexHelperFunctions.countRegistered(registered)).toBe(141);

                // Costume Hoenn pokemon should not be registered at all
                var costumeRegistered = pokedexService.getRegistered(
                    trainerid = trainer.id,
                    region    = "Hoenn",
                    costume   = true
                );
                expect(pokedexHelperFunctions.countRegistered(costumeRegistered)).toBe(0);

                // No pokedex row was written for specific costume pokemon
                expect(pokedexRows(getPokemon(265, "Wurmple", "Party Hat").id).recordCount).toBe(0);
                expect(pokedexRows(getPokemon(302, "Sableye", "Halloween").id).recordCount).toBe(0);
            });
        });
    }

    private struct function getPokemon(
        required numeric number,
        required string name,
        string costumetype = ""
    ) {
        var filter = {
            number : arguments.number,
            name   : arguments.name,
            gender : "",
            costume: arguments.costumetype.len() > 0
        };
        if(arguments.costumetype.len()) {
            filter.costumetype = arguments.costumetype;
        }
        return pokemonService.findPokemon(filter)[1];
    }

    private query function getRow(required numeric pokemonid) {
        var row = pokedexRows(arguments.pokemonid);
        expect(row.recordCount).toBe(1);
        return row;
    }

    /**
     * The trainer's pokedex rows for this pokemon
     */
    private query function pokedexRows(required numeric pokemonid) {
        return queryExecute(
            "
            SELECT caught, shiny, hundo, shadow, shadowshiny
            FROM pokedex
            WHERE trainerid = :trainerid AND pokemonid = :pokemonid
            ",
            {
                trainerid: {value: trainer.id, cfsqltype: "integer"},
                pokemonid: {value: arguments.pokemonid, cfsqltype: "integer"}
            }
        );
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
            {trainerid: {value: trainer.id, cfsqltype: "integer"}}
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
                trainerid: {value: trainer.id, cfsqltype: "integer"},
                region   : {value: arguments.region, cfsqltype: "varchar"}
            }
        ).total;
    }

}
