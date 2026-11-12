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
        describe("Account service", () => {
            beforeEach(() => {
                setup();
                sessionService = getInstance("services.session");
                accountService = getInstance("services.account");
                userService    = getInstance("services.user");
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

            describe("register", () => {
                it("Stores a bcrypt hash with a blank salt", () => {
                    var username = "REG_#left(createUUID().replace("-", "", "all"), 10)#";
                    var email    = "#username#@test.com";
                    var password = "RegPass_#createUUID()#";

                    accountService.register(
                        username   = username,
                        password   = password,
                        email      = email,
                        friendcode = mockTrainer.makeFriendcode(),
                        icon       = "charmander"
                    );

                    var trainer = userService.findByEmail(email);
                    try {
                        expect(trainer.getPassword()).toMatch("^\$2[aby]\$");
                        expect(trainer.getPassword()).notToInclude(password);
                        expect(trainer.getSalt() ?: "").toBe("");
                        expect(getInstance("@BCrypt").checkPassword(password, trainer.getPassword())).toBeTrue();
                    }
                    finally {
                        mockTrainer.delete(trainer.getId());
                    }
                });
            });

            describe("update", () => {
                it("Persists new username and email", () => {
                    entityReload(trainerA);
                    var originalUsername = trainerA.getUsername();
                    var originalEmail    = trainerA.getEmail();

                    var newUsername = "UPD_#left(createUUID().replace("-", "", "all"), 10)#";
                    var newEmail    = "#newUsername#@test.com";

                    accountService.update(
                        trainerid = trainerA.getId(),
                        username  = newUsername,
                        password  = "",
                        email     = newEmail,
                        icon      = trainerA.getIcon()
                    );

                    entityReload(trainerA);
                    expect(trainerA.getUsername()).toBe(newUsername);
                    expect(trainerA.getEmail()).toBe(lCase(newEmail));

                    // Restore
                    accountService.update(
                        trainerid = trainerA.getId(),
                        username  = originalUsername,
                        password  = "",
                        email     = originalEmail,
                        icon      = trainerA.getIcon()
                    );
                });

                it("Hashes and stores new password when one is provided", () => {
                    entityReload(trainerA);
                    var passwordBefore = trainerA.getPassword();
                    var newPassword    = "NewPass_#createUUID()#";

                    accountService.update(
                        trainerid = trainerA.getId(),
                        username  = trainerA.getUsername(),
                        password  = newPassword,
                        email     = trainerA.getEmail(),
                        icon      = trainerA.getIcon()
                    );

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).notToBe(passwordBefore);
                    expect(trainerA.getPassword()).toMatch("^\$2[aby]\$");
                    expect(getInstance("@BCrypt").checkPassword(newPassword, trainerA.getPassword())).toBeTrue();
                });

                it("Leaves password unchanged when an empty string is provided", () => {
                    entityReload(trainerA);
                    var passwordBefore = trainerA.getPassword();

                    accountService.update(
                        trainerid = trainerA.getId(),
                        username  = trainerA.getUsername(),
                        password  = "",
                        email     = trainerA.getEmail(),
                        icon      = trainerA.getIcon()
                    );

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).toBe(passwordBefore);
                });

                it("Sets securityLevel and marks trainer unverified when securityLevel is 5", () => {
                    entityReload(trainerA);

                    accountService.update(
                        trainerid     = trainerA.getId(),
                        username      = trainerA.getUsername(),
                        password      = "",
                        email         = trainerA.getEmail(),
                        icon          = trainerA.getIcon(),
                        securityLevel = "5"
                    );

                    entityReload(trainerA);
                    expect(trainerA.getSecurityLevel()).toBe(5);
                    expect(trainerA.getVerified()).toBeFalse();

                    // Restore
                    accountService.update(
                        trainerid     = trainerA.getId(),
                        username      = trainerA.getUsername(),
                        password      = "",
                        email         = trainerA.getEmail(),
                        icon          = trainerA.getIcon(),
                        securityLevel = "10",
                        verified      = "yes"
                    );
                    entityReload(trainerA);
                    expect(trainerA.getSecurityLevel()).toBe(10);
                });

                it("Verifies a trainer moved off the unverified level", () => {
                    setLevel(trainerA, 5, false);

                    accountService.update(
                        trainerid     = trainerA.getId(),
                        username      = trainerA.getUsername(),
                        password      = "",
                        email         = trainerA.getEmail(),
                        icon          = trainerA.getIcon(),
                        securityLevel = "20"
                    );

                    entityReload(trainerA);
                    expect(trainerA.getSecurityLevel()).toBe(20);
                    expect(trainerA.getVerified()).toBeTrue();
                    setLevel(trainerA, 10, true);
                });

                it("Moves a trainer verified at the unverified level up to the verified level", () => {
                    setLevel(trainerA, 5, false);

                    // The admin form always sends the level, so checking verified arrives with the unchanged level 5
                    accountService.update(
                        trainerid     = trainerA.getId(),
                        username      = trainerA.getUsername(),
                        password      = "",
                        email         = trainerA.getEmail(),
                        icon          = trainerA.getIcon(),
                        securityLevel = "5",
                        verified      = "true"
                    );

                    entityReload(trainerA);
                    expect(trainerA.getSecurityLevel()).toBe(10);
                    expect(trainerA.getVerified()).toBeTrue();
                });

                it("Persists friendcode when provided", () => {
                    entityReload(trainerA);
                    var newFriendcode = mockTrainer.makeFriendcode();

                    accountService.update(
                        trainerid  = trainerA.getId(),
                        username   = trainerA.getUsername(),
                        password   = "",
                        email      = trainerA.getEmail(),
                        icon       = trainerA.getIcon(),
                        friendcode = newFriendcode
                    );

                    entityReload(trainerA);
                    expect(trainerA.getFriendcode()).toBe(newFriendcode);
                });
            });

            describe("validateUpdateProfile", () => {
                // Who may edit what is cbsecurity's job (trainer.updateProfile) - this only checks the values

                it("Returns true for a trainer's own unchanged profile", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            email         = trainerA.getEmail(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeTrue();
                });

                it("Returns false for an invalid securityLevel", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            email         = trainerA.getEmail(),
                            friendcode    = "",
                            securityLevel = "999",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false for an invalid verified value", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            email         = trainerA.getEmail(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = "notvalid"
                        )
                    ).toBeFalse();
                });

                it("Returns false when the submitted email belongs to another trainer", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            email         = trainerB.getEmail(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false when the submitted username belongs to another trainer", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerB.getUsername(),
                            email         = trainerA.getEmail(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false when the submitted friendcode belongs to another trainer", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            email         = trainerA.getEmail(),
                            friendcode    = trainerB.getFriendcode(),
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns true for valid admin only fields", () => {
                    expect(
                        accountService.validateUpdateProfile(
                            trainerid     = trainerB.getId(),
                            username      = trainerB.getUsername(),
                            email         = trainerB.getEmail(),
                            friendcode    = "123456789012",
                            securityLevel = "10",
                            verified      = "on"
                        )
                    ).toBeTrue();
                });
            });

            describe("sendVerificationCode", () => {
                it("Sends code when the trainer has no recent verification code", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationCode("");
                    trainerA.setVerificationSentDate(dateAdd("d", -30, now())); // expired - forces send
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.getEmail(), false);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    entityReload(trainerA);
                    expect(trainerA.getVerificationCode()).notToBe("");
                    expect(session).toHaveKey("verificationCode");
                });

                it("Does not resend within the cooldown window and shows a danger alert", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(now()); // just sent - within 900s cooldown
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.getEmail(), true);

                    expect(globalFunctions.countTestEmails()).toBe(before); // no new email
                    expect(getFlashScope().exists("alert")).toBeTrue();
                    expect(getFlashScope().get("alert").type).toBe("danger");
                });

                it("Resends after the cooldown expires and shows a success alert", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(dateAdd("d", -1, now())); // 1 day ago - past 900s
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.getEmail(), true);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    expect(getFlashScope().exists("alert")).toBeTrue();
                    expect(getFlashScope().get("alert").type).toBe("success");
                });
            });

            describe("checkVerificationCode", () => {
                it("Returns false when verificationCode is absent from session", () => {
                    structDelete(session, "verificationCode");
                    expect(accountService.checkVerificationCode(trainerA.getEmail(), "ANYCODE")).toBeFalse();
                });

                it("Returns false when the session code does not match the submitted code", () => {
                    session.verificationCode = "CORRECTCODE";
                    expect(accountService.checkVerificationCode(trainerA.getEmail(), "WRONGCODE")).toBeFalse();
                });

                it("Returns false when the verification code has expired", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(dateAdd("d", -7, now())); // way past 15 min lifespan
                    entitySave(trainerA);
                    ormFlush();

                    session.verificationCode = "EXPIREDCODE";
                    expect(accountService.checkVerificationCode(trainerA.getEmail(), "EXPIREDCODE")).toBeFalse();
                });

                it("Returns false when the stored hash does not match", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(now()); // not expired
                    trainerA.setVerificationCode("NOTAVALIDHASH");
                    entitySave(trainerA);
                    ormFlush();

                    session.verificationCode = "TESTCODE";
                    expect(accountService.checkVerificationCode(trainerA.getEmail(), "TESTCODE")).toBeFalse();
                });

                it("Returns true, verifies trainer, and removes session code when everything is valid", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(createDate(1970, 1, 1));
                    entitySave(trainerA);
                    ormFlush();

                    // Use the service to generate a real code so the hash is correct
                    accountService.sendVerificationCode(trainerA.getEmail(), false);
                    var code = session.verificationCode;

                    var result = accountService.checkVerificationCode(trainerA.getEmail(), code);
                    expect(result).toBeTrue();
                    expect(session).notToHaveKey("verificationCode");

                    entityReload(trainerA);
                    expect(trainerA.getVerified()).toBeTrue();
                    expect(trainerA.getSecurityLevel()).toBe(10);
                });

                it("Accepts the code typed in lowercase", () => {
                    // Codes are emailed uppercase - store a known one so the lowercase input really differs
                    var code = "ABCD1234";
                    var env  = new coldbox.system.core.delegates.Env();
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(now());
                    trainerA.setVerificationCode(
                        hash(
                            code & session.sessionid & env.getEnv("PEPPER"),
                            env.getEnv("ALGORITHM"),
                            "UTF-8",
                            env.getEnv("ITERATIONS")
                        )
                    );
                    entitySave(trainerA);
                    ormFlush();
                    session.verificationCode = code;

                    expect(accountService.checkVerificationCode(trainerA.getEmail(), lCase(code))).toBeTrue();
                });
            });

            describe("sendResetCode", () => {
                it("Sends a reset link when no recent code exists", () => {
                    entityReload(trainerA);
                    trainerA.setResetCode("");
                    trainerA.setResetSentDate(dateAdd("d", -30, now())); // expired - forces send
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    accountService.sendResetCode(trainerA.getEmail());

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    entityReload(trainerA);
                    expect(trainerA.getResetCode()).notToBe("");
                });

                it("Does not resend within the cooldown window", () => {
                    entityReload(trainerA);
                    trainerA.setResetSentDate(now()); // just sent - within 900s cooldown
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    accountService.sendResetCode(trainerA.getEmail());
                    expect(globalFunctions.countTestEmails()).toBe(before);
                });
            });
        });
    }

    /**
     * Put the trainer at a security level and verified state directly
     */
    private void function setLevel(
        required component trainer,
        required numeric securityLevel,
        required boolean verified
    ) {
        entityReload(arguments.trainer);
        arguments.trainer.setSecurityLevel(arguments.securityLevel);
        arguments.trainer.setVerified(arguments.verified);
        entitySave(arguments.trainer);
        ormFlush();
    }

}
