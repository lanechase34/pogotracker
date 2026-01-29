component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance('tests.resources.mocktrainer');
        pokemonService = getInstance('services.pokemon');
        trainer        = mockTrainer.make();
        customTitle    = createUUID();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe('Custom lifecycle events', () => {
            beforeEach(() => {
                setup();
                customService = getInstance('services.custom');
            });

            it('Can be created', () => {
                expect(customService).toBeComponent();
            });

            it('Can create a custom pokedex by posting data to pokedex.addCustomPokedex', () => {
                // Mock custom pokedex data
                data = {
                    name   : 'Test Custom #customTitle#',
                    public : false,
                    pokemon: [
                        pokemonService.get({
                            number: 324,
                            name  : 'Torkoal',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 369,
                            name  : 'Relicanth',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 352,
                            name  : 'Kecleon',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 360,
                            name  : 'Wynaut',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 357,
                            name  : 'Tropius',
                            gender: ''
                        })[1].getId()
                    ]
                };

                beforeCount = customHelperFunctions.count();

                event = post(route = '/pokedex/addCustomPokedex', params = data);

                // Verify the custom pokedex was created
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();
                expect(response).toHaveKey('data');
                expect(response.data.id).toBeInteger();

                expect(customHelperFunctions.count()).toBe(beforeCount + 1);

                // Retrieve the created custom pokedex
                customid = response.data.id;
                custom   = customService.getFromId(customid);

                // Verify the custom pokedex properties
                expect(custom).toBeComponent();

                entityReload(custom); // Why do I need this?

                expect(custom.getName()).toBe(data.name);
                expect(custom.getPublic()).toBe(data.public);
                expect(custom.getCustomPokedex()).toBeArray();
                expect(custom.getCustomPokedex().len()).toBe(data.pokemon.len());
                expect(custom.getTrainer().getId()).toBe(trainer.getId());
            });

            it('Can edit a custom pokedex by posting data to pokedex.editCustomPokedex', () => {
                data = {
                    customid: customid,
                    name    : 'Updated Test Custom #customTitle#',
                    public  : false,
                    pokemon : [
                        pokemonService.get({
                            number: 352,
                            name  : 'Kecleon',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 360,
                            name  : 'Wynaut',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 357,
                            name  : 'Tropius',
                            gender: ''
                        })[1].getId(),
                        pokemonService.get({
                            number: 358,
                            name  : 'Chimecho',
                            gender: ''
                        })[1].getId()
                    ]
                };

                beforeCount = customHelperFunctions.count();

                event = post(route = '/pokedex/editCustomPokedex', params = data);

                // The amount of custom pokedex should not change since we are editing
                expect(customHelperFunctions.count()).toBe(beforeCount);

                // Verify the custom pokedex was updated successfully
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();

                // Check the properties
                entityReload(custom);

                expect(custom.getName()).toBe(data.name);
                expect(custom.getPublic()).toBe(data.public);
                expect(custom.getCustomPokedex()).toBeArray();
                expect(custom.getCustomPokedex().len()).toBe(data.pokemon.len());
                expect(custom.getTrainer().getId()).toBe(trainer.getId());

                // Verify the pokedex entires have updated
                expectedPokemon = {
                    'Kecleon' : 1,
                    'Wynaut'  : 1,
                    'Tropius' : 1,
                    'Chimecho': 1
                };

                custom
                    .getCustomPokedex()
                    .each((entry) => {
                        expect(expectedPokemon).toHaveKey(entry.getPokemon().getName());
                        structDelete(expectedPokemon, entry.getPokemon().getName());
                    });

                expect(expectedPokemon.len()).toBe(0);
            });

            it('Can view the custom pokedex in the customPokedexList', () => {
                event = get(route = '/custompokedexlist', renderResults = true);
                expect(event.getResponse().getStatusCode()).toBe(200);

                // Expect the custom pokedex to be listed
                expect(event.getRenderedContent()).toContain('Updated Test Custom #customTitle#');
                expect(event.getRenderedContent()).toContain('/mycustompokedex/#customid#');
            });

            it('Can view the custom pokedex', () => {
                // Load the page
                event = get(route = '/mycustompokedex/#customid#', renderResults = true);
                expect(event.getResponse().getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toContain('Updated Test Custom #customTitle#');

                // Load the custom pokedex data
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        shiny   : false,
                        hundo   : false,
                        customid: customid
                    }
                );

                expect(event.getRenderedContent()).toContain('id="pokedexGrid"');
                expect(event.getRenderedContent()).toContain('data-name="Kecleon"');
                expect(event.getRenderedContent()).toContain('data-name="Wynaut"');
                expect(event.getRenderedContent()).toContain('data-name="Tropius"');
                expect(event.getRenderedContent()).toContain('data-name="Chimecho"');
            });

            it('Can delete a custom pokedex by posting data to pokedex.deleteCustomPokedex', () => {
                beforeCount = customHelperFunctions.count();

                event = post(route = '/pokedex/deleteCustomPokedex', params = {customid: customid});

                // Verify the custom pokedex was deleted successfully
                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();
                expect(customHelperFunctions.count()).toBe(beforeCount - 1);

                // Verify the custom pokedex no longer exists
                expect(customService.getFromId(customid)).toBeNull();
            });

            afterEach(() => {
            });
        });
    }

}
