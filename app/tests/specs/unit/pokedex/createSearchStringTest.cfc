component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.createSearchString', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Can get strings for generation 1', () => {
                count      = randRange(25, 50);
                generation = 1;
                info       = pokedexHelperFunctions.getGenerationInfo(generation);
                pokedexHelperFunctions.registerRandom(count, 1, info, trainer);

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Kanto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered, false)).toBe(count);

                // Get the complete search string
                searchString = pokedexService.createSearchString(registered, '');
                expect(searchString).toBeString();
                expect(listToArray(searchString, ',').len()).toBe(info.ids.len());

                // Check the 'missing' search string
                missingSearchString = pokedexService.createSearchString(registered, '', true);
                expect(missingSearchString).toBeString();

                // Expect the missing search string to have the count of registered pokemon less
                expect(listToArray(missingSearchString, ',').len()).toBe(info.ids.len() - count);
            });

            it('Can get strings for generation 2', () => {
                count      = randRange(15, 30);
                generation = 2;
                info       = pokedexHelperFunctions.getGenerationInfo(generation);
                pokedexHelperFunctions.registerRandom(count, generation, info, trainer);

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = 'Johto',
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered, false)).toBe(count);

                // Get the complete search string
                searchString = pokedexService.createSearchString(registered, '');
                expect(searchString).toBeString();
                expect(listToArray(searchString, ',').len()).toBe(info.ids.len());

                // Check the 'missing' search string
                missingSearchString = pokedexService.createSearchString(registered, '', true);
                expect(missingSearchString).toBeString();
                // Expect the missing search string to have the count of registered pokemon less
                expect(listToArray(missingSearchString, ',').len()).toBe(info.ids.len() - count);
            });

            it('Can get strings for random gen 3-9', () => {
                count      = randRange(5, 15);
                generation = randRange(3, 9);
                info       = pokedexHelperFunctions.getGenerationInfo(generation);
                pokedexHelperFunctions.registerRandom(count, generation, info, trainer);

                registered = pokedexService.getRegistered(
                    trainer = trainer,
                    region  = info.region,
                    form    = false,
                    mega    = false,
                    shadow  = false,
                    giga    = false
                );
                expect(pokedexHelperFunctions.countRegistered(registered, false)).toBe(count);

                // Get the complete search string
                searchString = pokedexService.createSearchString(registered, '');
                expect(searchString).toBeString();
                expect(listToArray(searchString, ',').len()).toBe(info.ids.len());

                // Check the 'missing' search string
                missingSearchString = pokedexService.createSearchString(registered, '', true);
                expect(missingSearchString).toBeString();
                // Expect the missing search string to have the count of registered pokemon less
                expect(listToArray(missingSearchString, ',').len()).toBe(info.ids.len() - count);
            });

            it('Returns a correct string for ''shiny''', () => {
                var mockPokemon = [
                    [
                        {
                            getNumber: () => {
                                return 1;
                            }
                        },
                        {}
                    ],
                    [
                        {
                            getNumber: () => {
                                return 2;
                            }
                        },
                        {}
                    ]
                ];
                var result = pokedexService.createSearchString(pokedex = mockPokemon, view = 'shiny');
                expect(result).toBe('shiny&1,2,');
            });

            it('Returns a correct string for ''shadow''', () => {
                var mockPokemon = [
                    [
                        {
                            getNumber: () => {
                                return 3;
                            }
                        },
                        {}
                    ]
                ];
                var result = pokedexService.createSearchString(pokedex = mockPokemon, view = 'shadow');
                expect(result).toBe('shadow&3,');
            });

            it('Returns a correct string for ''hundo''', () => {
                var mockPokemon = [
                    [
                        {
                            getNumber: () => {
                                return 4;
                            }
                        },
                        {}
                    ]
                ];
                var result = pokedexService.createSearchString(pokedex = mockPokemon, view = 'hundo');
                expect(result).toBe('4*&4,');
            });

            it('Returns a correct string for ''shadowshiny''', () => {
                var mockPokemon = [
                    [
                        {
                            getNumber: () => {
                                return 5;
                            }
                        },
                        {}
                    ]
                ];
                var result = pokedexService.createSearchString(pokedex = mockPokemon, view = 'shadowshiny');
                expect(result).toBe('shadow&shiny&5,');
            });

            it('returns only unregistered when unregisteredOnly is true', () => {
                var mockPokemon = [
                    [
                        {
                            getNumber: () => {
                                return 6;
                            }
                        }
                    ], // unregistered
                    [
                        {
                            getNumber: () => {
                                return 7;
                            }
                        },
                        {}
                    ] // registered
                ];
                var result = pokedexService.createSearchString(
                    pokedex          = mockPokemon,
                    view             = '',
                    unregisteredOnly = true
                );
                expect(result).toBe('6,');
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
