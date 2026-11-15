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
        describe("User service (cbauth user service)", () => {
            beforeEach(() => {
                userService    = getInstance("services.user");
                accountService = getInstance("services.account");
                mockTrainer.resetSession();
            });

            describe("retrieveUserById / retrieveUserByUsername", () => {
                it("Returns the cached trainer", () => {
                    expect(userService.retrieveUserById(trainerA.id).getId()).toBe(trainerA.id);
                    expect(userService.retrieveUserByUsername(trainerA.email).getId()).toBe(trainerA.id);
                });

                it("Throws for an unknown trainer", () => {
                    expect(() => userService.retrieveUserById(-999)).toThrow("TrainerNotFound");
                    expect(() => userService.retrieveUserByUsername("nobody_xyzabc123@example.com")).toThrow(
                        "TrainerNotFound"
                    );
                });
            });

            describe("isValidCredentials", () => {
                it("Returns true for a valid email (impersonation enabled in test env)", () => {
                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(userService.isValidCredentials(row.email, createUUID())).toBeTrue();
                });

                it("Returns false when the email is not registered", () => {
                    expect(userService.isValidCredentials("nobody_xyzabc123@example.com", "anypassword")).toBeFalse();
                });

                it("Upgrades a legacy hash to bcrypt when the correct password is supplied", () => {
                    var password = "Legacy_#createUUID()#";
                    mockTrainer.setLegacyPassword(trainerA, password);

                    expect(userService.isValidCredentials(trainerA.email, password)).toBeTrue();

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.password).toMatch("^\$2[aby]\$");
                    expect(row.salt ?: "").toBe("");
                    expect(getInstance("@BCrypt").checkPassword(password, row.password)).toBeTrue();
                });

                it("Leaves a legacy hash alone when the wrong password is supplied", () => {
                    var password   = "Legacy_#createUUID()#";
                    var legacyHash = mockTrainer.setLegacyPassword(trainerA, password);

                    userService.isValidCredentials(trainerA.email, "WrongPass_#createUUID()#");

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.password).toBe(legacyHash);
                });

                describe("WITH impersonation disabled", () => {
                    beforeEach(() => {
                        // Real password checks - impersonation (on in the test env) skips them
                        storedImpersonation = userService.getImpersonation();
                        userService.setImpersonation(false);
                    });

                    afterEach(() => {
                        userService.setImpersonation(storedImpersonation);
                    });

                    it("Returns false for the wrong password against a bcrypt hash", () => {
                        var password   = "Bcrypt_#createUUID()#";
                        var bcryptHash = mockTrainer.setBcryptPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.email, "WrongPass_#createUUID()#")).toBeFalse();
                        expect(userService.isValidCredentials(trainerA.email, "")).toBeFalse();
                        expect(userService.isValidCredentials(trainerA.email, uCase(password))).toBeFalse();

                        var row = mockTrainer.getSaved(trainerA.id);
                        expect(row.password).toBe(bcryptHash);
                    });

                    it("Returns false for the wrong password against a legacy hash", () => {
                        var password = "Legacy_#createUUID()#";
                        mockTrainer.setLegacyPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.email, "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with the upgraded bcrypt hash after a legacy login", () => {
                        var password = "Legacy_#createUUID()#";
                        mockTrainer.setLegacyPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.email, password)).toBeTrue();
                        var row = mockTrainer.getSaved(trainerA.id);
                        expect(row.password).toMatch("^\$2[aby]\$");

                        expect(userService.isValidCredentials(row.email, password)).toBeTrue();
                        expect(userService.isValidCredentials(row.email, "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with a password set through update and rejects the old one", () => {
                        var oldPassword = "OldPass_#createUUID()#";
                        var newPassword = "NewPass_#createUUID()#";
                        mockTrainer.setBcryptPassword(trainerA, oldPassword);

                        accountService.updateTrainer(
                            trainerid = trainerA.id,
                            username  = trainerA.username,
                            password  = newPassword,
                            email     = trainerA.email,
                            icon      = trainerA.icon
                        );

                        expect(userService.isValidCredentials(trainerA.email, newPassword)).toBeTrue();
                        expect(userService.isValidCredentials(trainerA.email, oldPassword)).toBeFalse();
                    });
                });
            });
        });
    }

}
