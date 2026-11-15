component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer             = getInstance("tests.resources.mockTrainer");
        originalDefaultSettings = duplicate(application.cbController.getSetting("defaultSettings"));
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("Trainer settings tests", () => {
            beforeEach(() => {
                setup();
                trainerService = getInstance("services.trainer");
                trainer        = mockTrainer.make(10, false);
            });

            it("Trainer can getSettings()", () => {
                var settings = trainerService.getFromId(trainer.id).settings;
                expect(settings).toBeStruct();
                expect(settings).toBeEmpty();
            });

            it("Trainer can update their settings", () => {
                trainerService.updateSettings(trainer.id, {defaultView: "shiny", defaultRegion: "Unova"});

                var settings = trainerService.getFromId(trainer.id).settings;
                expect(settings).toBeStruct();
                expect(settings.defaultView).toBe("shiny");
                expect(settings.defaultRegion).toBe("Unova");
            });

            describe("Trainer's settings will auto update on login if a new key is present in the default settings", () => {
                afterEach(() => {
                    // Restore in place - services inject this same struct, so swapping in a new one wouldn't reach them
                    var live = application.cbController.getSetting("defaultSettings");
                    live.clear();
                    live.append(duplicate(originalDefaultSettings));
                });

                it("Can update if a simple value is added", () => {
                    mockTrainer.login(trainer);
                    var settings = trainerService.getFromId(trainer.id).settings;
                    expect(settings.count()).toBe(application.cbController.getSetting("defaultSettings").count());

                    var temp   = application.cbController.getSetting("defaultSettings");
                    temp.chase = createUUID();
                    application.cbController.setSetting("defaultSettings", temp);

                    mockTrainer.logout();

                    // Apply new settings on login
                    mockTrainer.login(trainer);
                    settings = trainerService.getFromId(trainer.id).settings;
                    expect(settings.count()).toBe(application.cbController.getSetting("defaultSettings").count());
                    expect(settings.chase).toBe(temp.chase);
                });

                it("Can update if a struct is added", () => {
                    mockTrainer.login(trainer);
                    var settings = trainerService.getFromId(trainer.id).settings;
                    expect(settings.count()).toBe(application.cbController.getSetting("defaultSettings").count());

                    var temp     = application.cbController.getSetting("defaultSettings");
                    temp.complex = {chase: createUUID(), lane: createUUID()};
                    application.cbController.setSetting("defaultSettings", temp);

                    mockTrainer.logout();

                    // Apply new settings on login
                    mockTrainer.login(trainer);
                    settings = trainerService.getFromId(trainer.id).settings;
                    expect(settings.count()).toBe(application.cbController.getSetting("defaultSettings").count());

                    // Check the complex settings value
                    expect(settings.complex).toBeStruct();
                    expect(settings.complex).toHaveKey("chase");
                    expect(settings.complex.chase).toBe(temp.complex.chase);
                    expect(settings.complex).toHaveKey("lane");
                    expect(settings.complex.lane).toBe(temp.complex.lane);
                });
            });

            describe("Test settings behaviors", () => {
                it("Default page will change the relocate event after login", () => {
                    mockTrainer.login(trainer);

                    var settings         = trainerService.getFromId(trainer.id).settings;
                    settings.defaultPage = "/buildtradeplan";
                    trainerService.updateSettings(trainer.id, settings);
                    mockTrainer.logout();
                    mockTrainer.login(trainer, "/buildtradeplan");

                    settings             = trainerService.getFromId(trainer.id).settings;
                    settings.defaultPage = "/mypokedex";
                    trainerService.updateSettings(trainer.id, settings);
                    mockTrainer.logout();
                    mockTrainer.login(trainer, "/mypokedex");
                });
            });

            afterEach(() => {
                mockTrainer.deleteTrainer(); // Delete mock trainer after every request
            });
        });
    }

}
