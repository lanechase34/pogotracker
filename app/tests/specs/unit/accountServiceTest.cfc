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
        describe("Account service", () => {
            beforeEach(() => {
                accountService = getInstance("services.account");
                trainerService = getInstance("services.trainer");
                mockTrainer.resetSession();
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

                    var trainer = trainerService.findByEmail(email);
                    try {
                        expect(mockTrainer.getSaved(trainer.id).password).toMatch("^\$2[aby]\$");
                        expect(mockTrainer.getSaved(trainer.id).password).notToInclude(password);
                        expect(mockTrainer.getSaved(trainer.id).salt ?: "").toBe("");
                        expect(
                            getInstance("@BCrypt").checkPassword(password, mockTrainer.getSaved(trainer.id).password)
                        ).toBeTrue();
                    }
                    finally {
                        mockTrainer.deleteTrainer(trainer.id);
                    }
                });
            });

            describe("checkPassword", () => {
                it("Accepts the trainer's real password", () => {
                    var password = "Check_#createUUID()#";
                    mockTrainer.setBcryptPassword(trainerA, password);
                    expect(accountService.checkPassword(trainerA.id, password)).toBeTrue();
                });

                it("Rejects a wrong or blank password even with impersonation on", () => {
                    mockTrainer.setBcryptPassword(trainerA, "Check_#createUUID()#");
                    var saved = getInstance("services.trainer").getFromId(trainerA.id);
                    expect(accountService.checkPassword(saved.id, "Wrong_#createUUID()#")).toBeFalse();
                    expect(accountService.checkPassword(saved.id, "")).toBeFalse();
                });
            });

            describe("update", () => {
                it("Persists new username and email", () => {
                    var row              = mockTrainer.getSaved(trainerA.id);
                    var originalUsername = row.username;
                    var originalEmail    = row.email;

                    var newUsername = "UPD_#left(createUUID().replace("-", "", "all"), 10)#";
                    var newEmail    = "#newUsername#@test.com";

                    accountService.updateTrainer(
                        trainerid = trainerA.id,
                        username  = newUsername,
                        password  = "",
                        email     = newEmail,
                        icon      = trainerA.icon
                    );

                    row = mockTrainer.getSaved(trainerA.id);
                    expect(row.username).toBe(newUsername);
                    expect(row.email).toBe(lCase(newEmail));

                    // Restore
                    accountService.updateTrainer(
                        trainerid = trainerA.id,
                        username  = originalUsername,
                        password  = "",
                        email     = originalEmail,
                        icon      = trainerA.icon
                    );
                });

                it("Unverifies a trainer who changes their own email and sends a code to the new one", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    try {
                        var newEmail = "REV_#left(createUUID().replace("-", "", "all"), 10)#@test.com";
                        var reverify = accountService.updateTrainer(
                            trainerid     = trainer.id,
                            username      = trainer.username,
                            password      = "",
                            email         = newEmail,
                            icon          = trainer.icon,
                            reverifyEmail = true
                        );

                        var row = mockTrainer.getSaved(trainer.id);
                        expect(reverify).toBeTrue();
                        expect(row.verified).toBeFalse();
                        expect(row.securitylevel).toBe(10);
                        expect(row.verificationcode ?: "").notToBe("");
                        expect(session.keyExists("verificationCode")).toBeTrue();
                    }
                    finally {
                        mockTrainer.deleteTrainer(trainer.id);
                    }
                });

                it("Keeps a trainer verified when their email doesn't change or an admin changes it", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    try {
                        expect(
                            accountService.updateTrainer(
                                trainerid     = trainer.id,
                                username      = trainer.username,
                                password      = "",
                                email         = trainer.email,
                                icon          = trainer.icon,
                                reverifyEmail = true
                            )
                        ).toBeFalse();
                        expect(mockTrainer.getSaved(trainer.id).verified).toBeTrue();

                        // reverifyEmail is only set for your own profile
                        expect(
                            accountService.updateTrainer(
                                trainerid = trainer.id,
                                username  = trainer.username,
                                password  = "",
                                email     = "ADM_#left(createUUID().replace("-", "", "all"), 10)#@test.com",
                                icon      = trainer.icon
                            )
                        ).toBeFalse();
                        expect(mockTrainer.getSaved(trainer.id).verified).toBeTrue();
                    }
                    finally {
                        mockTrainer.deleteTrainer(trainer.id);
                    }
                });

                it("Keeps an admin's level when they verify a changed email", () => {
                    var trainer = mockTrainer.make(securityLevel = 50, autoLogin = false);
                    try {
                        var newEmail = "REV_#left(createUUID().replace("-", "", "all"), 10)#@test.com";
                        accountService.updateTrainer(
                            trainerid     = trainer.id,
                            username      = trainer.username,
                            password      = "",
                            email         = newEmail,
                            icon          = trainer.icon,
                            reverifyEmail = true
                        );
                        expect(mockTrainer.getSaved(trainer.id).verified).toBeFalse();

                        expect(accountService.checkVerificationCode(email = newEmail, code = session.verificationCode)).toBeTrue();

                        var row = mockTrainer.getSaved(trainer.id);
                        expect(row.verified).toBeTrue();
                        expect(row.securitylevel).toBe(50);
                    }
                    finally {
                        mockTrainer.deleteTrainer(trainer.id);
                    }
                });

                it("Hashes and stores new password when one is provided", () => {
                    var row            = mockTrainer.getSaved(trainerA.id);
                    var passwordBefore = row.password;
                    var newPassword    = "NewPass_#createUUID()#";

                    accountService.updateTrainer(
                        trainerid = trainerA.id,
                        username  = trainerA.username,
                        password  = newPassword,
                        email     = trainerA.email,
                        icon      = trainerA.icon
                    );

                    row = mockTrainer.getSaved(trainerA.id);
                    expect(row.password).notToBe(passwordBefore);
                    expect(row.password).toMatch("^\$2[aby]\$");
                    expect(getInstance("@BCrypt").checkPassword(newPassword, row.password)).toBeTrue();
                });

                it("Leaves password unchanged when an empty string is provided", () => {
                    var row            = mockTrainer.getSaved(trainerA.id);
                    var passwordBefore = row.password;

                    accountService.updateTrainer(
                        trainerid = trainerA.id,
                        username  = trainerA.username,
                        password  = "",
                        email     = trainerA.email,
                        icon      = trainerA.icon
                    );

                    row = mockTrainer.getSaved(trainerA.id);
                    expect(row.password).toBe(passwordBefore);
                });

                it("Sets securityLevel and marks trainer unverified when securityLevel is 5", () => {
                    accountService.updateTrainer(
                        trainerid     = trainerA.id,
                        username      = trainerA.username,
                        password      = "",
                        email         = trainerA.email,
                        icon          = trainerA.icon,
                        securityLevel = "5"
                    );

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.securitylevel).toBe(5);
                    expect(row.verified).toBeFalse();

                    // Restore
                    accountService.updateTrainer(
                        trainerid     = trainerA.id,
                        username      = trainerA.username,
                        password      = "",
                        email         = trainerA.email,
                        icon          = trainerA.icon,
                        securityLevel = "10",
                        verified      = "yes"
                    );
                    row = mockTrainer.getSaved(trainerA.id);
                    expect(row.securitylevel).toBe(10);
                });

                it("Verifies a trainer moved off the unverified level", () => {
                    setLevel(trainerA, 5, false);

                    accountService.updateTrainer(
                        trainerid     = trainerA.id,
                        username      = trainerA.username,
                        password      = "",
                        email         = trainerA.email,
                        icon          = trainerA.icon,
                        securityLevel = "20"
                    );

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.securitylevel).toBe(20);
                    expect(row.verified).toBeTrue();
                    setLevel(trainerA, 10, true);
                });

                it("Moves a trainer verified at the unverified level up to the verified level", () => {
                    setLevel(trainerA, 5, false);

                    // The admin form always sends the level, so checking verified arrives with the unchanged level 5
                    accountService.updateTrainer(
                        trainerid     = trainerA.id,
                        username      = trainerA.username,
                        password      = "",
                        email         = trainerA.email,
                        icon          = trainerA.icon,
                        securityLevel = "5",
                        verified      = "true"
                    );

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.securitylevel).toBe(10);
                    expect(row.verified).toBeTrue();
                });

                it("Persists friendcode when provided", () => {
                    var newFriendcode = mockTrainer.makeFriendcode();

                    accountService.updateTrainer(
                        trainerid  = trainerA.id,
                        username   = trainerA.username,
                        password   = "",
                        email      = trainerA.email,
                        icon       = trainerA.icon,
                        friendcode = newFriendcode
                    );

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.friendcode).toBe(newFriendcode);
                });
            });

            describe("sendVerificationCode", () => {
                it("Sends code when the trainer has no recent verification code", () => {
                    // expired - forces send
                    mockTrainer.updateSaved(
                        trainerA.id,
                        {verificationcode: "", verificationsentdate: dateAdd("d", -30, now())}
                    );

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.email, false);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.verificationcode).notToBe("");
                    expect(session).toHaveKey("verificationCode");
                });

                it("Does not resend within the cooldown window and shows a danger alert", () => {
                    mockTrainer.updateSaved(trainerA.id, {verificationsentdate: now()}); // just sent - within 900s cooldown

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.email, true);

                    expect(globalFunctions.countTestEmails()).toBe(before); // no new email
                    expect(getFlashScope().exists("alert")).toBeTrue();
                    expect(getFlashScope().get("alert").type).toBe("danger");
                });

                it("Resends after the cooldown expires and shows a success alert", () => {
                    mockTrainer.updateSaved(trainerA.id, {verificationsentdate: dateAdd("d", -1, now())}); // 1 day ago - past 900s

                    var before = globalFunctions.countTestEmails();
                    accountService.sendVerificationCode(trainerA.email, true);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    expect(getFlashScope().exists("alert")).toBeTrue();
                    expect(getFlashScope().get("alert").type).toBe("success");
                });
            });

            describe("checkVerificationCode", () => {
                it("Returns false when verificationCode is absent from session", () => {
                    structDelete(session, "verificationCode");
                    expect(accountService.checkVerificationCode(trainerA.email, "ANYCODE")).toBeFalse();
                });

                it("Returns false when the session code does not match the submitted code", () => {
                    session.verificationCode = "CORRECTCODE";
                    expect(accountService.checkVerificationCode(trainerA.email, "WRONGCODE")).toBeFalse();
                });

                it("Returns false when the verification code has expired", () => {
                    // way past 15 min lifespan
                    mockTrainer.updateSaved(trainerA.id, {verificationsentdate: dateAdd("d", -7, now())});

                    session.verificationCode = "EXPIREDCODE";
                    expect(accountService.checkVerificationCode(trainerA.email, "EXPIREDCODE")).toBeFalse();
                });

                it("Returns false when the stored hash does not match", () => {
                    // not expired
                    mockTrainer.updateSaved(
                        trainerA.id,
                        {verificationsentdate: now(), verificationcode: "NOTAVALIDHASH"}
                    );

                    session.verificationCode = "TESTCODE";
                    expect(accountService.checkVerificationCode(trainerA.email, "TESTCODE")).toBeFalse();
                });

                it("Returns true, verifies trainer, and removes session code when everything is valid", () => {
                    mockTrainer.updateSaved(trainerA.id, {verificationsentdate: createDate(1970, 1, 1)});

                    // Use the service to generate a real code so the hash is correct
                    accountService.sendVerificationCode(trainerA.email, false);
                    var code = session.verificationCode;

                    var result = accountService.checkVerificationCode(trainerA.email, code);
                    expect(result).toBeTrue();
                    expect(session).notToHaveKey("verificationCode");

                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.verified).toBeTrue();
                    expect(row.securitylevel).toBe(10);
                });

                it("Accepts the code typed in lowercase", () => {
                    // Codes are emailed uppercase - store a known one so the lowercase input really differs
                    var code = "ABCD1234";
                    var env  = new coldbox.system.core.delegates.Env();
                    mockTrainer.updateSaved(
                        trainerA.id,
                        {
                            verificationsentdate: now(),
                            verificationcode    : hash(
                                code & session.sessionid & env.getEnv("PEPPER"),
                                env.getEnv("ALGORITHM"),
                                "UTF-8",
                                env.getEnv("ITERATIONS")
                            )
                        }
                    );
                    session.verificationCode = code;

                    expect(accountService.checkVerificationCode(trainerA.email, lCase(code))).toBeTrue();
                });
            });

            describe("sendResetCode", () => {
                it("Sends a reset link when no recent code exists", () => {
                    // expired - forces send
                    mockTrainer.updateSaved(trainerA.id, {resetcode: "", resetsentdate: dateAdd("d", -30, now())});

                    var before = globalFunctions.countTestEmails();
                    accountService.sendResetCode(trainerA.email);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    var row = mockTrainer.getSaved(trainerA.id);
                    expect(row.resetcode).notToBe("");
                });

                it("Does not resend within the cooldown window", () => {
                    mockTrainer.updateSaved(trainerA.id, {resetsentdate: now()}); // just sent - within 900s cooldown

                    var before = globalFunctions.countTestEmails();
                    accountService.sendResetCode(trainerA.email);
                    expect(globalFunctions.countTestEmails()).toBe(before);
                });
            });
        });
    }

    /**
     * Put the trainer at a security level and verified state directly
     */
    private void function setLevel(
        required struct trainer,
        required numeric securityLevel,
        required boolean verified
    ) {
        mockTrainer.updateSaved(
            arguments.trainer.id,
            {securitylevel: arguments.securityLevel, verified: arguments.verified}
        );
    }

}
