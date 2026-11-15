component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer   = getInstance("tests.resources.mockTrainer");
        customService = getInstance("services.custom");
        validation    = getInstance("ValidationManager@cbvalidation");
        trainer       = mockTrainer.make();
        customTitle   = left(createUUID(), 50);
        onePokemonId  = globalFunctions.pokemonId(324, "Torkoal");

        // The lifecycle specs delete their own custom pokedex, the validation specs edit this one (deleteTrainer cleans it up)
        validationCustomid = customService.create(
            trainerid = trainer.id,
            name      = "Validation Custom #customTitle#",
            isPublic  = false
        );
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer();
    }

    /**
     * A target that passes pokedex.addCustomPokedex
     */
    private struct function validAdd() {
        return {
            name   : "Valid Name Here",
            public : false,
            pokemon: [onePokemonId]
        };
    }

    /**
     * A target that passes pokedex.editCustomPokedex
     */
    private struct function validEdit() {
        var target      = validAdd();
        target.customid = validationCustomid;
        return target;
    }

    /**
     * Drop and/or overwrite fields on a valid target
     *
     * @target valid target
     * @rule   {drop: field} and/or {set: {field: value}}
     */
    private struct function applyRule(required struct target, required struct rule) {
        if(arguments.rule.keyExists("drop")) {
            arguments.target.delete(arguments.rule.drop);
        }
        if(arguments.rule.keyExists("set")) {
            arguments.target.append(arguments.rule.set);
        }
        return arguments.target;
    }

    /**
     * Lowercase list of the fields that fail the named constraint
     */
    private string function failedFields(required struct target, required string constraints) {
        var result = validation.validate(target = arguments.target, constraints = arguments.constraints);
        return lCase(result.getAllErrorsAsStruct().keyList());
    }

    function run() {
        describe("Custom lifecycle events", () => {
            beforeEach(() => {
                setup();
            });

            it("Can create a custom pokedex by posting data to pokedex.addCustomPokedex", () => {
                var data = {
                    name   : "Test Custom #customTitle#",
                    public : false,
                    pokemon: [
                        globalFunctions.pokemonId(324, "Torkoal"),
                        globalFunctions.pokemonId(369, "Relicanth"),
                        globalFunctions.pokemonId(352, "Kecleon"),
                        globalFunctions.pokemonId(360, "Wynaut"),
                        globalFunctions.pokemonId(357, "Tropius"),
                        // A normal pokemon and its costume share a number, but are separate entries
                        globalFunctions.pokemonId(1, "Bulbasaur"),
                        globalFunctions.pokemonId(1, "Bulbasaur", "Party Hat")
                    ]
                };

                var beforeCount = testData.countRows("custom");

                var event = post(route = "/pokedex/addCustomPokedex", params = data);

                // Verify the custom pokedex was created
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();
                expect(response).toHaveKey("data");
                expect(response.data.id).toBeInteger();

                expect(testData.countRows("custom")).toBe(beforeCount + 1);

                // Shared with the specs below
                customid   = response.data.id;
                var custom = customService.getFromId(customid);

                // Verify the custom pokedex properties
                expect(custom).toBeStruct();

                expect(custom.name).toBe(data.name);
                expect(custom.public).toBe(data.public);
                expect(custom.trainerid).toBe(trainer.id);

                // Verify the pokedex entries - exactly these, costumes told apart from their normal form
                var members = customHelperFunctions.getMembers(custom.id);
                expect(members.len()).toBe(data.pokemon.len());

                var expectedPokemon = {
                    "Torkoal_"           : true,
                    "Relicanth_"         : true,
                    "Kecleon_"           : true,
                    "Wynaut_"            : true,
                    "Tropius_"           : true,
                    "Bulbasaur_"         : true,
                    "Bulbasaur_Party Hat": true
                };
                members.each((entry) => {
                    var key = "#entry.name#_#entry.costumetype#";
                    expect(expectedPokemon).toHaveKey(key);
                    structDelete(expectedPokemon, key);
                });

                expect(expectedPokemon.len()).toBe(0);
            });

            it("Can edit a custom pokedex by posting data to pokedex.editCustomPokedex", () => {
                var data = {
                    customid: customid,
                    name    : "Updated Test Custom #customTitle#",
                    public  : false,
                    pokemon : [
                        globalFunctions.pokemonId(352, "Kecleon"),
                        globalFunctions.pokemonId(360, "Wynaut"),
                        globalFunctions.pokemonId(357, "Tropius"),
                        globalFunctions.pokemonId(358, "Chimecho")
                    ]
                };

                var beforeCount = testData.countRows("custom");

                var event = post(route = "/pokedex/editCustomPokedex", params = data);

                // The amount of custom pokedex should not change since we are editing
                expect(testData.countRows("custom")).toBe(beforeCount);

                // Verify the custom pokedex was updated successfully
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();

                var custom = customService.getFromId(customid);
                expect(custom.name).toBe(data.name);
                expect(custom.public).toBe(data.public);
                expect(custom.trainerid).toBe(trainer.id);

                // Verify the pokedex entries have updated - exactly these four
                var members = customHelperFunctions.getMembers(custom.id);
                expect(members.len()).toBe(data.pokemon.len());

                var expectedPokemon = {
                    "Kecleon" : 1,
                    "Wynaut"  : 1,
                    "Tropius" : 1,
                    "Chimecho": 1
                };
                members.each((entry) => {
                    expect(expectedPokemon).toHaveKey(entry.name);
                    structDelete(expectedPokemon, entry.name);
                });

                expect(expectedPokemon.len()).toBe(0);
            });

            it("Can view the custom pokedex in the customPokedexList", () => {
                var event = get(route = "/custompokedexlist", renderResults = true);
                expect(event.getResponse().getStatusCode()).toBe(200);

                // Expect the custom pokedex to be listed
                expect(event.getRenderedContent()).toContain("Updated Test Custom #customTitle#");
                expect(event.getRenderedContent()).toContain("/mycustompokedex/#customid#");
            });

            it("Can view the custom pokedex", () => {
                // Load the page
                var event = get(route = "/mycustompokedex/#customid#", renderResults = true);
                expect(event.getResponse().getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toContain("Updated Test Custom #customTitle#");

                // Load the custom pokedex data
                event = get(
                    route  = "/pokedex/getCustomPokedex",
                    params = {
                        shiny   : false,
                        hundo   : false,
                        customid: customid
                    }
                );

                expect(event.getRenderedContent()).toContain("id=""pokedexGrid""");
                expect(event.getRenderedContent()).toContain("data-name=""Kecleon""");
                expect(event.getRenderedContent()).toContain("data-name=""Wynaut""");
                expect(event.getRenderedContent()).toContain("data-name=""Tropius""");
                expect(event.getRenderedContent()).toContain("data-name=""Chimecho""");
            });

            it("Can delete a custom pokedex by posting data to pokedex.deleteCustomPokedex", () => {
                var beforeCount = testData.countRows("custom");

                var event = post(route = "/pokedex/deleteCustomPokedex", params = {customid: customid});

                // Verify the custom pokedex was deleted successfully
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();
                expect(testData.countRows("custom")).toBe(beforeCount - 1);

                // Verify the custom pokedex no longer exists
                expect(customService.getFromId(customid)).toBeNull();
            });

            // The handlers answer every validation failure with the same 400, so one request each proves the wiring
            // and each field rule is checked against the named constraint, where the failing field can be seen
            describe("pokedex.addCustomPokedex validation", () => {
                it("Rejects an invalid custom pokedex with a 400", () => {
                    var beforeCount = testData.countRows("custom");

                    var event = post(
                        route  = "/pokedex/addCustomPokedex",
                        params = {public: false, pokemon: [onePokemonId]}
                    );
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(400);
                    expect(response.success).toBeFalse();
                    expect(response.message).toBe("Invalid Custom Pokedex");
                    expect(testData.countRows("custom")).toBe(beforeCount);
                });

                var addRules = [
                    {
                        title: "name is missing",
                        field: "name",
                        drop : "name"
                    },
                    {
                        title: "name is shorter than 5 characters",
                        field: "name",
                        set  : {name: "TooS"}
                    },
                    {
                        title: "name is longer than 100 characters",
                        field: "name",
                        set  : {name: repeatString("a", 101)}
                    },
                    {
                        title: "public is missing",
                        field: "public",
                        drop : "public"
                    },
                    {
                        title: "pokemon array is missing",
                        field: "pokemon",
                        drop : "pokemon"
                    },
                    {
                        title: "pokemon array is empty",
                        field: "pokemon",
                        set  : {pokemon: []}
                    }
                ];

                for(var addRule in addRules) {
                    it(
                        title = "Rejects when #addRule.title#",
                        body  = (data) => {
                            expect(failedFields(applyRule(validAdd(), data.rule), "pokedex.addCustomPokedex")).toBe(
                                data.rule.field
                            );
                        },
                        data = {rule: addRule}
                    );
                }
            });

            describe("pokedex.editCustomPokedex validation", () => {
                it("Rejects an invalid edit with a 400", () => {
                    var event = post(
                        route  = "/pokedex/editCustomPokedex",
                        params = {
                            customid: validationCustomid,
                            name    : "Too",
                            public  : false,
                            pokemon : [onePokemonId]
                        }
                    );
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(400);
                    expect(response.success).toBeFalse();
                    expect(response.message).toBe("Invalid Custom Pokedex");
                    expect(customService.getFromId(validationCustomid).name).toBe("Validation Custom #customTitle#");
                });

                var editRules = [
                    {
                        title: "customid is missing",
                        field: "customid",
                        drop : "customid"
                    },
                    {
                        title: "customid is not numeric",
                        field: "customid",
                        set  : {customid: "notanumber"}
                    },
                    {
                        title: "customid does not exist",
                        field: "customid",
                        set  : {customid: 999999}
                    },
                    {
                        title: "name is missing",
                        field: "name",
                        drop : "name"
                    },
                    {
                        title: "name is shorter than 5 characters",
                        field: "name",
                        set  : {name: "Too"}
                    },
                    {
                        title: "name is longer than 100 characters",
                        field: "name",
                        set  : {name: repeatString("a", 101)}
                    },
                    {
                        title: "public is missing",
                        field: "public",
                        drop : "public"
                    },
                    {
                        title: "pokemon array is missing",
                        field: "pokemon",
                        drop : "pokemon"
                    },
                    {
                        title: "pokemon array is empty",
                        field: "pokemon",
                        set  : {pokemon: []}
                    }
                ];

                for(var editRule in editRules) {
                    it(
                        title = "Rejects when #editRule.title#",
                        body  = (data) => {
                            expect(failedFields(applyRule(validEdit(), data.rule), "pokedex.editCustomPokedex")).toBe(
                                data.rule.field
                            );
                        },
                        data = {rule: editRule}
                    );
                }
            });
        });
    }

}
