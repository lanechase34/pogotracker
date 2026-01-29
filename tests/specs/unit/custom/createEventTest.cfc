component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        adminService = getInstance('services.admin');
        mockTrainer  = getInstance('tests.resources.mocktrainer');

        // Make sure events needed during the tests are deleted before running
        eventNames = [
            'Psychic Spectacular: Taken Over',
            'Cozy Companions'
        ];
        eventNames.each((name) => {
            customHelperFunctions.deleteByName(name);
        });
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('adminService.createEvent', () => {
            beforeEach(() => {
                setup();

                customService = getInstance('services.custom');
                trainer       = mockTrainer.make(50); // admin trainer
                customid      = -1;
            });

            it('Can be created', () => {
                expect(customService).toBeComponent();
            });

            it('Can create custom pokedex event with correct information from leekduck', () => {
                eventLink   = 'https://leekduck.com/events/cozy-companions/';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                entityReload(custom); // Why do I need this?

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Cozy Companions');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2025, 8, 6));
                expect(custom.getEnds()).toBe(createDate(2025, 8, 12));

                // Verify the pokedex for the custom pokedex
                customPokedex  = custom.getCustomPokedex();
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    'Snom'                    : 1,
                    'Frosmoth'                : 1,
                    'Abra'                    : 1,
                    'Kadabra'                 : 1,
                    'Alakazam'                : 1,
                    'Geodude'                 : 1,
                    'Graveler'                : 1,
                    'Golem'                   : 1,
                    'Karrablast'              : 1,
                    'Escavalier'              : 1,
                    'Shelmet'                 : 1,
                    'Accelgor'                : 1,
                    'Phantump'                : 1,
                    'Trevenant'               : 1,
                    'Alolan Geodude'          : 1,
                    'Alolan Graveler'         : 1,
                    'Alolan Golem'            : 1,
                    'Pancham'                 : 1,
                    'Pangoro'                 : 1,
                    'Charcadet'               : 1,
                    'Armarouge'               : 1,
                    'Ceruledge'               : 1,
                    'Maushold Family of Three': 1,
                    'Maushold Family of Four' : 1,
                    'Tandemaus'               : 1,
                    'Diglett'                 : 1,
                    'Dugtrio'                 : 1,
                    'Magnemite'               : 1,
                    'Magneton'                : 1,
                    'Magnezone'               : 1,
                    'Lapras'                  : 1,
                    'Klink'                   : 1,
                    'Klang'                   : 1,
                    'Klinklang'               : 1,
                    'Binacle'                 : 1,
                    'Barbaracle'              : 1,
                    'Nosepass'                : 1,
                    'Probopass'               : 1,
                    'Eevee'                   : 1,
                    'Vaporeon'                : 1,
                    'Jolteon'                 : 1,
                    'Flareon'                 : 1,
                    'Espeon'                  : 1,
                    'Umbreon'                 : 1,
                    'Leafeon'                 : 1,
                    'Glaceon'                 : 1,
                    'Sylveon'                 : 1,
                    'Beldum'                  : 1,
                    'Metang'                  : 1,
                    'Metagross'               : 1,
                    'Koffing'                 : 1,
                    'Weezing'                 : 1,
                    'Galarian Weezing'        : 1,
                    'Chansey'                 : 1,
                    'Blissey'                 : 1,
                    'Cherubi'                 : 1,
                    'Cherrim Overcast Form'   : 1,
                    'Cherrim Sunshine Form'   : 1,
                    'Combee'                  : 1,
                    'Vespiquen'               : 1,
                    'Galarian Farfetch''d': 1,
                    'Sirfetch''d': 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.getPokemon().getName());
                    structDelete(expectedSpawns, entry.getPokemon().getName());
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it('Will skip shadow pokemon when creating event', () => {
                eventLink   = 'https://leekduck.com/events/psychic-spectacular-taken-over-2025/ ';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                entityReload(custom); // Why do I need this?

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Psychic Spectacular: Taken Over');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2025, 9, 16));
                expect(custom.getEnds()).toBe(createDate(2025, 9, 21));

                // Verify the pokedex for the custom pokedex
                customPokedex  = custom.getCustomPokedex();
                // This is the list of expected spawns for the event
                // This list has no shadow pokemon
                expectedSpawns = {
                    'Abra'             : 1,
                    'Kadabra'          : 1,
                    'Alakazam'         : 1,
                    'Starmie'          : 1,
                    'Jynx'             : 1,
                    'Girafarig'        : 1,
                    'Smoochum'         : 1,
                    'Spoink'           : 1,
                    'Grumpig'          : 1,
                    'Lunatone'         : 1,
                    'Solrock'          : 1,
                    'Chimecho'         : 1,
                    'Beldum'           : 1,
                    'Metang'           : 1,
                    'Metagross'        : 1,
                    'Chingling'        : 1,
                    'Elgyem'           : 1,
                    'Beheeyem'         : 1,
                    'Espurr'           : 1,
                    'Meowstic Male'    : 1,
                    'Meowstic Female'  : 1,
                    'Inkay'            : 1,
                    'Malamar'          : 1,
                    'Alolan Raichu'    : 1,
                    'Galarian Ponyta'  : 1,
                    'Galarian Rapidash': 1,
                    'Galarian Slowpoke': 1,
                    'Galarian Slowbro' : 1,
                    'Galarian Slowking': 1,
                    'Hisuian Braviary' : 1,
                    'Wyrdeer'          : 1,
                    'Indeedee Female'  : 1,
                    'Indeedee Male'    : 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    currName = entry.getPokemon().getName();
                    if(
                        entry
                            .getPokemon()
                            .getGender()
                            .len()
                    ) {
                        currName = '#entry.getPokemon().getName()# #entry.getPokemon().getGender()#';
                    }
                    expect(expectedSpawns).toHaveKey(currName);
                    structDelete(expectedSpawns, currName);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            afterEach(() => {
                if(!isNull(custom)) {
                    customService.delete(custom);
                }
                mockTrainer.delete();
            });
        });
    }

}
