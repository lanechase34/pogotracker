component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        customService  = getInstance('services.custom');
        pokemonService = getInstance('services.pokemon');
        mockTrainer    = getInstance('tests.resources.mocktrainer');
        customTitle    = 'Test Custom #left(createUUID(), 50)#';
        customid       = -1;
        trainer        = mockTrainer.make();

        pokemonIds = [
            pokemonService.get({
                number : 1,
                name   : 'Bulbasaur',
                gender : '',
                costume: false
            })[1].getId(),
            pokemonService.get({
                number : 2,
                name   : 'Ivysaur',
                gender : '',
                costume: false
            })[1].getId(),
            pokemonService.get({
                number : 3,
                name   : 'Venusaur',
                gender : '',
                costume: false
            })[1].getId(),
            pokemonService.get({
                number     : 1,
                name       : 'Bulbasaur',
                gender     : '',
                costume    : true,
                costumetype: 'Party Hat'
            })[1].getId(),
            pokemonService.get({
                number     : 2,
                name       : 'Ivysaur',
                gender     : '',
                costume    : true,
                costumetype: 'Party Hat'
            })[1].getId()
        ];

        pikachuVisorBulbasaurId = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Pikachu Visor'
        })[1].getId();
        pikachuVisorVenusaurId = pokemonService.get({
            number     : 3,
            name       : 'Venusaur',
            gender     : '',
            costume    : true,
            costumetype: 'Pikachu Visor'
        })[1].getId();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe('Lifecycle events of custom pokedex with normal and costume pokemon', () => {
            beforeEach(() => {
                setup();
            });

            it('Can create the custom pokedex', () => {
                var beforeCount = customHelperFunctions.count();

                event = post(
                    route  = '/pokedex/addCustomPokedex',
                    params = {
                        name   : customTitle,
                        public : false,
                        pokemon: pokemonIds
                    }
                );

                expect(event.getStatusCode()).toBe(200);

                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();
                expect(response).toHaveKey('data');
                expect(response.data.id).toBeInteger();
                expect(customHelperFunctions.count()).toBe(beforeCount + 1);

                customid   = response.data.id;
                var custom = customService.getFromId(customid);

                expect(custom).toBeComponent();
                expect(custom.getName()).toBe(customTitle);
                expect(custom.getPublic()).toBeFalse();
                expect(custom.getCustomPokedex()).toBeArray();
                expect(custom.getCustomPokedex().len()).toBe(pokemonIds.len());
                expect(custom.getTrainer().getId()).toBe(trainer.getId());

                var expectedPokemon = {
                    'Bulbasaur_'         : true,
                    'Ivysaur_'           : true,
                    'Venusaur_'          : true,
                    'Bulbasaur_Party Hat': true,
                    'Ivysaur_Party Hat'  : true
                };

                custom
                    .getCustomPokedex()
                    .each((entry) => {
                        var key = '#entry.getPokemon().getName()#_#entry.getPokemon().getCostumetype()#';
                        expect(expectedPokemon).toHaveKey(key);
                        structDelete(expectedPokemon, key);
                    });

                expect(expectedPokemon.len()).toBe(0);
            });

            it('Registering a costume pokemon does not collide with its normal counterpart, and vice-versa', () => {
                // Step 1: register only normal Bulbasaur as caught (no shiny)
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : pokemonIds[1],
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
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: customid,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                var normalBlock = mid(
                    html,
                    find('data-id="#pokemonIds[1]#"', html),
                    300
                );
                var costumeBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );

                // Normal Bulbasaur should be caught; Party Hat completely unaffected (no collision forward)
                expect(normalBlock).toContain('data-caught="true"');
                expect(costumeBlock).toContain('data-caught="false"');

                // Step 2: register Party Hat as caught + shiny to distinguish it from normal
                setup();
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : pokemonIds[4],
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
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: customid,
                        shiny   : false,
                        hundo   : false
                    }
                );
                html = event.getRenderedContent();

                normalBlock = mid(
                    html,
                    find('data-id="#pokemonIds[1]#"', html),
                    300
                );
                costumeBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );

                // Normal: still only caught, shiny must be false - costume registration did NOT bleed back
                expect(normalBlock).toContain('data-caught="true"');
                expect(normalBlock).toContain('data-shiny="false"');

                // Party Hat: its own independent caught + shiny entry
                expect(costumeBlock).toContain('data-caught="true"');
                expect(costumeBlock).toContain('data-shiny="true"');
            });

            it('Can edit the custom pokedex to add Pikachu Visor costume entries without affecting existing entries', () => {
                var updatedPokemon = duplicate(pokemonIds);
                updatedPokemon.append(pikachuVisorBulbasaurId);
                updatedPokemon.append(pikachuVisorVenusaurId);

                event = post(
                    route  = '/pokedex/editCustomPokedex',
                    params = {
                        customid: customid,
                        name    : customTitle,
                        public  : false,
                        pokemon : updatedPokemon
                    }
                );

                expect(event.getStatusCode()).toBe(200);
                expect(deserializeJSON(event.getRenderedContent()).success).toBeTrue();

                var custom = customService.getFromId(customid);
                expect(custom.getCustomPokedex().len()).toBe(updatedPokemon.len());

                setup();
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: customid,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                expect(html).toContain('data-id="#pokemonIds[1]#"');
                expect(html).toContain('data-id="#pokemonIds[2]#"');
                expect(html).toContain('data-id="#pokemonIds[3]#"');
                expect(html).toContain('data-id="#pokemonIds[4]#"');
                expect(html).toContain('data-id="#pokemonIds[5]#"');
                expect(html).toContain('data-id="#pikachuVisorBulbasaurId#"');
                expect(html).toContain('data-id="#pikachuVisorVenusaurId#"');

                var visorBulbasaurBlock = mid(
                    html,
                    find('data-id="#pikachuVisorBulbasaurId#"', html),
                    300
                );
                var visorVenusaurBlock = mid(
                    html,
                    find('data-id="#pikachuVisorVenusaurId#"', html),
                    300
                );
                expect(visorBulbasaurBlock).toContain('data-caught="false"');
                expect(visorVenusaurBlock).toContain('data-caught="false"');

                var bulbasaurBlock = mid(
                    html,
                    find('data-id="#pokemonIds[1]#"', html),
                    300
                );
                var bulbasaurPartyHatBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );
                expect(bulbasaurBlock).toContain('data-caught="true"');
                expect(bulbasaurBlock).toContain('data-shiny="false"');
                expect(bulbasaurPartyHatBlock).toContain('data-caught="true"');
                expect(bulbasaurPartyHatBlock).toContain('data-shiny="true"');
            });

            it('Two different costume types for the same pokemon are independent of each other', () => {
                // Register Pikachu Visor Bulbasaur as caught (no shiny) to contrast with Party Hat (caught + shiny)
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : pikachuVisorBulbasaurId,
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
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: customid,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                var normalBlock = mid(
                    html,
                    find('data-id="#pokemonIds[1]#"', html),
                    300
                );
                var partyHatBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );
                var pikachuVisorBlock = mid(
                    html,
                    find('data-id="#pikachuVisorBulbasaurId#"', html),
                    300
                );

                // All three share pokemon #1 but have completely independent registrations
                expect(normalBlock).toContain('data-caught="true"');
                expect(normalBlock).toContain('data-shiny="false"');

                // Party Hat untouched by Pikachu Visor registration
                expect(partyHatBlock).toContain('data-caught="true"');
                expect(partyHatBlock).toContain('data-shiny="true"');

                // Pikachu Visor registered as caught only, not shiny
                expect(pikachuVisorBlock).toContain('data-caught="true"');
                expect(pikachuVisorBlock).toContain('data-shiny="false"');
            });

            it('Editing the custom pokedex to remove a costume pokemon is entity-based, not number-based', () => {
                // Remove Party Hat Bulbasaur (pokemonIds[4]) while keeping normal Bulbasaur (pokemonIds[1])
                // and Pikachu Visor Bulbasaur - all three share pokemon number 1
                var updatedPokemon = [
                    pokemonIds[1],
                    pokemonIds[2],
                    pokemonIds[3],
                    pokemonIds[5],
                    pikachuVisorBulbasaurId,
                    pikachuVisorVenusaurId
                ];

                event = post(
                    route  = '/pokedex/editCustomPokedex',
                    params = {
                        customid: customid,
                        name    : customTitle,
                        public  : false,
                        pokemon : updatedPokemon
                    }
                );
                expect(event.getStatusCode()).toBe(200);
                expect(deserializeJSON(event.getRenderedContent()).success).toBeTrue();

                var custom = customService.getFromId(customid);
                expect(custom.getCustomPokedex().len()).toBe(updatedPokemon.len());

                setup();
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: customid,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                // Party Hat Bulbasaur must be gone
                expect(html).notToContain('data-id="#pokemonIds[4]#"');

                // Normal Bulbasaur (same number) and Pikachu Visor (same number) must survive
                expect(html).toContain('data-id="#pokemonIds[1]#"');
                expect(html).toContain('data-id="#pikachuVisorBulbasaurId#"');
            });

            it('Removing a costume pokemon from the custom pokedex does not delete its pokedex registration', () => {
                // Party Hat Bulbasaur was removed from the main custom pokedex in the previous test.
                // Verify its registration (caught=true, shiny=true from test 2) survived by placing it
                // in a fresh mini custom pokedex and checking getCustomPokedex.
                event = post(
                    route  = '/pokedex/addCustomPokedex',
                    params = {
                        name   : 'Verify Party Hat Survival #left(createUUID(), 50)#',
                        public : false,
                        pokemon: [pokemonIds[4]]
                    }
                );
                expect(event.getStatusCode()).toBe(200);
                var miniCustomId = deserializeJSON(event.getRenderedContent()).data.id;

                // Verify the registered entry still exists
                setup();
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: miniCustomId,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                var partyHatBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );
                expect(partyHatBlock).toContain('data-caught="true"');
                expect(partyHatBlock).toContain('data-shiny="true"');

                // Remove the custom pokedex
                setup();
                post(route = '/pokedex/deleteCustomPokedex', params = {customid: miniCustomId});
            });

            it('A pokemon registered before being added to the custom pokedex shows the correct caught status', () => {
                // Register Pikachu Visor Venusaur as caught+shiny BEFORE creating a new custom pokedex that includes it.
                // This verifies createCustomPokedex only writes the join-table entry and does not
                // overwrite or initialise the existing registration.
                event = post(
                    route  = '/pokedex/register',
                    params = {
                        pokemonid  : pikachuVisorVenusaurId,
                        caught     : true,
                        shiny      : true,
                        hundo      : false,
                        shadow     : false,
                        shadowshiny: false
                    }
                );
                expect(event.getStatusCode()).toBe(200);

                setup();
                event = post(
                    route  = '/pokedex/addCustomPokedex',
                    params = {
                        name   : 'Pre-reg Verify #left(createUUID(), 50)#',
                        public : false,
                        pokemon: [pikachuVisorVenusaurId]
                    }
                );
                expect(event.getStatusCode()).toBe(200);
                var preRegCustomId = deserializeJSON(event.getRenderedContent()).data.id;

                setup();
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: preRegCustomId,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                var visorVenusaurBlock = mid(
                    html,
                    find('data-id="#pikachuVisorVenusaurId#"', html),
                    300
                );
                expect(visorVenusaurBlock).toContain('data-caught="true"');
                expect(visorVenusaurBlock).toContain('data-shiny="true"');

                setup();
                post(route = '/pokedex/deleteCustomPokedex', params = {customid: preRegCustomId});
            });

            it('Deleting the custom pokedex does not delete the trainer''s pokedex registrations', () => {
                event = post(route = '/pokedex/deleteCustomPokedex', params = {customid: customid});
                expect(event.getStatusCode()).toBe(200);
                expect(deserializeJSON(event.getRenderedContent()).success).toBeTrue();

                // Custom pokedex entity must be gone
                expect(customService.getFromId(customid)).toBeNull();

                // Verify that pokedex registrations for both normal and costume pokemon survived.
                // Create a fresh mini custom pokedex and check getCustomPokedex to confirm.
                setup();
                event = post(
                    route  = '/pokedex/addCustomPokedex',
                    params = {
                        name   : 'Registration Survival Check #left(createUUID(), 50)#',
                        public : false,
                        pokemon: [
                            pokemonIds[1],
                            pokemonIds[4],
                            pikachuVisorBulbasaurId
                        ]
                    }
                );
                var verifyCustomId = deserializeJSON(event.getRenderedContent()).data.id;

                setup();
                event = get(
                    route  = '/pokedex/getCustomPokedex',
                    params = {
                        customid: verifyCustomId,
                        shiny   : false,
                        hundo   : false
                    }
                );
                var html = event.getRenderedContent();

                // Normal Bulbasaur: caught=true, shiny=false
                var normalBlock = mid(
                    html,
                    find('data-id="#pokemonIds[1]#"', html),
                    300
                );
                expect(normalBlock).toContain('data-caught="true"');
                expect(normalBlock).toContain('data-shiny="false"');

                // Party Hat Bulbasaur: caught=true, shiny=true
                var partyHatBlock = mid(
                    html,
                    find('data-id="#pokemonIds[4]#"', html),
                    300
                );
                expect(partyHatBlock).toContain('data-caught="true"');
                expect(partyHatBlock).toContain('data-shiny="true"');

                // Pikachu Visor Bulbasaur: caught=true, shiny=false
                var visorBlock = mid(
                    html,
                    find('data-id="#pikachuVisorBulbasaurId#"', html),
                    300
                );
                expect(visorBlock).toContain('data-caught="true"');
                expect(visorBlock).toContain('data-shiny="false"');
            });
        });
    }

}
