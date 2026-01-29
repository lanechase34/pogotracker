component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('ORM Functionality Tests', () => {
            beforeEach(() => {
                setup();
            });

            describe('Can load entities', () => {
                it('Can load by PK', () => {
                    var mockedTrainer = mockTrainer.make(autoLogin = false);
                    var trainer       = entityLoadByPK('trainer', mockedTrainer.getId());
                    expect(trainer).notToBeNull();
                    expect(trainer).toBeComponent();
                });

                it('Can load by col', () => {
                    var mockedTrainer = mockTrainer.make(autoLogin = false);
                    var trainer       = entityLoad('trainer', {email: mockedTrainer.getEmail()});
                    expect(trainer).toBeArray();
                    expect(trainer.len()).toBe(1);
                });

                it('Can load many', () => {
                    var trainer = entityLoad('trainer', {});
                    expect(trainer).toBeArray();
                    expect(trainer.len()).toBeGT(1);
                });
            });

            describe('Life cycle methods', () => {
                it('Can make an entity', () => {
                    username  = 'TEST_#left(createUUID().replace('-', '', 'all'), 10)#';
                    newEntity = entityNew(
                        'trainer',
                        {
                            username     : username,
                            email        : '#username#@gmail.com',
                            password     : createUUID(),
                            salt         : createUUID(),
                            friendcode   : mockTrainer.makeFriendcode(),
                            icon         : 'mudkip',
                            securityLevel: 5
                        }
                    );

                    entitySave(newEntity);
                    ormFlush();

                    session.newId = newEntity.getId();

                    // Load entity and verify it saved to DB
                    trainer = entityLoadByPK('trainer', session.newId);
                    expect(trainer).notToBeNull();
                    expect(trainer).toBeComponent();
                    expect(trainer.getUsername()).toBe(username);

                    // ORM pre insert handler
                    expect(trainer.getCreated()).notToBeNull();
                    expect(dateDiff('s', trainer.getCreated(), now())).toBeLT(5);
                    expect(trainer.getUpdated()).notToBeNull();
                    expect(dateDiff('s', trainer.getUpdated(), now())).toBeLT(5);
                });

                it('Save an updated entity', () => {
                    // Wait 2 seconds then update the entity
                    sleep(2000);
                    trainer = entityLoadByPK('trainer', session.newId);
                    before  = trainer.getUpdated();
                    trainer.setIcon('treeko');
                    entitySave(trainer);
                    ormFlush();

                    // Reload the entity and verify changes saved
                    trainer = entityLoadByPK('trainer', session.newId);
                    expect(trainer).notToBeNull();
                    expect(trainer).toBeComponent();
                    expect(trainer.getIcon()).toBe('treeko');

                    // ORM pre update handler - the updated column will change
                    expect(before).toBeLT(trainer.getUpdated());
                    expect(trainer.getCreated()).toBeLT(trainer.getUpdated());
                });

                it('Delete an entity', () => {
                    trainer = entityLoadByPK('trainer', session.newId);
                    entityDelete(trainer);
                    ormFlush();

                    trainer = entityLoadByPK('trainer', session.newId);
                    expect(isNull(trainer)).toBeTrue();
                });
            });

            it('Can ORM reload', () => {
                ormReload();
                currSession = ormGetSession();
                expect(currSession).notToBeNull();
            });
        });
    }

}
