component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        adminService = getInstance("services.admin");
        mockTrainer  = getInstance("tests.resources.mockTrainer");

        // Make sure events needed during the tests are deleted before running
        // Titles with a hardcoded year take it from the leekduck page title, not from the app
        eventNames = [
            "Psychic Spectacular: Taken Over",
            "Cozy Companions",
            "Steeled Resolve",
            "Steeled Resolve #year(now())#",
            "Spring Marathon 2026",
            "Candela's Quest for Victory",
            "Frigibax Community Day",
            "Deino Community Day Classic",
            "Pokémon GO Wild Area 2026: Global"
        ];
        eventNames.each((name) => {
            customHelperFunctions.deleteByName(name);
        });

        // Serve leekduck pages from saved fixtures instead of the network
        // adminService is a singleton shared with the app - the real scraper is put back in afterAll
        originalScraper = adminService.getScraperService();
        adminService.setScraperService(fixtureScraper());
    }

    function afterAll() {
        if(!isNull(variables.originalScraper)) {
            adminService.setScraperService(originalScraper);
        }
        super.afterAll();
    }

    /**
     * A scraper stub whose getData parses the saved leekduck page for the url instead of fetching it
     * The fixture is tests/resources/fixtures/leekduck/{last url path segment}.html
     * Any other url throws so a spec never silently falls back to a live fetch
     */
    private any function fixtureScraper() {
        var jsoup      = getInstance("javaloader:org.jsoup.Jsoup");
        var fixtureDir = expandPath("/tests/resources/fixtures/leekduck");
        // Links that serve another link's page
        var aliases    = {"steeled-resolve-rerun": "steeled-resolve"};

        return createEmptyMock("models.services.scraper")
            .$(method = "getData", preserveArguments = true)
            .$callback((required string targetURL, boolean returnJSON = false) => {
                var link = trim(arguments.targetURL);
                var slug = listLast(link, "/");
                slug     = aliases[slug] ?: slug;
                var path = "#fixtureDir#/#slug#.html";

                if(
                    arguments.returnJSON
                    || !reFindNoCase("^https://leekduck\.com/events/[^/]+/?$", link)
                    || !fileExists(path)
                ) {
                    throw(type = "MissingFixture", message = "No leekduck fixture for #arguments.targetURL#");
                }

                return jsoup.parse(fileRead(path, "utf-8"), link);
            });
    }

    function run() {
        describe("adminService.createEvent", () => {
            beforeEach(() => {
                setup();

                customService = getInstance("services.custom");
                custom        = javacast("null", "");
            });

            it("Can create custom pokedex event with correct information from leekduck", () => {
                eventLink   = "https://leekduck.com/events/cozy-companions/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Cozy Companions");
                expect(custom.public).toBeTrue();
                expect(custom.commday).toBeFalse();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2025, 8, 6));
                expect(custom.ends).toBe(createDate(2025, 8, 12));

                // Verify the pokedex for the custom pokedex
                customPokedex  = customHelperFunctions.getMembers(custom.id);
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    "Snom"                    : 1,
                    "Frosmoth"                : 1,
                    "Abra"                    : 1,
                    "Kadabra"                 : 1,
                    "Alakazam"                : 1,
                    "Geodude"                 : 1,
                    "Graveler"                : 1,
                    "Golem"                   : 1,
                    "Karrablast"              : 1,
                    "Escavalier"              : 1,
                    "Shelmet"                 : 1,
                    "Accelgor"                : 1,
                    "Phantump"                : 1,
                    "Trevenant"               : 1,
                    "Alolan Geodude"          : 1,
                    "Alolan Graveler"         : 1,
                    "Alolan Golem"            : 1,
                    "Pancham"                 : 1,
                    "Pangoro"                 : 1,
                    "Charcadet"               : 1,
                    "Armarouge"               : 1,
                    "Ceruledge"               : 1,
                    "Maushold Family of Three": 1,
                    "Maushold Family of Four" : 1,
                    "Tandemaus"               : 1,
                    "Diglett"                 : 1,
                    "Dugtrio"                 : 1,
                    "Magnemite"               : 1,
                    "Magneton"                : 1,
                    "Magnezone"               : 1,
                    "Lapras"                  : 1,
                    "Klink"                   : 1,
                    "Klang"                   : 1,
                    "Klinklang"               : 1,
                    "Binacle"                 : 1,
                    "Barbaracle"              : 1,
                    "Nosepass"                : 1,
                    "Probopass"               : 1,
                    "Eevee"                   : 1,
                    "Vaporeon"                : 1,
                    "Jolteon"                 : 1,
                    "Flareon"                 : 1,
                    "Espeon"                  : 1,
                    "Umbreon"                 : 1,
                    "Leafeon"                 : 1,
                    "Glaceon"                 : 1,
                    "Sylveon"                 : 1,
                    "Beldum"                  : 1,
                    "Metang"                  : 1,
                    "Metagross"               : 1,
                    "Koffing"                 : 1,
                    "Weezing"                 : 1,
                    "Galarian Weezing"        : 1,
                    "Chansey"                 : 1,
                    "Blissey"                 : 1,
                    "Cherubi"                 : 1,
                    "Cherrim Overcast Form"   : 1,
                    "Cherrim Sunshine Form"   : 1,
                    "Combee"                  : 1,
                    "Vespiquen"               : 1,
                    "Galarian Farfetch'd"     : 1,
                    "Sirfetch'd"              : 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.name);
                    structDelete(expectedSpawns, entry.name);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Will skip shadow pokemon when creating event", () => {
                // Save custom name map
                adminService.saveOverride(
                    name     = "leekducknamemap",
                    override = {"Indeedee (Female)": "Indeedee Female", "Indeedee (Male)": "Indeedee Male"}
                );

                eventLink   = "https://leekduck.com/events/psychic-spectacular-taken-over-2025/ ";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Psychic Spectacular: Taken Over");
                expect(custom.public).toBeTrue();
                expect(custom.commday).toBeFalse();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2025, 9, 16));
                expect(custom.ends).toBe(createDate(2025, 9, 21));

                // Verify the pokedex for the custom pokedex
                customPokedex  = customHelperFunctions.getMembers(custom.id);
                // This is the list of expected spawns for the event
                // This list has no shadow pokemon
                expectedSpawns = {
                    "Abra"             : 1,
                    "Kadabra"          : 1,
                    "Alakazam"         : 1,
                    "Starmie"          : 1,
                    "Jynx"             : 1,
                    "Girafarig"        : 1,
                    "Smoochum"         : 1,
                    "Spoink"           : 1,
                    "Grumpig"          : 1,
                    "Lunatone"         : 1,
                    "Solrock"          : 1,
                    "Chimecho"         : 1,
                    "Beldum"           : 1,
                    "Metang"           : 1,
                    "Metagross"        : 1,
                    "Chingling"        : 1,
                    "Elgyem"           : 1,
                    "Beheeyem"         : 1,
                    "Espurr"           : 1,
                    "Meowstic Male"    : 1,
                    "Meowstic Female"  : 1,
                    "Inkay"            : 1,
                    "Malamar"          : 1,
                    "Alolan Raichu"    : 1,
                    "Galarian Ponyta"  : 1,
                    "Galarian Rapidash": 1,
                    "Galarian Slowpoke": 1,
                    "Galarian Slowbro" : 1,
                    "Galarian Slowking": 1,
                    "Hisuian Braviary" : 1,
                    "Wyrdeer"          : 1,
                    "Indeedee Female"  : 1,
                    "Indeedee Male"    : 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    currName = entry.name;
                    if(entry.gender.len()) {
                        currName = "#entry.name# #entry.gender#";
                    }
                    expect(expectedSpawns).toHaveKey(currName);
                    structDelete(expectedSpawns, currName);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Will append current year to event name if same name already exists", () => {
                var firstLink  = "https://leekduck.com/events/steeled-resolve/";
                // Same page under a new link, like leekduck reusing a title for a rerun (served by the steeled-resolve fixture)
                var secondLink = "https://leekduck.com/events/steeled-resolve-rerun/";

                beforeCount = testData.countRows("custom");

                // Create the first event
                adminService.createEvent(firstLink);

                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);

                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();
                expect(custom.name).toBe("Steeled Resolve");
                expect(custom.commday).toBeFalse();

                // Create the second event with the same name - should have year appended
                adminService.createEvent(secondLink);

                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 2);

                var customid2 = customHelperFunctions.getMostRecentCreated();
                var custom2   = customService.getFromId(customid2);
                expect(custom2).toBeStruct();
                expect(custom2.name).toBe("Steeled Resolve #year(now())#");
                expect(custom2.link).toBe(secondLink);
                expect(custom2.commday).toBeFalse();

                // Clean up second event - first is handled by afterEach
                customService.deleteCustom(custom2);
            });

            it("Can create custom pokedex event with normal and costume pokemon from leekduck", () => {
                // Save custom name map
                adminService.saveOverride(
                    name     = "leekducknamemap",
                    override = {
                        "Flower Crown Buneary"  : {"name": "Buneary", "costumetype": "Flower Crown"},
                        "Cherry Blossom Eevee"  : {"name": "Eevee", "costumetype": "Cherry Blossom"},
                        "Flower Crown Cottonee" : {"name": "Cottonee", "costumetype": "Flower Crown"},
                        "Flower Crown Happiny"  : {"name": "Happiny", "costumetype": "Flower Crown"},
                        "Flower Crown Pichu"    : {"name": "Pichu", "costumetype": "Flower Crown"},
                        "Flower Crown Togepi"   : {"name": "Togepi", "costumetype": "Flower Crown"},
                        "Marathon Visor Pikachu": {"name": "Pikachu", "costumetype": "Marathon Visor"}
                    }
                );

                eventLink   = "https://leekduck.com/events/spring-marathon-2026/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Spring Marathon 2026");
                expect(custom.public).toBeTrue();
                expect(custom.commday).toBeFalse();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2026, 5, 12));
                expect(custom.ends).toBe(createDate(2026, 5, 18));

                // Verify the pokedex for the custom pokedex
                customPokedex  = customHelperFunctions.getMembers(custom.id);
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    "Flower Crown Blissey"   : 1,
                    "Flower Crown Buneary"   : 1,
                    "Flower Crown Chansey"   : 1,
                    "Flower Crown Cottonee"  : 1,
                    "Cherry Blossom Eevee"   : 1,
                    "Espathra"               : 1,
                    "Cherry Blossom Espeon"  : 1,
                    "Cherry Blossom Flareon" : 1,
                    "Flittle"                : 1,
                    "Cherry Blossom Glaceon" : 1,
                    "Flower Crown Happiny"   : 1,
                    "Cherry Blossom Jolteon" : 1,
                    "Cherry Blossom Leafeon" : 1,
                    "Flower Crown Lopunny"   : 1,
                    "Flower Crown Pichu"     : 1,
                    "Flower Crown Pikachu"   : 1,
                    "Flower Crown Raichu"    : 1,
                    "Cherry Blossom Sylveon" : 1,
                    "Flower Crown Togekiss"  : 1,
                    "Flower Crown Togepi"    : 1,
                    "Flower Crown Togetic"   : 1,
                    "Cherry Blossom Umbreon" : 1,
                    "Cherry Blossom Vaporeon": 1,
                    "Flower Crown Whimsicott": 1,
                    "Marathon Visor Pikachu" : 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    // Build the pokemon key using costumetype too
                    var curr = entry.name;
                    if(entry.costume) {
                        curr = "#entry.costumetype# #curr#";
                    }
                    expect(expectedSpawns).toHaveKey(curr);
                    structDelete(expectedSpawns, curr);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Can create event with a normal pokemon and its costume form from the battle pass", () => {
                // Save custom name map
                adminService.saveOverride(
                    name     = "leekducknamemap",
                    override = {"Candela Accessory Ponyta": {"name": "Ponyta", "costumetype": "Candela"}}
                );

                eventLink   = "https://leekduck.com/events/candelas-quest-for-victory/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Candela's Quest for Victory");
                expect(custom.public).toBeTrue();
                expect(custom.commday).toBeFalse();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2026, 6, 9));
                expect(custom.ends).toBe(createDate(2026, 6, 15));

                // Verify the pokedex for the custom pokedex
                customPokedex = customHelperFunctions.getMembers(custom.id);

                // Only check the base + costume variant (from battle pass)
                expectedSpawns = {
                    "Ponyta"          : 1,
                    "Candela Ponyta"  : 1,
                    "Rapidash"        : 1,
                    "Candela Rapidash": 1
                };

                customPokedex.each((entry) => {
                    // Build the pokemon key using costumetype too
                    var curr = entry.name;
                    if(entry.costume) {
                        curr = "#entry.costumetype# #curr#";
                    }
                    structDelete(expectedSpawns, curr);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Can create community day event and flags it as commday", () => {
                eventLink   = "https://leekduck.com/events/june-communityday2026/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Frigibax Community Day");
                expect(custom.public).toBeTrue();
                // Community day events are flagged so they can be excluded from user pokedex lists
                expect(custom.commday).toBeTrue();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2026, 6, 20));
                expect(custom.ends).toBe(createDate(2026, 6, 20));

                // Verify the pokedex for the custom pokedex
                customPokedex  = customHelperFunctions.getMembers(custom.id);
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    "Frigibax"  : 1,
                    "Arctibax"  : 1,
                    "Baxcalibur": 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.name);
                    structDelete(expectedSpawns, entry.name);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Can create community day classic event and flags it as commday", () => {
                eventLink   = "https://leekduck.com/events/may-communitydayclassic2026/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Verify the contents of the custom pokedex
                expect(custom.name).toBe("Deino Community Day Classic");
                expect(custom.public).toBeTrue();
                // Community day classic events are flagged so they can be excluded from user pokedex lists
                expect(custom.commday).toBeTrue();
                expect(custom.trainerid).toBe(1); // defaults to administrator since this is a scheduled task typically
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2026, 5, 16));
                expect(custom.ends).toBe(createDate(2026, 5, 16));

                // Verify the pokedex for the custom pokedex
                customPokedex  = customHelperFunctions.getMembers(custom.id);
                // This is the list of expected spawns for the event
                expectedSpawns = {
                    "Deino"    : 1,
                    "Zweilous" : 1,
                    "Hydreigon": 1
                };

                expect(customPokedex.len()).toBe(expectedSpawns.count());

                customPokedex.each((entry) => {
                    expect(expectedSpawns).toHaveKey(entry.name);
                    structDelete(expectedSpawns, entry.name);
                });

                expect(expectedSpawns.count()).toBe(0);
            });

            it("Can create multi-day event using first and last day schedule rows", () => {
                eventLink   = "https://leekduck.com/events/pokemon-go-wild-area-2026-global/";
                beforeCount = testData.countRows("custom");

                adminService.createEvent(eventLink);

                // Verify a custom pokedex was created for the event
                afterCount = testData.countRows("custom");
                expect(afterCount).toBe(beforeCount + 1);
                customid = customHelperFunctions.getMostRecentCreated();
                custom   = customService.getFromId(customid);
                expect(custom).toBeStruct();

                // Schedule renders one data-kind=day row per day - begins is day 1 start, ends is day 2 end
                // The year is part of the leekduck page title
                expect(custom.name).toBe("Pokémon GO Wild Area 2026: Global");
                expect(custom.link).toBe(eventLink);
                expect(custom.begins).toBe(createDate(2026, 11, 14));
                expect(custom.ends).toBe(createDate(2026, 11, 15));
            });

            afterEach(() => {
                if(!isNull(custom)) {
                    customService.deleteCustom(custom);
                }
            });
        });

        describe("customService.getMine", () => {
            beforeEach(() => {
                setup();
                customService = getInstance("services.custom");
                trainer       = mockTrainer.make(autoLogin = false);
            });

            it("Excludes community day events but includes normal custom pokedexes", () => {
                var normalName  = "Normal Custom #createUUID()#";
                var commdayName = "Commday Custom #createUUID()#";

                var normalId = customService.create(
                    trainerid = trainer.id,
                    name      = normalName,
                    isPublic  = false,
                    commday   = false
                );
                var commdayId = customService.create(
                    trainerid = trainer.id,
                    name      = commdayName,
                    isPublic  = false,
                    commday   = true
                );

                var results = customService.getMine(trainerid = trainer.id);
                var ids     = results.map((entry) => entry.id);

                expect(ids).toContain(normalId);
                expect(ids).notToContain(commdayId);

                customService.deleteCustom(customService.getFromId(normalId));
                customService.deleteCustom(customService.getFromId(commdayId));
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });
        });

        describe("customService.searchMyCustom", () => {
            beforeEach(() => {
                setup();
                customService = getInstance("services.custom");
                trainer       = mockTrainer.make(autoLogin = false);
            });

            it("Excludes community day events but includes normal custom pokedexes", () => {
                var searchTerm  = "SearchTerm#createUUID()#";
                var normalName  = "#searchTerm# Normal";
                var commdayName = "#searchTerm# Commday";

                var normalId = customService.create(
                    trainerid = trainer.id,
                    name      = normalName,
                    isPublic  = false,
                    commday   = false
                );
                var commdayId = customService.create(
                    trainerid = trainer.id,
                    name      = commdayName,
                    isPublic  = false,
                    commday   = true
                );

                var results = customService.searchMyCustom(
                    trainerid = trainer.id,
                    search    = searchTerm,
                    page      = 1
                );
                var ids = results.results.map((entry) => entry.id);

                expect(ids).toContain(normalId);
                expect(ids).notToContain(commdayId);

                customService.deleteCustom(customService.getFromId(normalId));
                customService.deleteCustom(customService.getFromId(commdayId));
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });
        });

        describe("pokemonService.getPreviousEvents", () => {
            beforeEach(() => {
                setup();
                customService  = getInstance("services.custom");
                pokemonService = getInstance("services.pokemon");
                trainer        = mockTrainer.make(autoLogin = false);
            });

            it("Includes community day events without a link but excludes user-made pokedexes", () => {
                var targetPokemon = pokemonService.findPokemon({
                    number : 1,
                    name   : "Bulbasaur",
                    gender : "",
                    costume: false
                })[1];

                var commdayName = "Commday Previous Event #createUUID()#";
                var userName    = "User Pokedex #createUUID()#";

                // Community day events are not guaranteed to have a leekduck link
                var commdayId = customService.create(
                    trainerid = trainer.id,
                    name      = commdayName,
                    isPublic  = true,
                    link      = "",
                    commday   = true
                );
                // A normal user-made pokedex also has no link and must not show up as a "previous event"
                var userId = customService.create(
                    trainerid = trainer.id,
                    name      = userName,
                    isPublic  = true,
                    link      = "",
                    commday   = false
                );

                customService.createCustomPokedex(customService.getFromId(commdayId), [targetPokemon.id]);
                customService.createCustomPokedex(customService.getFromId(userId), [targetPokemon.id]);

                var events = pokemonService.getPreviousEvents(pokemon = targetPokemon, limit = 1000);
                var names  = events.map((entry) => entry.name);

                expect(names).toContain(commdayName);
                expect(names).notToContain(userName);

                customService.deleteCustom(customService.getFromId(commdayId));
                customService.deleteCustom(customService.getFromId(userId));
            });

            afterEach(() => {
                mockTrainer.deleteTrainer();
            });
        });
    }

}
