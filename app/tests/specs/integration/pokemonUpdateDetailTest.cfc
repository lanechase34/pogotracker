component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        adminService   = getInstance("services.admin");
        pokemonService = getInstance("services.pokemon");

        admin = mockTrainer.make(securityLevel = 50, autoLogin = false);
        user  = mockTrainer.make(securityLevel = 10, autoLogin = false);
        session.delete("mocktrainerid");

        bulbasaur = pokemonService.findPokemon({
            number : 1,
            name   : "Bulbasaur",
            gender : "",
            costume: false
        })[1];
        gendered = pokemonFromSQL("
            SELECT id
            FROM pokemon
            WHERE gender <> ''
                AND costume = false
                AND name NOT ILIKE 'Nidoran%'
            ORDER BY id ASC
            LIMIT 1
        ");
        nidoran = pokemonFromSQL("
            SELECT id
            FROM pokemon
            WHERE name ILIKE 'Nidoran%'
                AND costume = false
            ORDER BY id ASC
            LIMIT 1
        ");
        costumed = pokemonFromSQL("
            SELECT id
            FROM pokemon
            WHERE costume = true
            ORDER BY id ASC
            LIMIT 1
        ");

        // Every spec changes these - each is put back after the spec
        touched = [bulbasaur, gendered, nidoran, costumed].map((pokemon) => {
            return testData.getRowById("pokemon", pokemon.id);
        });
    }

    function afterAll() {
        mockTrainer.deleteTrainer(admin.id);
        mockTrainer.deleteTrainer(user.id);
        super.afterAll();
    }

    private struct function pokemonFromSQL(required string sql) {
        var found = queryExecute(arguments.sql);
        expect(found.recordCount).toBe(1, "No pokemon for: #arguments.sql#");
        return pokemonService.getFromId(found.id);
    }

    /**
     * POST the detail form as the given trainer
     *
     * @switches switch name -> "on"/"off", switches left out are not sent (an unchecked box)
     */
    private any function postDetail(
        required struct trainer,
        required numeric pokemonid,
        struct switches = {}
    ) {
        mockTrainer.actAs(arguments.trainer);
        setup();
        var params = {pokemonid: arguments.pokemonid};
        params.append(arguments.switches);
        return post(route = "/pokemon/updateDetail", params = params);
    }

    private struct function allOn() {
        return {
            liveSwitch       : "on",
            shinySwitch      : "on",
            shadowSwitch     : "on",
            shinyShadowSwitch: "on",
            tradableSwitch   : "on"
        };
    }

    private struct function savedOverrides() {
        return adminService.getOverride(name = "envpokedexoverrides");
    }

    function run() {
        describe("POST /pokemon/updateDetail", () => {
            beforeEach(() => {
                // Raw so the exact saved json goes back, or no row at all if there was none
                originalOverrides = queryExecute(
                    "SELECT override FROM overrides WHERE name = :name",
                    {name: {value: "envpokedexoverrides", cfsqltype: "varchar"}}
                );
            });

            afterEach(() => {
                if(originalOverrides.recordCount) {
                    queryExecute(
                        "UPDATE overrides SET override = CAST(:override AS jsonb) WHERE name = :name",
                        {
                            name    : {value: "envpokedexoverrides", cfsqltype: "varchar"},
                            override: {value: originalOverrides.override, cfsqltype: "varchar"}
                        }
                    );
                }
                else {
                    testData.deleteRows("overrides", {name: "envpokedexoverrides"});
                }

                touched.each((row) => {
                    testData.updateRow(
                        "pokemon",
                        row.id,
                        {
                            live       : row.live,
                            shiny      : row.shiny,
                            shadow     : row.shadow,
                            shadowshiny: row.shadowshiny,
                            tradable   : row.tradable
                        }
                    );
                });
                pokemonService.clearAllCaches();
                mockTrainer.actAsGuest();
            });

            it("Saves every switch to the pokemon row and relocates to its page", () => {
                var event = postDetail(admin, bulbasaur.id, allOn());

                expect(event.getValue("relocate_URI", "")).toBe("/pokemon/#bulbasaur.ses#");
                var row = testData.getRowById("pokemon", bulbasaur.id);
                expect(row.live).toBeTrue();
                expect(row.shiny).toBeTrue();
                expect(row.shadow).toBeTrue();
                expect(row.shadowshiny).toBeTrue();
                expect(row.tradable).toBeTrue();
            });

            it("Treats switches left out as off", () => {
                postDetail(admin, bulbasaur.id, allOn());
                postDetail(admin, bulbasaur.id, {liveSwitch: "on"});

                var row = testData.getRowById("pokemon", bulbasaur.id);
                expect(row.live).toBeTrue();
                expect(row.shiny).toBeFalse();
                expect(row.shadow).toBeFalse();
                expect(row.shadowshiny).toBeFalse();
                expect(row.tradable).toBeFalse();
            });

            it("Treats an explicit off as off", () => {
                var switches          = allOn();
                switches.shinySwitch  = "off";
                switches.shadowSwitch = "off";
                postDetail(admin, bulbasaur.id, switches);

                var row = testData.getRowById("pokemon", bulbasaur.id);
                expect(row.live).toBeTrue();
                expect(row.shiny).toBeFalse();
                expect(row.shadow).toBeFalse();
                expect(row.tradable).toBeTrue();
            });

            it("Writes the flags to the env overrides so the nightly build keeps them", () => {
                postDetail(
                    admin,
                    bulbasaur.id,
                    {
                        liveSwitch       : "on",
                        shinySwitch      : "off",
                        shadowSwitch     : "on",
                        shinyShadowSwitch: "off",
                        tradableSwitch   : "on"
                    }
                );

                var overrides = savedOverrides();
                expect(overrides).toHaveKey("Bulbasaur");
                var entry = overrides["Bulbasaur"];
                expect(entry.live).toBeTrue();
                expect(entry.shiny).toBeFalse();
                expect(entry.shadow).toBeTrue();
                expect(entry.shadowshiny).toBeFalse();
                expect(entry.tradable).toBeTrue();
            });

            it("Keeps the rest of an existing override entry", () => {
                var overrides          = savedOverrides();
                overrides["Bulbasaur"] = {
                    moves: ["FRENZY_PLANT*"],
                    catch: 25,
                    shiny: false
                };
                overrides["Override Untouched"] = {live: false};
                adminService.saveOverride(name = "envpokedexoverrides", override = overrides);

                postDetail(admin, bulbasaur.id, allOn());

                var saved = savedOverrides();
                expect(saved["Bulbasaur"].moves).toBe(["FRENZY_PLANT*"]);
                expect(saved["Bulbasaur"].catch).toBe(25);
                expect(saved["Bulbasaur"].shiny).toBeTrue();
                // Other pokemon's entries are left alone
                expect(saved["Override Untouched"]).toBe({live: false});
            });

            it("Replaces an override entry that isn't a struct", () => {
                var overrides          = savedOverrides();
                overrides["Bulbasaur"] = "broken";
                adminService.saveOverride(name = "envpokedexoverrides", override = overrides);

                postDetail(admin, bulbasaur.id, allOn());

                var entry = savedOverrides()["Bulbasaur"];
                expect(entry).toBeStruct();
                expect(entry.live).toBeTrue();
                expect(entry.tradable).toBeTrue();
            });

            it("Keys a gendered pokemon by name and gender, the same key the build uses", () => {
                var key = "#gendered.name# #gendered.gender#";
                expect(adminService.getOverrideKey(gendered)).toBe(key);

                postDetail(
                    admin,
                    gendered.id,
                    {liveSwitch: "on", shinySwitch: "on"}
                );

                var overrides = savedOverrides();
                expect(overrides).toHaveKey(key);
                expect(overrides[key].shiny).toBeTrue();
                expect(testData.getRowById("pokemon", gendered.id).shiny).toBeTrue();
            });

            it("Keys Nidoran by name alone - its name already carries the gender", () => {
                expect(adminService.getOverrideKey(nidoran)).toBe(nidoran.name);

                postDetail(
                    admin,
                    nidoran.id,
                    {liveSwitch: "on", tradableSwitch: "on"}
                );

                var overrides = savedOverrides();
                expect(overrides).toHaveKey(nidoran.name);
                expect(overrides[nidoran.name].tradable).toBeTrue();
                if(nidoran.gender.len()) {
                    expect(overrides).notToHaveKey("#nidoran.name# #nidoran.gender#");
                }
            });

            it("Updates a costume pokemon's row without writing an override over its base pokemon", () => {
                var before = serializeJSON(savedOverrides());

                postDetail(admin, costumed.id, allOn());

                expect(serializeJSON(savedOverrides())).toBe(before);
                var row = testData.getRowById("pokemon", costumed.id);
                expect(row.live).toBeTrue();
                expect(row.shiny).toBeTrue();
                expect(row.tradable).toBeTrue();
            });

            it("Clears the cached pokemon so the change shows right away", () => {
                var current = testData.getRowById("pokemon", bulbasaur.id);
                // Warm the cache with the current flags
                expect(pokemonService.getFromSes(bulbasaur.ses).shiny).toBe(current.shiny);
                pokemonService.getAll();

                var switches         = allOn();
                switches.shinySwitch = current.shiny ? "off" : "on";
                postDetail(admin, bulbasaur.id, switches);

                expect(pokemonService.getFromSes(bulbasaur.ses).shiny).toBe(!current.shiny);
                var fromAll = pokemonService.getAll().filter((pokemon) => pokemon.id == bulbasaur.id);
                expect(fromAll.len()).toBe(1);
                expect(fromAll[1].shiny).toBe(!current.shiny);
            });

            it("Rejects a switch value other than on/off and changes nothing", () => {
                var before          = testData.getRowById("pokemon", bulbasaur.id);
                var beforeOverrides = serializeJSON(savedOverrides());

                var switches        = allOn();
                switches.liveSwitch = "yes";
                var event           = postDetail(admin, bulbasaur.id, switches);

                expect(event.getValue("relocate_event", "")).toBe("home");
                expect(testData.getRowById("pokemon", bulbasaur.id)).toBe(before);
                expect(serializeJSON(savedOverrides())).toBe(beforeOverrides);
            });

            it("Rejects a pokemon that doesn't exist", () => {
                var beforeOverrides = serializeJSON(savedOverrides());
                var maxId           = queryExecute("SELECT MAX(id) AS maxid FROM pokemon").maxid;

                var event = postDetail(admin, maxId + 1000, allOn());

                expect(event.getValue("relocate_event", "")).toBe("home");
                expect(serializeJSON(savedOverrides())).toBe(beforeOverrides);
            });

            it("Is admin only - a regular trainer gets a 403 and nothing changes", () => {
                var before          = testData.getRowById("pokemon", bulbasaur.id);
                var beforeOverrides = serializeJSON(savedOverrides());

                var event = postDetail(user, bulbasaur.id, allOn());

                expect(event.getCurrentEvent()).toBe("error.unauthorized");
                expect(testData.getRowById("pokemon", bulbasaur.id)).toBe(before);
                expect(serializeJSON(savedOverrides())).toBe(beforeOverrides);
            });

            it("Rejects GET with 405", () => {
                var before = testData.getRowById("pokemon", bulbasaur.id);

                mockTrainer.actAs(admin);
                setup();
                var params       = allOn();
                params.pokemonid = bulbasaur.id;
                var event        = get(route = "/pokemon/updateDetail", params = params);

                expect(event.getStatusCode()).toBe(405);
                expect(testData.getRowById("pokemon", bulbasaur.id)).toBe(before);
            });
        });
    }

}
