component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
        trainer     = mockTrainer.make();
        testMedal   = left('Test Medal #createUUID()#', 50);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();

        queryExecute('delete from medal where name like ''%Test Medal%''');
    }

    function run() {
        describe('Medal service tests', () => {
            beforeEach(() => {
                setup();
                medalService = getInstance('services.medal');
            });

            it('Can be created', () => {
                expect(medalService).toBeComponent();
            });

            it('Can getAll medals', () => {
                medals = medalService.getAll();
                expect(medals).toBeArray();
                expect(medals.len()).toBeGT(1);
            });

            it('Cam load medal by name', () => {
                name  = 'Ultra League Veteran';
                medal = medalService.get(name);
                expect(medal).toBeArray();
                expect(medal.len()).toBe(1);
                expect(medal[1].getName()).toBe(name);
            });

            it('Can create a new medal', () => {
                medalProperties = {
                    name        : testMedal,
                    description : 'Testing',
                    bronze      : 1,
                    silver      : 2,
                    gold        : 3,
                    platinum    : 4,
                    displayOrder: 50
                };
                medalService.update(medalProperties);
                ormFlush();

                // Load medal by name
                medal = medalService.get(medalProperties.name);
                expect(medal).toBeArray();
                expect(medal.len()).toBe(1);
                expect(medal[1].getName()).toBe(medalProperties.name);
            });

            it('Can update a medal', () => {
                medalProperties = {
                    name        : testMedal,
                    description : 'Updated',
                    bronze      : 1,
                    silver      : 2,
                    gold        : 3,
                    platinum    : 4,
                    displayOrder: 50
                };
                medalService.update(medalProperties);
                ormFlush();

                // Load medal by name
                medal = medalService.get(medalProperties.name);
                expect(medal).toBeArray();
                expect(medal.len()).toBe(1);
                expect(medal[1].getDescription()).toBe('Updated');
            });

            describe('Trainer medal lifecycle', () => {
                it('Can get medal by name', () => {
                    medal = medalService.get('Youngster');
                    expect(medal).toBeArray();
                    expect(medal.len()).toBe(1);
                    medal = medal[1];
                    expect(medal.getName()).toBe('Youngster');
                });

                it('Can get no progress against medal', () => {
                    medalProgress = medalService.getProgress(trainer);
                    expect(medalProgress).toBeArray();

                    found = false;
                    medalProgress.each((progress) => {
                        if(progress[1].getName() == medal.getName()) {
                            expect(isNull(progress[2])).toBeTrue();
                            found = true;
                            break;
                        }
                    });

                    expect(found).toBeTrue();
                });

                it('Can track progress against medal', () => {
                    silverProg = medal.getSilver();
                    data       = {medal: medal.getId(), current: silverProg};

                    event = post(route = '/stats/trackMedalProgress', params = data);
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();
                });

                it('Can get new progress against medal', () => {
                    medalProgress = medalService.getProgress(trainer);
                    expect(medalProgress).toBeArray();

                    found = false;
                    medalProgress.each((progress) => {
                        if(progress[1].getId() == medal.getId()) {
                            // Expect the amount to be the progress we just tracked
                            expect(progress[2].getCurrent()).toBe(silverProg);
                            found = true;
                            break;
                        }
                    });

                    expect(found).toBeTrue();
                });
            })
        });
    }

}
