component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");

        // trainerA is the primary subject; trainerB is used for uniqueness-conflict assertions
        trainerA   = mockTrainer.make(securityLevel = 10, autoLogin = false);
        trainerAId = trainerA.getId();
        trainerB   = mockTrainer.make(securityLevel = 10, autoLogin = false);
        trainerBId = trainerB.getId();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete(trainerBId);
        mockTrainer.delete(trainerAId);
    }

    function run() {
        describe("User service (cbauth user service)", () => {
            beforeEach(() => {
                setup();
                sessionService = getInstance("services.session");
                userService    = getInstance("services.user");
                accountService = getInstance("services.account");
                sessionService.destroy(false);
                // Ensure recaptcha key is present so recaptcha checks never throw
                session.recaptcha = {
                    token    : "",
                    valid    : false,
                    timestamp: now(),
                    action   : ""
                };
                session.sessionid = createUUID();
                setup();
            });

            describe("findByEmail", () => {
                it("Returns the trainer when the email exists (any case)", () => {
                    var result = userService.findByEmail(uCase(trainerA.getEmail()));
                    expect(result.getId()).toBe(trainerA.getId());
                });

                it("Returns null when the email does not exist", () => {
                    expect(userService.findByEmail("nobody_xyzabc123@example.com")).toBeNull();
                });
            });

            describe("retrieveUserById / retrieveUserByUsername", () => {
                it("Returns the cached trainer", () => {
                    expect(userService.retrieveUserById(trainerA.getId()).getId()).toBe(trainerA.getId());
                    expect(userService.retrieveUserByUsername(trainerA.getEmail()).getId()).toBe(trainerA.getId());
                });

                it("Throws for an unknown trainer", () => {
                    expect(() => userService.retrieveUserById(-999)).toThrow("TrainerNotFound");
                    expect(() => userService.retrieveUserByUsername("nobody_xyzabc123@example.com")).toThrow(
                        "TrainerNotFound"
                    );
                });
            });

            describe("checkPassword", () => {
                it("Accepts the trainer's real password", () => {
                    var password = "Check_#createUUID()#";
                    setBcryptPassword(trainerA, password);
                    expect(userService.checkPassword(trainerA, password)).toBeTrue();
                });

                it("Rejects a wrong or blank password even with impersonation on", () => {
                    setBcryptPassword(trainerA, "Check_#createUUID()#");
                    expect(userService.checkPassword(trainerA, "Wrong_#createUUID()#")).toBeFalse();
                    expect(userService.checkPassword(trainerA, "")).toBeFalse();
                });
            });

            describe("isValidCredentials", () => {
                it("Returns true for a valid email (impersonation enabled in test env)", () => {
                    entityReload(trainerA);
                    expect(userService.isValidCredentials(trainerA.getEmail(), createUUID())).toBeTrue();
                });

                it("Returns false when the email is not registered", () => {
                    expect(userService.isValidCredentials("nobody_xyzabc123@example.com", "anypassword")).toBeFalse();
                });

                it("Upgrades a legacy hash to bcrypt when the correct password is supplied", () => {
                    var password = "Legacy_#createUUID()#";
                    setLegacyPassword(trainerA, password);

                    expect(userService.isValidCredentials(trainerA.getEmail(), password)).toBeTrue();

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).toMatch("^\$2[aby]\$");
                    expect(trainerA.getSalt() ?: "").toBe("");
                    expect(getInstance("@BCrypt").checkPassword(password, trainerA.getPassword())).toBeTrue();
                });

                it("Leaves a legacy hash alone when the wrong password is supplied", () => {
                    var password   = "Legacy_#createUUID()#";
                    var legacyHash = setLegacyPassword(trainerA, password);

                    userService.isValidCredentials(trainerA.getEmail(), "WrongPass_#createUUID()#");

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).toBe(legacyHash);
                });

                describe("with impersonation disabled", () => {
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
                        var bcryptHash = setBcryptPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                        expect(userService.isValidCredentials(trainerA.getEmail(), "")).toBeFalse();
                        expect(userService.isValidCredentials(trainerA.getEmail(), uCase(password))).toBeFalse();

                        entityReload(trainerA);
                        expect(trainerA.getPassword()).toBe(bcryptHash);
                    });

                    it("Returns false for the wrong password against a legacy hash", () => {
                        var password = "Legacy_#createUUID()#";
                        setLegacyPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with the upgraded bcrypt hash after a legacy login", () => {
                        var password = "Legacy_#createUUID()#";
                        setLegacyPassword(trainerA, password);

                        expect(userService.isValidCredentials(trainerA.getEmail(), password)).toBeTrue();
                        entityReload(trainerA);
                        expect(trainerA.getPassword()).toMatch("^\$2[aby]\$");

                        expect(userService.isValidCredentials(trainerA.getEmail(), password)).toBeTrue();
                        expect(userService.isValidCredentials(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with a password set through update and rejects the old one", () => {
                        var oldPassword = "OldPass_#createUUID()#";
                        var newPassword = "NewPass_#createUUID()#";
                        setBcryptPassword(trainerA, oldPassword);

                        accountService.update(
                            trainerid = trainerA.getId(),
                            username  = trainerA.getUsername(),
                            password  = newPassword,
                            email     = trainerA.getEmail(),
                            icon      = trainerA.getIcon()
                        );

                        expect(userService.isValidCredentials(trainerA.getEmail(), newPassword)).toBeTrue();
                        expect(userService.isValidCredentials(trainerA.getEmail(), oldPassword)).toBeFalse();
                    });
                });
            });
        });
    }

    /**
     * Store a pre-bcrypt (salted + peppered SHA) hash on the trainer, returns the hash
     */
    private string function setLegacyPassword(required component trainer, required string password) {
        var env        = new coldbox.system.core.delegates.Env();
        var salt       = createUUID();
        var legacyHash = hash(
            arguments.password & salt & env.getEnv("PEPPER"),
            env.getEnv("ALGORITHM"),
            "UTF-8",
            env.getEnv("ITERATIONS")
        );

        entityReload(arguments.trainer);
        arguments.trainer.setPassword(legacyHash);
        arguments.trainer.setSalt(salt);
        entitySave(arguments.trainer);
        ormFlush();

        return legacyHash;
    }

    /**
     * Store a bcrypt hash on the trainer, returns the hash
     */
    private string function setBcryptPassword(required component trainer, required string password) {
        var bcryptHash = getInstance("@BCrypt").hashPassword(password = arguments.password);

        entityReload(arguments.trainer);
        arguments.trainer.setPassword(bcryptHash);
        arguments.trainer.setSalt("");
        entitySave(arguments.trainer);
        ormFlush();

        return bcryptHash;
    }

}
