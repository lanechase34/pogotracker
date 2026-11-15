component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        customService = getInstance("services.custom");
        mockTrainer   = getInstance("tests.resources.mockTrainer");
        customTitle   = "Test Custom #left(createUUID(), 50)#";
        trainer       = mockTrainer.make();

        pokemonIds = [
            globalFunctions.pokemonId(1, "Bulbasaur"),
            globalFunctions.pokemonId(2, "Ivysaur"),
            globalFunctions.pokemonId(3, "Venusaur"),
            globalFunctions.pokemonId(1, "Bulbasaur", "Party Hat"),
            globalFunctions.pokemonId(2, "Ivysaur", "Party Hat")
        ];

        pikachuVisorBulbasaurId = globalFunctions.pokemonId(1, "Bulbasaur", "Pikachu Visor");
        pikachuVisorVenusaurId  = globalFunctions.pokemonId(3, "Venusaur", "Pikachu Visor");

        // Creating a custom pokedex with costume entries is covered by customLifecycleTest - every spec here builds on this one
        customid = addCustom(customTitle, pokemonIds);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer();
    }

    /**
     * Add a private custom pokedex through the endpoint, returns its id
     */
    private numeric function addCustom(required string name, required array pokemon) {
        setup();
        var event = post(
            route  = "/pokedex/addCustomPokedex",
            params = {
                name   : arguments.name,
                public : false,
                pokemon: arguments.pokemon
            }
        );
        expect(event.getStatusCode()).toBe(200);
        return deserializeJSON(event.getRenderedContent()).data.id;
    }

    /**
     * Edit the main custom pokedex to hold exactly these pokemon
     */
    private void function editCustom(required array pokemon) {
        setup();
        var event = post(
            route  = "/pokedex/editCustomPokedex",
            params = {
                customid: customid,
                name    : customTitle,
                public  : false,
                pokemon : arguments.pokemon
            }
        );
        expect(event.getStatusCode()).toBe(200);
        expect(deserializeJSON(event.getRenderedContent()).success).toBeTrue();
        expect(customHelperFunctions.getMembers(customid).len()).toBe(arguments.pokemon.len());
    }

    /**
     * Delete a custom pokedex through the endpoint
     */
    private void function deleteCustom(required numeric id) {
        setup();
        var event = post(route = "/pokedex/deleteCustomPokedex", params = {customid: arguments.id});
        expect(event.getStatusCode()).toBe(200);
        expect(deserializeJSON(event.getRenderedContent()).success).toBeTrue();
        expect(customService.getFromId(arguments.id)).toBeNull();
    }

    /**
     * The rendered getCustomPokedex grid
     */
    private string function customHtml(required numeric id) {
        setup();
        var event = get(
            route  = "/pokedex/getCustomPokedex",
            params = {
                customid: arguments.id,
                shiny   : false,
                hundo   : false
            }
        );
        return event.getRenderedContent();
    }

    function run() {
        // The specs share one custom pokedex and the trainer's registrations - each builds on the one before
        describe("Lifecycle events of custom pokedex with normal and costume pokemon", () => {
            it("Registering a costume pokemon does not collide with its normal counterpart, and vice-versa", () => {
                // Step 1: register only normal Bulbasaur as caught (no shiny)
                globalFunctions.registerCaught(pokemonIds[1], false);

                var html = customHtml(customid);

                // Normal Bulbasaur should be caught; Party Hat completely unaffected (no collision forward)
                expect(globalFunctions.entryBlock(html, pokemonIds[1])).toContain("data-caught=""true""");
                expect(globalFunctions.entryBlock(html, pokemonIds[4])).toContain("data-caught=""false""");

                // Step 2: register Party Hat as caught + shiny to distinguish it from normal
                globalFunctions.registerCaught(pokemonIds[4], true);

                html             = customHtml(customid);
                var normalBlock  = globalFunctions.entryBlock(html, pokemonIds[1]);
                var costumeBlock = globalFunctions.entryBlock(html, pokemonIds[4]);

                // Normal: still only caught, shiny must be false - costume registration did NOT bleed back
                expect(normalBlock).toContain("data-caught=""true""");
                expect(normalBlock).toContain("data-shiny=""false""");

                // Party Hat: its own independent caught + shiny entry
                expect(costumeBlock).toContain("data-caught=""true""");
                expect(costumeBlock).toContain("data-shiny=""true""");
            });

            it("Can edit the custom pokedex to add Pikachu Visor costume entries without affecting existing entries", () => {
                var updatedPokemon = duplicate(pokemonIds);
                updatedPokemon.append(pikachuVisorBulbasaurId);
                updatedPokemon.append(pikachuVisorVenusaurId);

                editCustom(updatedPokemon);

                var html = customHtml(customid);

                updatedPokemon.each((id) => {
                    expect(html).toContain("data-id=""#id#""");
                });

                expect(globalFunctions.entryBlock(html, pikachuVisorBulbasaurId)).toContain("data-caught=""false""");
                expect(globalFunctions.entryBlock(html, pikachuVisorVenusaurId)).toContain("data-caught=""false""");

                var bulbasaurBlock         = globalFunctions.entryBlock(html, pokemonIds[1]);
                var bulbasaurPartyHatBlock = globalFunctions.entryBlock(html, pokemonIds[4]);
                expect(bulbasaurBlock).toContain("data-caught=""true""");
                expect(bulbasaurBlock).toContain("data-shiny=""false""");
                expect(bulbasaurPartyHatBlock).toContain("data-caught=""true""");
                expect(bulbasaurPartyHatBlock).toContain("data-shiny=""true""");
            });

            it("Two different costume types for the same pokemon are independent of each other", () => {
                // Register Pikachu Visor Bulbasaur as caught (no shiny) to contrast with Party Hat (caught + shiny)
                globalFunctions.registerCaught(pikachuVisorBulbasaurId, false);

                var html              = customHtml(customid);
                var normalBlock       = globalFunctions.entryBlock(html, pokemonIds[1]);
                var partyHatBlock     = globalFunctions.entryBlock(html, pokemonIds[4]);
                var pikachuVisorBlock = globalFunctions.entryBlock(html, pikachuVisorBulbasaurId);

                // All three share pokemon #1 but have completely independent registrations
                expect(normalBlock).toContain("data-caught=""true""");
                expect(normalBlock).toContain("data-shiny=""false""");

                // Party Hat untouched by Pikachu Visor registration
                expect(partyHatBlock).toContain("data-caught=""true""");
                expect(partyHatBlock).toContain("data-shiny=""true""");

                // Pikachu Visor registered as caught only, not shiny
                expect(pikachuVisorBlock).toContain("data-caught=""true""");
                expect(pikachuVisorBlock).toContain("data-shiny=""false""");
            });

            it("Editing the custom pokedex to remove a costume pokemon is id-based, not number-based", () => {
                // Remove Party Hat Bulbasaur (pokemonIds[4]) while keeping normal Bulbasaur (pokemonIds[1])
                // and Pikachu Visor Bulbasaur - all three share pokemon number 1
                editCustom([
                    pokemonIds[1],
                    pokemonIds[2],
                    pokemonIds[3],
                    pokemonIds[5],
                    pikachuVisorBulbasaurId,
                    pikachuVisorVenusaurId
                ]);

                var html = customHtml(customid);

                // Party Hat Bulbasaur must be gone
                expect(html).notToContain("data-id=""#pokemonIds[4]#""");

                // Normal Bulbasaur (same number) and Pikachu Visor (same number) must survive
                expect(html).toContain("data-id=""#pokemonIds[1]#""");
                expect(html).toContain("data-id=""#pikachuVisorBulbasaurId#""");
            });

            it("Removing a costume pokemon from the custom pokedex does not delete its pokedex registration", () => {
                // Party Hat Bulbasaur was removed from the main custom pokedex in the previous spec.
                // Its registration (caught + shiny) must survive - check it in a fresh mini custom pokedex
                var miniCustomId  = addCustom("Verify Party Hat Survival #left(createUUID(), 50)#", [pokemonIds[4]]);
                var partyHatBlock = globalFunctions.entryBlock(customHtml(miniCustomId), pokemonIds[4]);
                expect(partyHatBlock).toContain("data-caught=""true""");
                expect(partyHatBlock).toContain("data-shiny=""true""");

                deleteCustom(miniCustomId);
            });

            it("A pokemon registered before being added to the custom pokedex shows the correct caught status", () => {
                // createCustomPokedex only writes the join-table entry - it must not overwrite or reset an existing registration
                globalFunctions.registerCaught(pikachuVisorVenusaurId, true);

                var preRegCustomId     = addCustom("Pre-reg Verify #left(createUUID(), 50)#", [pikachuVisorVenusaurId]);
                var visorVenusaurBlock = globalFunctions.entryBlock(customHtml(preRegCustomId), pikachuVisorVenusaurId);
                expect(visorVenusaurBlock).toContain("data-caught=""true""");
                expect(visorVenusaurBlock).toContain("data-shiny=""true""");

                deleteCustom(preRegCustomId);
            });

            it("Deleting the custom pokedex does not delete the trainer's pokedex registrations", () => {
                deleteCustom(customid);

                // Registrations for both normal and costume pokemon survived - check them in a fresh mini custom pokedex
                var html = customHtml(
                    addCustom(
                        "Registration Survival Check #left(createUUID(), 50)#",
                        [
                            pokemonIds[1],
                            pokemonIds[4],
                            pikachuVisorBulbasaurId
                        ]
                    )
                );

                // Normal Bulbasaur: caught=true, shiny=false
                var normalBlock = globalFunctions.entryBlock(html, pokemonIds[1]);
                expect(normalBlock).toContain("data-caught=""true""");
                expect(normalBlock).toContain("data-shiny=""false""");

                // Party Hat Bulbasaur: caught=true, shiny=true
                var partyHatBlock = globalFunctions.entryBlock(html, pokemonIds[4]);
                expect(partyHatBlock).toContain("data-caught=""true""");
                expect(partyHatBlock).toContain("data-shiny=""true""");

                // Pikachu Visor Bulbasaur: caught=true, shiny=false
                var visorBlock = globalFunctions.entryBlock(html, pikachuVisorBulbasaurId);
                expect(visorBlock).toContain("data-caught=""true""");
                expect(visorBlock).toContain("data-shiny=""false""");
            });
        });
    }

}
