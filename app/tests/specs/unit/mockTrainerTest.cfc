component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
    }

    function run() {
        describe("Mock Trainer", () => {
            beforeEach(() => {
                setup();
            });

            describe("Mock trainer life cycle", () => {
                it("Can create a mock trainer", () => {
                    trainer = mockTrainer.make(autoLogin = false);
                    expect(trainer).toBeStruct();
                    expect(session).toHaveKey("mocktrainerid");
                    expect(session.mocktrainerid).toBe(trainer.id);
                });

                it("Can log in a mock trainer", () => {
                    mockTrainer.login(trainer);
                    expect(getInstance("authenticationService@cbauth").getUserId()).toBe(trainer.id);
                });

                it("Can delete a mock trainer", () => {
                    var email = trainer.email;
                    mockTrainer.deleteTrainer();
                    expect(getInstance("authenticationService@cbauth").isLoggedIn()).toBeFalse();

                    // Make sure record deleted
                    expect(getInstance("services.trainer").findByEmail(email)).toBeNull();
                });
            });
        });
    }

}
