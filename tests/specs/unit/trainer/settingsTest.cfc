component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Trainer settings tests', () => {
            beforeEach(() => {
                setup();
                trainerService = getInstance('services.trainer');
                trainer        = mockTrainer.make(10, false);
            });

            it('Can be created', () => {
                expect(trainerService).toBeComponent();
            });

            it('Trainer can getSettings()', () => {
                settings = trainer.getSettings();
                expect(settings).toBeStruct();
                expect(settings).toBeEmpty();
            });

            it('Trainer can get default settings on login', () => {
                mockTrainer.login(trainer);
                settings = trainer.getSettings();
                expect(settings).notToBeEmpty();
                expect(settings.count()).toBe(application.cbController.getSetting('defaultSettings').count());
            });

            it('Trainer can update their settings', () => {
                mockTrainer.login(trainer);

                newSettings               = {};
                newSettings.defaultView   = 'shiny';
                newSettings.defaultRegion = 'Unova';

                trainer.setSettings(newSettings);

                settings = trainer.getSettings();
                expect(settings).toBeStruct();
                expect(settings.defaultView).toBe('shiny');
                expect(settings.defaultRegion).toBe('Unova');
            });

            describe('Trainer''s settings will auto update on login if a new key is present in the default settings', () => {
                it('Can update if a simple value is added', () => {
                    mockTrainer.login(trainer);
                    settings = trainer.getSettings();
                    expect(settings.count()).toBe(application.cbController.getSetting('defaultSettings').count());

                    temp       = application.cbController.getSetting('defaultSettings');
                    temp.chase = createUUID();
                    application.cbController.setSetting('defaultSettings', temp);

                    mockTrainer.logout();

                    // Apply new settings on login
                    mockTrainer.login(trainer);
                    settings = trainer.getSettings();
                    expect(settings.count()).toBe(application.cbController.getSetting('defaultSettings').count());
                    expect(settings.chase).toBe(temp.chase);
                });

                it('Can update if a struct is added', () => {
                    mockTrainer.login(trainer);
                    settings = trainer.getSettings();
                    expect(settings.count()).toBe(application.cbController.getSetting('defaultSettings').count());

                    temp         = application.cbController.getSetting('defaultSettings');
                    temp.complex = {chase: createUUID(), lane: createUUID()};
                    application.cbController.setSetting('defaultSettings', temp);

                    mockTrainer.logout();

                    // Apply new settings on login
                    mockTrainer.login(trainer);
                    settings = trainer.getSettings();
                    expect(settings.count()).toBe(application.cbController.getSetting('defaultSettings').count());

                    // Check the complex settings value
                    expect(settings.complex).toBeStruct();
                    expect(settings.complex).toHaveKey('chase');
                    expect(settings.complex.chase).toBe(temp.complex.chase);
                    expect(settings.complex).toHaveKey('lane');
                    expect(settings.complex.lane).toBe(temp.complex.lane);
                });
            });

            describe('Test settings behaviors', () => {
                it('Default page will change the relocate event after login', () => {
                    mockTrainer.login(trainer);

                    settings             = trainer.getSettings();
                    settings.defaultPage = '/buildtradeplan';
                    trainer.setSettings(settings);
                    mockTrainer.logout();
                    mockTrainer.login(trainer, '/buildtradeplan');

                    settings             = trainer.getSettings();
                    settings.defaultPage = '/mypokedex';
                    trainer.setSettings(settings);
                    mockTrainer.logout();
                    mockTrainer.login(trainer, '/mypokedex');
                });
            });

            afterEach(() => {
                mockTrainer.delete(); // Delete mock trainer after every request
            });
        });
    }

}
