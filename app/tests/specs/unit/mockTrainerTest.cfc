component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.delete();
    }

    function run() {
        describe("Mock Trainer", () => {
            beforeEach(() => {
                setup();
            });

            describe("Mock trainer life cycle", () => {
                it("Can create a mock trainer", () => {
                    trainer = mockTrainer.make(autoLogin = false);
                    expect(trainer).toBeComponent();
                    expect(session).toHaveKey("mocktrainerid");
                    expect(session.mocktrainerid).toBe(trainer.getId());
                });

                it("Can log in a mock trainer", () => {
                    mockTrainer.login(trainer);
                    expect(getInstance("authenticationService@cbauth").getUserId()).toBe(trainer.getId());
                });

                it("Can delete a mock trainer", () => {
                    var email = trainer.getEmail();
                    mockTrainer.delete();
                    expect(getInstance("authenticationService@cbauth").isLoggedIn()).toBeFalse();

                    // Make sure record deleted
                    expect(getInstance("services.user").findByEmail(email)).toBeNull();
                });
            });
        });
    }

}
