component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        auth           = getInstance("authenticationService@cbauth");
        accountService = getInstance("services.account");
        trainerService = getInstance("services.trainer");
    }

    /**
     * Change the trainer's password out from under the logged in session (another device, or a reset)
     */
    private void function changePassword(required struct trainer) {
        accountService.updateTrainer(
            trainerid = arguments.trainer.id,
            username  = arguments.trainer.username,
            password  = "NewPass_#createUUID()#",
            email     = arguments.trainer.email,
            icon      = arguments.trainer.icon
        );
        mockTrainer.refresh(arguments.trainer.id);
    }

    function run() {
        describe("Session version", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
            });

            it("Signs out a session started before the trainer's password changed", () => {
                var trainer = mockTrainer.makeSignedIn();
                changePassword(trainer);

                setup();
                var event = execute(route = "/mypokedex");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(event.getValue("relocate_uri")).toBe("/login");
            });

            it("Keeps a session started after the password changed", () => {
                var trainer = mockTrainer.makeSignedIn();
                changePassword(trainer);

                mockTrainer.actAsGuest();
                mockTrainer.login(trainerService.getFromId(trainer.id));

                setup();
                var event = execute(route = "/mypokedex");

                expect(auth.isLoggedIn()).toBeTrue();
                expect(event.getCurrentEvent()).toBe("pokedex.myPokedex");
            });
        });
    }

}
