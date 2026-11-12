component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");
        trainer     = mockTrainer.make(); // read-only specs, one trainer is enough
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe("Pokedex pages prerender the grid", () => {
            beforeEach(() => {
                setup();
            });

            it("Renders the grid, in the right view, on the pokedex, shadow pokedex and costume pokedex pages", () => {
                // Route -> expected grid view
                var pages = {
                    "/mypokedex"       : "data-view=""(caught|shiny)""",
                    "/myshadowpokedex" : "data-view=""shadow(shiny)?""",
                    "/mycostumepokedex": "data-view=""costume(shiny)?"""
                };
                pages.each((route, viewPattern) => {
                    setup();
                    var event = get(route = route, renderResults = true);

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    var html = event.getRenderedContent();
                    expect(html).toContain("id=""pokedexGrid""");
                    expect(html).toContain("id=""registeredCount""");
                    expect(html).toContain("pokemonCell");
                    expect(html).toMatch(viewPattern);
                });
            });

            it("Renders the requested region and view", () => {
                var event = get(
                    route         = "/mypokedex",
                    params        = {region: "Johto", shiny: false},
                    renderResults = true
                );
                var html = event.getRenderedContent();
                expect(html).toContain("data-view=""caught""");
                // data-name only appears on grid cells
                expect(html).toContain("data-name=""Chikorita""");
                expect(html).notToContain("data-name=""Bulbasaur""");

                setup();
                event = get(
                    route         = "/mypokedex",
                    params        = {region: "Johto", shiny: true},
                    renderResults = true
                );
                expect(event.getRenderedContent()).toContain("data-view=""shiny""");
            });
        });
    }

}
