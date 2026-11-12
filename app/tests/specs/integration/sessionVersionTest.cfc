component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        auth           = getInstance("authenticationService@cbauth");
        accountService = getInstance("services.account");
        trainerService = getInstance("services.trainer");
    }

    /**
     * Change the trainer's password out from under the logged in session (another device, or a reset)
     */
    private void function changePassword(required component trainer) {
        accountService.update(
            trainerid = arguments.trainer.getId(),
            username  = arguments.trainer.getUsername(),
            password  = "NewPass_#createUUID()#",
            email     = arguments.trainer.getEmail(),
            icon      = arguments.trainer.getIcon()
        );
        mockTrainer.refresh(arguments.trainer.getId());
    }

    function run() {
        describe("Session version", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Signs out a session started before the trainer's password changed", () => {
                var trainer = mockTrainer.make(autoLogin = true);
                changePassword(trainer);

                setup();
                var event = execute(route = "/mypokedex");

                expect(auth.isLoggedIn()).toBeFalse();
                expect(event.getValue("relocate_uri")).toBe("/login");
            });

            it("Keeps a session started after the password changed", () => {
                var trainer = mockTrainer.make(autoLogin = true);
                changePassword(trainer);

                mockTrainer.actAsGuest();
                mockTrainer.login(trainerService.getFromId(trainer.getId()));

                setup();
                var event = execute(route = "/mypokedex");

                expect(auth.isLoggedIn()).toBeTrue();
                expect(event.getCurrentEvent()).toBe("pokedex.myPokedex");
            });
        });
    }

}
