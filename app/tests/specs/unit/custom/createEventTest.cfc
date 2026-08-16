component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        adminService = getInstance('services.admin');
        mockTrainer  = getInstance('tests.resources.mocktrainer');

        // Make sure events needed during the tests are deleted before running
        eventNames = [
            'Psychic Spectacular: Taken Over',
            'Cozy Companions',
            'Steeled Resolve',
            'Steeled Resolve 2026',
            'Spring Marathon 2026',
            'Candela''s Quest for Victory',
            'Frigibax Community Day',
            'Deino Community Day Classic'
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

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Cozy Companions');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getCommday()).toBeFalse();
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
                // Save custom name map
                adminService.saveOverride(
                    name     = 'leekducknamemap',
                    override = {'Indeedee (Female)': 'Indeedee Female', 'Indeedee (Male)': 'Indeedee Male'}
                );

                eventLink   = 'https://leekduck.com/events/psychic-spectacular-taken-over-2025/ ';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Psychic Spectacular: Taken Over');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getCommday()).toBeFalse();
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

            it('Will append current year to event name if same name already exists', () => {
                var firstLink  = 'https://leekduck.com/events/steeled-resolve/';
                var secondLink = 'https://leekduck.com/events/steeled-resolve-2026/';
                var customid2  = -1;
                var custom2    = javacast('null', '');

                beforeCount = customHelperFunctions.count();

                // Create the first event
                adminService.createEvent(firstLink);

                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);

                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();
                expect(custom.getName()).toBe('Steeled Resolve');
                expect(custom.getCommday()).toBeFalse();

                // Create the second event with the same name - should have year appended
                adminService.createEvent(secondLink);

                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 2);

                customid2 = customHelperFunctions.getMostRecentCreated();
                custom2   = customService.getFromId(customid2);
                expect(custom2).toBeComponent();
                expect(custom2.getName()).toBe('Steeled Resolve 2026');
                expect(custom2.getCommday()).toBeFalse();

                // Clean up second event - first is handled by afterEach
                customService.delete(custom2);
            });

            it('Can create custom pokedex event with normal and costume pokemon from leekduck', () => {
                // Save custom name map
                adminService.saveOverride(
                    name     = 'leekducknamemap',
                    override = {
                        'Flower Crown Buneary'  : {'name': 'Buneary', 'costumetype': 'Flower Crown'},
                        'Cherry Blossom Eevee'  : {'name': 'Eevee', 'costumetype': 'Cherry Blossom'},
                        'Flower Crown Cottonee' : {'name': 'Cottonee', 'costumetype': 'Flower Crown'},
                        'Flower Crown Happiny'  : {'name': 'Happiny', 'costumetype': 'Flower Crown'},
                        'Flower Crown Pichu'    : {'name': 'Pichu', 'costumetype': 'Flower Crown'},
                        'Flower Crown Togepi'   : {'name': 'Togepi', 'costumetype': 'Flower Crown'},
                        'Marathon Visor Pikachu': {'name': 'Pikachu', 'costumetype': 'Marathon Visor'}
                    }
                );

                eventLink   = 'https://leekduck.com/events/spring-marathon-2026/';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Spring Marathon 2026');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getCommday()).toBeFalse();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2026, 5, 12));
                expect(custom.getEnds()).toBe(createDate(2026, 5, 18));

                // Verify the pokedex for the custom pokedex
                customPokedex  = custom.getCustomPokedex();
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    'Flower Crown Blissey'   : 1,
                    'Flower Crown Buneary'   : 1,
                    'Flower Crown Chansey'   : 1,
                    'Flower Crown Cottonee'  : 1,
                    'Cherry Blossom Eevee'   : 1,
                    'Espathra'               : 1,
                    'Cherry Blossom Espeon'  : 1,
                    'Cherry Blossom Flareon' : 1,
                    'Flittle'                : 1,
                    'Cherry Blossom Glaceon' : 1,
                    'Flower Crown Happiny'   : 1,
                    'Cherry Blossom Jolteon' : 1,
                    'Cherry Blossom Leafeon' : 1,
                    'Flower Crown Lopunny'   : 1,
                    'Flower Crown Pichu'     : 1,
                    'Flower Crown Pikachu'   : 1,
                    'Flower Crown Raichu'    : 1,
                    'Cherry Blossom Sylveon' : 1,
                    'Flower Crown Togekiss'  : 1,
                    'Flower Crown Togepi'    : 1,
                    'Flower Crown Togetic'   : 1,
                    'Cherry Blossom Umbreon' : 1,
                    'Cherry Blossom Vaporeon': 1,
                    'Flower Crown Whimsicott': 1,
                    'Marathon Visor Pikachu' : 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    // Build the pokemon key using costumetype too
                    var curr = entry.getPokemon().getName();
                    if(entry.getPokemon().getCostume()) {
                        curr = '#entry.getPokemon().getCostumeType()# #curr#';
                    }
                    expect(expectedSpawns).toHaveKey(curr);
                    structDelete(expectedSpawns, curr);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it('Can create event with a normal pokemon and its costume form from the battle pass', () => {
                // Save custom name map
                adminService.saveOverride(
                    name     = 'leekducknamemap',
                    override = {'Candela Accessory Ponyta': {'name': 'Ponyta', 'costumetype': 'Candela'}}
                );

                eventLink   = 'https://leekduck.com/events/candelas-quest-for-victory/';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Candela''s Quest for Victory');
                expect(custom.getPublic()).toBeTrue();
                expect(custom.getCommday()).toBeFalse();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2026, 6, 9));
                expect(custom.getEnds()).toBe(createDate(2026, 6, 15));

                // Verify the pokedex for the custom pokedex
                customPokedex = custom.getCustomPokedex();

                // Only check the base + costume variant (from battle pass)
                expectedSpawns = {
                    'Ponyta'          : 1,
                    'Candela Ponyta'  : 1,
                    'Rapidash'        : 1,
                    'Candela Rapidash': 1
                };

                customPokedex.each((entry) => {
                    // Build the pokemon key using costumetype too
                    var curr = entry.getPokemon().getName();
                    if(entry.getPokemon().getCostume()) {
                        curr = '#entry.getPokemon().getCostumeType()# #curr#';
                    }
                    structDelete(expectedSpawns, curr);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it('Can create community day event and flags it as commday', () => {
                eventLink   = 'https://leekduck.com/events/june-communityday2026/';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Frigibax Community Day');
                expect(custom.getPublic()).toBeTrue();
                // Community day events are flagged so they can be excluded from user pokedex lists
                expect(custom.getCommday()).toBeTrue();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2026, 6, 20));
                expect(custom.getEnds()).toBe(createDate(2026, 6, 20));

                // Verify the pokedex for the custom pokedex
                customPokedex  = custom.getCustomPokedex();
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    'Frigibax'  : 1,
                    'Arctibax'  : 1,
                    'Baxcalibur': 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.getPokemon().getName());
                    structDelete(expectedSpawns, entry.getPokemon().getName());
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it('Can create community day classic event and flags it as commday', () => {
                eventLink   = 'https://leekduck.com/events/may-communitydayclassic2026/';
                beforeCount = customHelperFunctions.count();

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = customHelperFunctions.count();
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeComponent();

                // Verify the contents of the custom pokedex
                expect(custom.getName()).toBe('Deino Community Day Classic');
                expect(custom.getPublic()).toBeTrue();
                // Community day classic events are flagged so they can be excluded from user pokedex lists
                expect(custom.getCommday()).toBeTrue();
                expect(custom.getTrainer().getId()).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.getLink()).toBe(eventLink);
                expect(custom.getBegins()).toBe(createDate(2026, 5, 16));
                expect(custom.getEnds()).toBe(createDate(2026, 5, 16));

                // Verify the pokedex for the custom pokedex
                customPokedex  = custom.getCustomPokedex();
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    'Deino'    : 1,
                    'Zweilous' : 1,
                    'Hydreigon': 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.getPokemon().getName());
                    structDelete(expectedSpawns, entry.getPokemon().getName());
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

        describe('customService.getMine', () => {
            beforeEach(() => {
                setup();
                customService = getInstance('services.custom');
                trainer       = mockTrainer.make();
            });

            it('Excludes community day events but includes normal custom pokedexes', () => {
                var normalName  = 'Normal Custom #createUUID()#';
                var commdayName = 'Commday Custom #createUUID()#';

                var normalId = customService.create(
                    trainer = trainer,
                    name    = normalName,
                    public  = false,
                    commday = false
                );
                var commdayId = customService.create(
                    trainer = trainer,
                    name    = commdayName,
                    public  = false,
                    commday = true
                );

                var results = customService.getMine(trainer = trainer);
                var ids     = results.map((entry) => entry.getId());

                expect(ids).toContain(normalId);
                expect(ids).notToContain(commdayId);

                customService.delete(customService.getFromId(normalId));
                customService.delete(customService.getFromId(commdayId));
            });

            afterEach(() => {
                mockTrainer.delete();
            });
        });

        describe('customService.searchMyCustom', () => {
            beforeEach(() => {
                setup();
                customService = getInstance('services.custom');
                trainer       = mockTrainer.make();
            });

            it('Excludes community day events but includes normal custom pokedexes', () => {
                var searchTerm  = 'SearchTerm#createUUID()#';
                var normalName  = '#searchTerm# Normal';
                var commdayName = '#searchTerm# Commday';

                var normalId = customService.create(
                    trainer = trainer,
                    name    = normalName,
                    public  = false,
                    commday = false
                );
                var commdayId = customService.create(
                    trainer = trainer,
                    name    = commdayName,
                    public  = false,
                    commday = true
                );

                var results = customService.searchMyCustom(trainer = trainer, search = searchTerm, page = 1);
                var ids     = results.results.map((entry) => entry.id);

                expect(ids).toContain(normalId);
                expect(ids).notToContain(commdayId);

                customService.delete(customService.getFromId(normalId));
                customService.delete(customService.getFromId(commdayId));
            });

            afterEach(() => {
                mockTrainer.delete();
            });
        });

        describe('pokemonService.getPreviousEvents', () => {
            beforeEach(() => {
                setup();
                customService  = getInstance('services.custom');
                pokemonService = getInstance('services.pokemon');
                trainer        = mockTrainer.make();
            });

            it('Includes community day events without a link but excludes user-made pokedexes', () => {
                var targetPokemon = pokemonService.get({
                    number : 1,
                    name   : 'Bulbasaur',
                    gender : '',
                    costume: false
                })[1];

                var commdayName = 'Commday Previous Event #createUUID()#';
                var userName    = 'User Pokedex #createUUID()#';

                // Community day events are not guaranteed to have a leekduck link
                var commdayId = customService.create(
                    trainer = trainer,
                    name    = commdayName,
                    public  = true,
                    link    = '',
                    commday = true
                );
                // A normal user-made pokedex also has no link and must not show up as a "previous event"
                var userId = customService.create(
                    trainer = trainer,
                    name    = userName,
                    public  = true,
                    link    = '',
                    commday = false
                );

                customService.createCustomPokedex(customService.getFromId(commdayId), [targetPokemon.getId()]);
                customService.createCustomPokedex(customService.getFromId(userId), [targetPokemon.getId()]);

                var events = pokemonService.getPreviousEvents(pokemon = targetPokemon, limit = 1000);
                var names  = events.map((entry) => entry.name);

                expect(names).toContain(commdayName);
                expect(names).notToContain(userName);

                customService.delete(customService.getFromId(commdayId));
                customService.delete(customService.getFromId(userId));
            });

            afterEach(() => {
                mockTrainer.delete();
            });
        });
    }

}
