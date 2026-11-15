component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");
        trainerA    = mockTrainer.make(securityLevel = 10, autoLogin = false);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainerA.id);
    }

    function run() {
        describe("Trainer lookup", () => {
            beforeEach(() => {
                trainerService = getInstance("services.trainer");
            });

            describe("findByEmail", () => {
                it("Returns the trainer when the email exists (any case)", () => {
                    var result = trainerService.findByEmail(uCase(trainerA.email));
                    expect(result.id).toBe(trainerA.id);
                });

                it("Returns null when the email does not exist", () => {
                    expect(trainerService.findByEmail("nobody_xyzabc123@example.com")).toBeNull();
                });
            });
        });
    }

}
