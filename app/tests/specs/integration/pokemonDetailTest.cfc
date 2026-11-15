component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();

        // Every spec reads the same guest render
        setup();
        var event            = get(route = "/pokemon/1");
        variables.statusCode = event.getStatusCode();
        variables.html       = event.getRenderedContent();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("GET /pokemon/1 (Bulbasaur detail page)", () => {
            it("Returns HTTP 200", () => {
                expect(statusCode).toBe(200);
            });

            describe("Base stats", () => {
                it("Stamina shows 128 HP", () => {
                    expect(html).toInclude("128 HP");
                });

                it("Attack shows 118 ATK", () => {
                    expect(html).toInclude("118 ATK");
                });

                it("Defense shows 111 DEF", () => {
                    expect(html).toInclude("111 DEF");
                });
            });

            describe("CP values", () => {
                it("Research (Lvl 15) CP is 477", () => {
                    expect(html).toInclude("477");
                });

                it("Max (Lvl 50) CP is 1260", () => {
                    expect(html).toInclude("1260 CP");
                });

                it("Raid/Egg (Lvl 20) CP range is 590 to 637", () => {
                    expect(html).toInclude("590");
                    expect(html).toInclude("637");
                });

                it("Weather Boosted (Lvl 25) CP range is 737 to 796", () => {
                    expect(html).toInclude("737");
                    expect(html).toInclude("796");
                });
            });

            describe("Evolutions", () => {
                it("Includes Bulbasaur to Ivysaur for 25 Candy", () => {
                    expect(html).toInclude("Ivysaur");
                    expect(html).toInclude("25 Candy");
                });

                it("Includes Ivysaur to Venusaur for 100 Candy", () => {
                    expect(html).toInclude("Venusaur");
                    expect(html).toInclude("100 Candy");
                });

                it("Includes Venusaur to Mega Venusaur evolution", () => {
                    expect(html).toInclude("Mega Venusaur");
                    expect(html).toInclude("Mega Evolution");
                });

                it("Includes Venusaur to Gigantamax Venusaur evolution", () => {
                    expect(html).toInclude("Gigantamax Venusaur");
                    expect(html).toInclude("Gigantamax Form");
                });
            });

            describe("Costume forms", () => {
                it("Includes Halloween costume", () => {
                    expect(html).toInclude("Halloween");
                });

                it("Includes Pikachu Visor costume", () => {
                    expect(html).toInclude("Pikachu Visor");
                });

                it("Includes Party Hat costume", () => {
                    expect(html).toInclude("Party Hat");
                });
            });
        });
    }

}
