component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
        mockTrainer    = getInstance('tests.resources.mocktrainer');

        bulbasaurId = pokemonService.get({
            number : 1,
            name   : 'Bulbasaur',
            gender : '',
            costume: false
        })[1].getId();
        partyHatBulbasaurId = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Party Hat'
        })[1].getId();
        pikachuVisorBulbasaurId = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Pikachu Visor'
        })[1].getId();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedex.myCostumePokedex', () => {
            beforeEach(() => {
                setup();
                trainer = mockTrainer.make();
            });

            afterEach(() => {
                mockTrainer.delete();
            });

            it('Loads the costume pokedex page with the correct structure and data attributes', () => {
                event = get(route = '/mycostumepokedex', renderResults = true);

                expect(event.getResponse().getStatusCode()).toBe(200);

                var html = event.getRenderedContent();
                expect(html).toContain('id="costumePokedexTable"');
                expect(html).toContain('data-costume="true"');
                expect(html).toContain('data-trainerid="#trainer.getId()#"');
                expect(html).toContain('data-shiny="false"');
            });

            it('Sets data-shiny to true on the page when shiny is requested', () => {
                event = get(
                    route         = '/mycostumepokedex',
                    params        = {shiny: true},
                    renderResults = true
                );

                expect(event.getResponse().getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toContain('data-shiny="true"');
            });

            it('Costume pokemon appear in the costume view even before being registered', () => {
                event = get(
                    route  = '/pokedex/getPokedex',
                    params = {
                        costume: true,
                        shiny  : false,
                        region : 'costumeRegion'
                    }
                );

                var html          = event.getRenderedContent();
                var partyHatBlock = mid(
                    html,
                    find('data-id="#partyHatBulbasaurId#"', html),
                    300
                );

                // Costume entry is present in the list
                expect(html).toContain('data-id="#partyHatBulbasaurId#"');
                // But shows as uncaught since it hasn't been registered
                expect(partyHatBlock).toContain('data-caught="false"');
            });

            it('Registered costume pokemon appear as caught in the costume view', () => {
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : partyHatBulbasaurId,
                        caught     : true,
                        shiny      : false,
                        hundo      : false,
                        shadow     : false,
                        shadowshiny: false
                    }
                );
                expect(event.getStatusCode()).toBe(200);

                setup();
                event = get(
                    route  = '/pokedex/getPokedex',
                    params = {
                        costume: true,
                        shiny  : false,
                        region : 'costumeRegion'
                    }
                );

                var html          = event.getRenderedContent();
                var partyHatBlock = mid(
                    html,
                    find('data-id="#partyHatBulbasaurId#"', html),
                    300
                );
                expect(partyHatBlock).toContain('data-caught="true"');
            });

            it('Normal pokemon are excluded from the costume view entirely', () => {
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : bulbasaurId,
                        caught     : true,
                        shiny      : false,
                        hundo      : false,
                        shadow     : false,
                        shadowshiny: false
                    }
                );
                expect(event.getStatusCode()).toBe(200);

                setup();
                event = get(
                    route  = '/pokedex/getPokedex',
                    params = {
                        costume: true,
                        shiny  : false,
                        region : 'costumeRegion'
                    }
                );

                var html = event.getRenderedContent();

                // Normal Bulbasaur (costume=false) must not appear at all in the costume view
                expect(html).notToContain('data-id="#bulbasaurId#"');

                // Its costume counterparts must still be present (and uncaught)
                expect(html).toContain('data-id="#partyHatBulbasaurId#"');
                expect(html).toContain('data-id="#pikachuVisorBulbasaurId#"');
            });

            it('Registering a normal pokemon does not mark its costume counterpart as caught in the costume view', () => {
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : bulbasaurId,
                        caught     : true,
                        shiny      : true,
                        hundo      : false,
                        shadow     : false,
                        shadowshiny: false
                    }
                );
                expect(event.getStatusCode()).toBe(200);

                setup();
                event = get(
                    route  = '/pokedex/getPokedex',
                    params = {
                        costume: true,
                        shiny  : false,
                        region : 'costumeRegion'
                    }
                );

                var html          = event.getRenderedContent();
                var partyHatBlock = mid(
                    html,
                    find('data-id="#partyHatBulbasaurId#"', html),
                    300
                );
                var pikachuVisorBlock = mid(
                    html,
                    find('data-id="#pikachuVisorBulbasaurId#"', html),
                    300
                );

                // Neither costume variant should inherit the normal registration
                expect(partyHatBlock).toContain('data-caught="false"');
                expect(partyHatBlock).toContain('data-shiny="false"');
                expect(pikachuVisorBlock).toContain('data-caught="false"');
            });
        });
    }

}
