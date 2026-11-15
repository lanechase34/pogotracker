component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");

        // trainer never registers a costume pokemon, writer does - switched with actAs instead of a login per spec
        trainer = mockTrainer.make(autoLogin = false);
        writer  = mockTrainer.make(autoLogin = false);

        bulbasaurId             = globalFunctions.pokemonId(1, "Bulbasaur");
        partyHatBulbasaurId     = globalFunctions.pokemonId(1, "Bulbasaur", "Party Hat");
        pikachuVisorBulbasaurId = globalFunctions.pokemonId(1, "Bulbasaur", "Pikachu Visor");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(writer.id);
        mockTrainer.deleteTrainer(trainer.id);
    }

    /**
     * The rendered costume pokedex grid
     */
    private string function costumeHtml() {
        setup();
        var event = get(
            route  = "/pokedex/getPokedex",
            params = {
                costume: true,
                shiny  : false,
                region : "costumeRegion"
            }
        );
        return event.getRenderedContent();
    }

    function run() {
        describe("pokedex.myCostumePokedex", () => {
            beforeEach(() => {
                setup();
                mockTrainer.actAs(trainer);
            });

            it("Loads the costume pokedex page with the correct structure and data attributes", () => {
                var event = get(route = "/mycostumepokedex", renderResults = true);

                expect(event.getResponse().getStatusCode()).toBe(200);

                var html = event.getRenderedContent();
                expect(html).toContain("id=""costumePokedexTable""");
                expect(html).toContain("data-trainerid=""#trainer.id#""");
                expect(html).toContain("data-shiny=""false""");
            });

            it("Sets data-shiny to true on the page when shiny is requested", () => {
                var event = get(
                    route         = "/mycostumepokedex",
                    params        = {shiny: true},
                    renderResults = true
                );

                expect(event.getResponse().getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toContain("data-shiny=""true""");
            });

            it("Costume pokemon appear in the costume view even before being registered", () => {
                var html = costumeHtml();

                // Costume entry is present in the list
                expect(html).toContain("data-id=""#partyHatBulbasaurId#""");
                // But shows as uncaught since it hasn't been registered
                expect(globalFunctions.entryBlock(html, partyHatBulbasaurId)).toContain("data-caught=""false""");
            });

            // Registering the normal pokemon never touches its costumes - which is what these assert
            it("Normal pokemon are excluded from the costume view entirely", () => {
                globalFunctions.registerCaught(bulbasaurId, false);

                var html = costumeHtml();

                // Normal Bulbasaur (costume=false) must not appear at all in the costume view
                expect(html).notToContain("data-id=""#bulbasaurId#""");

                // Its costume counterparts must still be present (and uncaught)
                expect(html).toContain("data-id=""#partyHatBulbasaurId#""");
                expect(html).toContain("data-id=""#pikachuVisorBulbasaurId#""");
            });

            it("Registering a normal pokemon does not mark its costume counterpart as caught in the costume view", () => {
                globalFunctions.registerCaught(bulbasaurId, true);

                var html              = costumeHtml();
                var partyHatBlock     = globalFunctions.entryBlock(html, partyHatBulbasaurId);
                var pikachuVisorBlock = globalFunctions.entryBlock(html, pikachuVisorBulbasaurId);

                // Neither costume variant should inherit the normal registration
                expect(partyHatBlock).toContain("data-caught=""false""");
                expect(partyHatBlock).toContain("data-shiny=""false""");
                expect(pikachuVisorBlock).toContain("data-caught=""false""");
            });

            describe("After registering a costume pokemon", () => {
                beforeEach(() => {
                    mockTrainer.actAs(writer);
                });

                it("Registered costume pokemon appear as caught in the costume view", () => {
                    globalFunctions.registerCaught(partyHatBulbasaurId, false);

                    expect(globalFunctions.entryBlock(costumeHtml(), partyHatBulbasaurId)).toContain("data-caught=""true""");
                });
            });
        });
    }

}
