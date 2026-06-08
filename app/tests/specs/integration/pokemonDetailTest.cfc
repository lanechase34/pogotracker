component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('GET /pokemon/1 (Bulbasaur detail page)', () => {
            beforeEach(() => {
                setup();
            });

            it('Returns HTTP 200', () => {
                event = get(route = '/pokemon/1');
                expect(event.getStatusCode()).toBe(200);
            });

            describe('Base stats', () => {
                it('Stamina shows 128 HP', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('128 HP');
                });

                it('Attack shows 118 ATK', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('118 ATK');
                });

                it('Defense shows 111 DEF', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('111 DEF');
                });
            });

            describe('CP values', () => {
                it('Research (Lvl 15) CP is 477', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('477');
                });

                it('Max (Lvl 50) CP is 1260', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('1260 CP');
                });

                it('Raid/Egg (Lvl 20) CP range is 590 to 637', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('590');
                    expect(html).toInclude('637');
                });

                it('Weather Boosted (Lvl 25) CP range is 737 to 796', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('737');
                    expect(html).toInclude('796');
                });
            });

            describe('Evolutions', () => {
                it('Includes Bulbasaur to Ivysaur for 25 Candy', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('Ivysaur');
                    expect(html).toInclude('25 Candy');
                });

                it('Includes Ivysaur to Venusaur for 100 Candy', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('Venusaur');
                    expect(html).toInclude('100 Candy');
                });

                it('Includes Venusaur to Mega Venusaur evolution', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('Mega Venusaur');
                    expect(html).toInclude('Mega Evolution');
                });

                it('Includes Venusaur to Gigantamax Venusaur evolution', () => {
                    event = get(route = '/pokemon/1');
                    html  = event.getRenderedContent();
                    expect(html).toInclude('Gigantamax Venusaur');
                    expect(html).toInclude('Gigantamax Form');
                });
            });

            describe('Costume forms', () => {
                it('Includes Halloween costume', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('Halloween');
                });

                it('Includes Pikachu Visor costume', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('Pikachu Visor');
                });

                it('Includes Party Hat costume', () => {
                    event = get(route = '/pokemon/1');
                    expect(event.getRenderedContent()).toInclude('Party Hat');
                });
            });
        });
    }

}
