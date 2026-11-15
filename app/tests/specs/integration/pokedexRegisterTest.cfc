component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        pokemonService = getInstance("services.pokemon");

        bulbasaur = getPokemon(1, "Bulbasaur");
        dragonite = getPokemon(149, "Dragonite");

        // The trainer a spoofed trainerid points at - never registers anything itself
        otherTrainer = mockTrainer.make(autoLogin = false);
        session.delete("mocktrainerid");
    }

    function afterAll() {
        mockTrainer.deleteTrainer(otherTrainer.id);
        super.afterAll();
    }

    /**
     * POST to a pokedex action and parse its JSON response
     */
    private struct function postPokedex(required string action, required struct params) {
        setup();
        var event = post(route = "/pokedex/#arguments.action#", params = arguments.params);
        return {
            event     : event,
            statusCode: event.getStatusCode(),
            response  : deserializeJSON(event.getRenderedContent())
        };
    }

    private struct function getPokemon(required numeric number, required string name) {
        return pokemonService.findPokemon({
            number : arguments.number,
            name   : arguments.name,
            gender : "",
            costume: false
        })[1];
    }

    /**
     * The trainer's pokedex row for this pokemon, empty struct when there is none
     */
    private struct function getEntry(required numeric trainerid, required numeric pokemonid) {
        return testData.findRow("pokedex", {trainerid: arguments.trainerid, pokemonid: arguments.pokemonid});
    }

    /**
     * Eligible pokemon in the region (the set registerAll targets) the trainer has not caught/shiny registered
     */
    private numeric function missingCount(
        required numeric trainerid,
        required string region,
        required boolean shiny
    ) {
        var flag = arguments.shiny ? "shiny" : "caught";
        return queryExecute(
            "
            SELECT COUNT(*) AS total
            FROM pokemon
            INNER JOIN generation ON generation.generation = pokemon.generation
            LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id
                AND pokedex.trainerid = :trainerid
            WHERE generation.region = :region
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
                #arguments.shiny ? "AND pokemon.shiny = true" : ""#
                AND COALESCE(pokedex.#flag#, false) = false
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                region   : {value: arguments.region, cfsqltype: "varchar"}
            }
        ).total;
    }

    function run() {
        describe("POST /pokedex/register", () => {
            beforeEach(() => {
                trainer = mockTrainer.makeSignedIn();
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });

            it("Registers the pokemon to the signed in trainer", () => {
                var result = postPokedex("register", {pokemonid: bulbasaur.id, caught: true});

                expect(result.statusCode).toBe(200);
                expect(result.response.success).toBeTrue();

                var entry = getEntry(trainer.id, bulbasaur.id);
                expect(entry).notToBeEmpty();
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeFalse();
                expect(entry.hundo).toBeFalse();
                expect(entry.shadow).toBeFalse();
                expect(entry.shadowshiny).toBeFalse();
            });

            it("Only writes the flags sent, so a stale view can't undo another change", () => {
                expect(postPokedex("register", {pokemonid: dragonite.id, shiny: true}).response.success).toBeTrue();
                expect(postPokedex("register", {pokemonid: dragonite.id, caught: true}).response.success).toBeTrue();

                var entry = getEntry(trainer.id, dragonite.id);
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeTrue();
            });

            it("Can clear a flag without touching the others", () => {
                postPokedex(
                    "register",
                    {
                        pokemonid: dragonite.id,
                        caught   : true,
                        hundo    : true
                    }
                );
                var result = postPokedex("register", {pokemonid: dragonite.id, hundo: false});

                expect(result.response.success).toBeTrue();
                var entry = getEntry(trainer.id, dragonite.id);
                expect(entry.caught).toBeTrue();
                expect(entry.hundo).toBeFalse();
            });

            it("Ignores blank flags alongside a sent one", () => {
                postPokedex("register", {pokemonid: dragonite.id, caught: true});
                var result = postPokedex(
                    "register",
                    {
                        pokemonid: dragonite.id,
                        caught   : "",
                        shiny    : true
                    }
                );

                expect(result.response.success).toBeTrue();
                var entry = getEntry(trainer.id, dragonite.id);
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeTrue();
            });

            it("Writes every flag sent together", () => {
                var result = postPokedex(
                    "register",
                    {
                        pokemonid  : dragonite.id,
                        caught     : true,
                        shiny      : true,
                        hundo      : true,
                        shadow     : true,
                        shadowshiny: true
                    }
                );

                expect(result.response.success).toBeTrue();
                var entry = getEntry(trainer.id, dragonite.id);
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeTrue();
                expect(entry.hundo).toBeTrue();
                expect(entry.shadow).toBeTrue();
                expect(entry.shadowshiny).toBeTrue();
            });

            it("Registers to the session's trainer, never a trainerid sent with the form", () => {
                var result = postPokedex(
                    "register",
                    {
                        pokemonid: bulbasaur.id,
                        caught   : true,
                        trainerid: otherTrainer.id
                    }
                );

                expect(result.response.success).toBeTrue();
                expect(getEntry(trainer.id, bulbasaur.id)).notToBeEmpty();
                expect(getEntry(otherTrainer.id, bulbasaur.id)).toBeEmpty();
            });

            it("Rejects a request with no flags (400) and writes nothing", () => {
                var result = postPokedex("register", {pokemonid: bulbasaur.id});

                expect(result.statusCode).toBe(400);
                expect(result.response.success).toBeFalse();
                expect(getEntry(trainer.id, bulbasaur.id)).toBeEmpty();
            });

            it("Rejects a request whose flags are all blank (400)", () => {
                var result = postPokedex(
                    "register",
                    {
                        pokemonid: bulbasaur.id,
                        caught   : "",
                        shiny    : ""
                    }
                );

                expect(result.statusCode).toBe(400);
                expect(getEntry(trainer.id, bulbasaur.id)).toBeEmpty();
            });

            it("Rejects a pokemon that doesn't exist (400)", () => {
                var maxId  = queryExecute("SELECT MAX(id) AS maxid FROM pokemon").maxid;
                var result = postPokedex("register", {pokemonid: maxId + 1000, caught: true});

                expect(result.statusCode).toBe(400);
                expect(result.response.success).toBeFalse();
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a non numeric pokemonid (400)", () => {
                var result = postPokedex("register", {pokemonid: "abc", caught: true});

                expect(result.statusCode).toBe(400);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a missing pokemonid (400)", () => {
                var result = postPokedex("register", {caught: true});

                expect(result.statusCode).toBe(400);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a non boolean flag (400) and writes nothing", () => {
                var result = postPokedex(
                    "register",
                    {
                        pokemonid: bulbasaur.id,
                        caught   : true,
                        shiny    : "maybe"
                    }
                );

                expect(result.statusCode).toBe(400);
                expect(getEntry(trainer.id, bulbasaur.id)).toBeEmpty();
            });

            it("Rejects GET with 405", () => {
                setup();
                var event = get(route = "/pokedex/register", params = {pokemonid: bulbasaur.id, caught: true});

                expect(event.getStatusCode()).toBe(405);
                expect(getEntry(trainer.id, bulbasaur.id)).toBeEmpty();
            });
        });

        describe("POST /pokedex/registerAll", () => {
            beforeEach(() => {
                trainer = mockTrainer.makeSignedIn();
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });

            it("Registers every eligible pokemon in the region as caught", () => {
                expect(missingCount(trainer.id, "Kanto", false)).toBeGT(0);

                var result = postPokedex("registerAll", {region: "Kanto", shiny: false});

                expect(result.statusCode).toBe(200);
                expect(result.response.success).toBeTrue();
                expect(missingCount(trainer.id, "Kanto", false)).toBe(0);
                // Caught only - no shiny flags written
                expect(testData.countRows("pokedex", {trainerid: trainer.id, shiny: true})).toBe(0);
            });

            it("Registers every live shiny in the region as shiny", () => {
                var result = postPokedex("registerAll", {region: "Kanto", shiny: true});

                expect(result.response.success).toBeTrue();
                expect(missingCount(trainer.id, "Kanto", true)).toBe(0);

                // Pokemon without a shiny release are left out
                var notShiny = queryExecute(
                    "
                    SELECT COUNT(*) AS total
                    FROM pokedex
                    INNER JOIN pokemon ON pokemon.id = pokedex.pokemonid
                    WHERE pokedex.trainerid = :trainerid
                        AND pokemon.shiny = false
                    ",
                    {trainerid: {value: trainer.id, cfsqltype: "integer"}}
                ).total;
                expect(notShiny).toBe(0);
            });

            it("Only touches the requested region", () => {
                postPokedex("registerAll", {region: "Kanto", shiny: false});

                var outside = queryExecute(
                    "
                    SELECT COUNT(*) AS total
                    FROM pokedex
                    INNER JOIN pokemon ON pokemon.id = pokedex.pokemonid
                    INNER JOIN generation ON generation.generation = pokemon.generation
                    WHERE pokedex.trainerid = :trainerid
                        AND generation.region <> 'Kanto'
                    ",
                    {trainerid: {value: trainer.id, cfsqltype: "integer"}}
                ).total;
                expect(outside).toBe(0);
            });

            it("Keeps flags already set on existing entries", () => {
                postPokedex(
                    "register",
                    {
                        pokemonid: bulbasaur.id,
                        shiny    : true,
                        hundo    : true
                    }
                );

                expect(postPokedex("registerAll", {region: "Kanto", shiny: false}).response.success).toBeTrue();

                var entry = getEntry(trainer.id, bulbasaur.id);
                expect(entry.caught).toBeTrue();
                expect(entry.shiny).toBeTrue();
                expect(entry.hundo).toBeTrue();
                expect(testData.countRows("pokedex", {trainerid: trainer.id, pokemonid: bulbasaur.id})).toBe(1);
            });

            it("Running it twice adds no rows", () => {
                postPokedex("registerAll", {region: "Kanto", shiny: false});
                var rowsAfterFirst = testData.countRows("pokedex", {trainerid: trainer.id});

                expect(postPokedex("registerAll", {region: "Kanto", shiny: false}).response.success).toBeTrue();
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(rowsAfterFirst);
            });

            it("Registers to the session's trainer, never a trainerid sent with the form", () => {
                var result = postPokedex(
                    "registerAll",
                    {
                        region   : "Kanto",
                        shiny    : false,
                        trainerid: otherTrainer.id
                    }
                );

                expect(result.response.success).toBeTrue();
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBeGT(0);
                expect(testData.countRows("pokedex", {trainerid: otherTrainer.id})).toBe(0);
            });

            it("Rejects a region that doesn't exist (400) and writes nothing", () => {
                var result = postPokedex("registerAll", {region: "Atlantis", shiny: false});

                expect(result.statusCode).toBe(400);
                expect(result.response.success).toBeFalse();
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a missing region (400)", () => {
                var result = postPokedex("registerAll", {shiny: false});

                expect(result.statusCode).toBe(400);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a missing shiny flag (400)", () => {
                var result = postPokedex("registerAll", {region: "Kanto"});

                expect(result.statusCode).toBe(400);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects a non boolean shiny flag (400)", () => {
                var result = postPokedex("registerAll", {region: "Kanto", shiny: "maybe"});

                expect(result.statusCode).toBe(400);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });

            it("Rejects GET with 405", () => {
                setup();
                var event = get(route = "/pokedex/registerAll", params = {region: "Kanto", shiny: false});

                expect(event.getStatusCode()).toBe(405);
                expect(testData.countRows("pokedex", {trainerid: trainer.id})).toBe(0);
            });
        });

        describe("Guests", () => {
            beforeEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Are sent to login from register", () => {
                setup();
                var event = post(route = "/pokedex/register", params = {pokemonid: bulbasaur.id, caught: true});

                expect(event.getValue("relocate_uri", "")).toBe("/login");
            });

            it("Are sent to login from registerAll", () => {
                setup();
                var event = post(route = "/pokedex/registerAll", params = {region: "Kanto", shiny: false});

                expect(event.getValue("relocate_uri", "")).toBe("/login");
            });
        });
    }

}
