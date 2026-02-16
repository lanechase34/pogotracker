component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists('mocktrainerid')) mockTrainer.delete();
    }

    function run() {
        describe('Mock Trainer', () => {
            beforeEach(() => {
                setup();
            });

            it('Can be created', () => {
                expect(mockTrainer).toBeComponent();
            });

            describe('Mock trainer life cycle', () => {
                it('Can create a mock trainer', () => {
                    trainer = mockTrainer.make(autoLogin = false);
                    expect(trainer).toBeComponent();
                    expect(session).toHaveKey('mocktrainerid');
                    expect(session.mocktrainerid).toBe(trainer.getId());
                });

                it('Can log in a mock trainer', () => {
                    mockTrainer.login(trainer);
                    expect(session).toHaveKey('email');
                });

                it('Can delete a mock trainer', () => {
                    var email = session.email;
                    mockTrainer.delete();
                    expect(session).notToHaveKey('email');

                    // Make sure record deleted
                    expect(getInstance('services.security').getTrainer(email).len()).toBe(0);
                });
            });
        });
    }

}
