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
        describe("Security service tests", () => {
            beforeEach(() => {
                setup();
                securityService = getInstance("services.security");
                sessionService  = getInstance("services.session");
                sessionService.destroy(false);
                execute("main.onSessionStart");
                // Ensure recaptcha key is present so checkRecaptcha never throws
                session.recaptcha = {
                    token    : "",
                    valid    : false,
                    timestamp: now(),
                    action   : ""
                };
                session.sessionid = createUUID();
                setup();
            });

            it("Can be created", () => {
                expect(securityService).toBeComponent();

                var levels = securityService.getSecurityLevels();
                expect(levels).toBeStruct();
                expect(levels).toHaveKey("0");
                expect(levels).toHaveKey("10");
                expect(levels).toHaveKey("50");

                expect(securityService.getSecurityMap()).toBeStruct();
            });

            describe("checkUserSecurity", () => {
                it("Returns false when handler is not in the security map", () => {
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 99,
                            handler       = "unknown",
                            action        = "index"
                        )
                    ).toBeFalse();
                });

                it("Enforces wildcard handler rule - admin requires level 50", () => {
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 50,
                            handler       = "admin",
                            action        = "index"
                        )
                    ).toBeTrue();
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 49,
                            handler       = "admin",
                            action        = "index"
                        )
                    ).toBeFalse();
                });

                it("Returns false when action is not in handler", () => {
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 50,
                            handler       = "blog",
                            action        = "notAnAction"
                        )
                    ).toBeFalse();
                });

                it("Enforces action-level rule - blog.addComment requires level 10", () => {
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 10,
                            handler       = "blog",
                            action        = "addComment"
                        )
                    ).toBeTrue();
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 5,
                            handler       = "blog",
                            action        = "addComment"
                        )
                    ).toBeFalse();
                });

                it("Allows level 0 access to public actions", () => {
                    expect(
                        securityService.checkUserSecurity(
                            securityLevel = 0,
                            handler       = "blog",
                            action        = "get"
                        )
                    ).toBeTrue();
                });
            });

            describe("getTrainer", () => {
                it("Returns a single-element array when the email exists", () => {
                    entityReload(trainerA);
                    var result = securityService.getTrainer(trainerA.getEmail());
                    expect(result).toBeArray();
                    expect(result.len()).toBe(1);
                    expect(result[1].getId()).toBe(trainerA.getId());
                });

                it("Returns an empty array when the email does not exist", () => {
                    var result = securityService.getTrainer("nobody_xyzabc123@example.com");
                    expect(result).toBeArray();
                    expect(result.len()).toBe(0);
                });
            });

            describe("login", () => {
                it("Returns true for a valid email (impersonation enabled in test env)", () => {
                    entityReload(trainerA);
                    expect(securityService.login(trainerA.getEmail(), createUUID())).toBeTrue();
                });

                it("Returns false when the email is not registered", () => {
                    expect(securityService.login("nobody_xyzabc123@example.com", "anypassword")).toBeFalse();
                });

                it("Upgrades a legacy hash to bcrypt when the correct password is supplied", () => {
                    var password = "Legacy_#createUUID()#";
                    setLegacyPassword(trainerA, password);

                    expect(securityService.login(trainerA.getEmail(), password)).toBeTrue();

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).toMatch("^\$2[aby]\$");
                    expect(trainerA.getSalt() ?: "").toBe("");
                    expect(getInstance("@BCrypt").checkPassword(password, trainerA.getPassword())).toBeTrue();
                });

                it("Leaves a legacy hash alone when the wrong password is supplied", () => {
                    var password   = "Legacy_#createUUID()#";
                    var legacyHash = setLegacyPassword(trainerA, password);

                    securityService.login(trainerA.getEmail(), "WrongPass_#createUUID()#");

                    entityReload(trainerA);
                    expect(trainerA.getPassword()).toBe(legacyHash);
                });

                describe("with impersonation disabled", () => {
                    beforeEach(() => {
                        // Real password checks - impersonation (on in the test env) skips them
                        storedImpersonation = securityService.getImpersonation();
                        securityService.setImpersonation(false);
                    });

                    afterEach(() => {
                        securityService.setImpersonation(storedImpersonation);
                    });

                    it("Returns true for the correct password against a bcrypt hash", () => {
                        var password = "Bcrypt_#createUUID()#";
                        setBcryptPassword(trainerA, password);

                        expect(securityService.login(trainerA.getEmail(), password)).toBeTrue();
                    });

                    it("Returns false for the wrong password against a bcrypt hash", () => {
                        var password   = "Bcrypt_#createUUID()#";
                        var bcryptHash = setBcryptPassword(trainerA, password);

                        expect(securityService.login(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                        expect(securityService.login(trainerA.getEmail(), "")).toBeFalse();
                        expect(securityService.login(trainerA.getEmail(), uCase(password))).toBeFalse();

                        entityReload(trainerA);
                        expect(trainerA.getPassword()).toBe(bcryptHash);
                    });

                    it("Returns true for the correct password against a legacy hash", () => {
                        var password = "Legacy_#createUUID()#";
                        setLegacyPassword(trainerA, password);

                        expect(securityService.login(trainerA.getEmail(), password)).toBeTrue();
                    });

                    it("Returns false for the wrong password against a legacy hash", () => {
                        var password = "Legacy_#createUUID()#";
                        setLegacyPassword(trainerA, password);

                        expect(securityService.login(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with the upgraded bcrypt hash after a legacy login", () => {
                        var password = "Legacy_#createUUID()#";
                        setLegacyPassword(trainerA, password);

                        expect(securityService.login(trainerA.getEmail(), password)).toBeTrue();
                        entityReload(trainerA);
                        expect(trainerA.getPassword()).toMatch("^\$2[aby]\$");

                        expect(securityService.login(trainerA.getEmail(), password)).toBeTrue();
                        expect(securityService.login(trainerA.getEmail(), "WrongPass_#createUUID()#")).toBeFalse();
                    });

                    it("Logs in with a password set through update and rejects the old one", () => {
                        var oldPassword = "OldPass_#createUUID()#";
                        var newPassword = "NewPass_#createUUID()#";
                        setBcryptPassword(trainerA, oldPassword);

                        securityService.update(
                            trainerid = trainerA.getId(),
                            username  = trainerA.getUsername(),
                            password  = newPassword,
                            email     = trainerA.getEmail(),
                            icon      = trainerA.getIcon()
                        );

                        expect(securityService.login(trainerA.getEmail(), newPassword)).toBeTrue();
                        expect(securityService.login(trainerA.getEmail(), oldPassword)).toBeFalse();
                    });
                });
            });

            describe("register", () => {
                it("Stores a bcrypt hash with a blank salt", () => {
                    var username = "REG_#left(createUUID().replace("-", "", "all"), 10)#";
                    var email    = "#username#@test.com";
                    var password = "RegPass_#createUUID()#";

                    securityService.register(
                        username   = username,
                        password   = password,
                        email      = email,
                        friendcode = mockTrainer.makeFriendcode(),
                        icon       = "charmander"
                    );

                    var trainer = securityService.getTrainer(email)[1];
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

                    securityService.update(
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
                    securityService.update(
                        trainerid = trainerA.getId(),
                        username  = originalUsername,
                        password  = "",
                        email     = originalEmail,
                        icon      = trainerA.getIcon()
                    );
                });

                it("Revokes persist cookies when the password changes", () => {
                    entityReload(trainerA);
                    var persistService = getInstance("services.persist");
                    persistService.addCookie(trainerA);
                    expect(entityLoad("persist", {trainer: trainerA}).len()).toBeGTE(1);

                    securityService.update(
                        trainerid = trainerA.getId(),
                        username  = trainerA.getUsername(),
                        password  = "NewPass_#createUUID()#",
                        email     = trainerA.getEmail(),
                        icon      = trainerA.getIcon()
                    );

                    var remaining = queryExecute(
                        "select count(id) as total from persist where trainerid = :id",
                        {id: {value: trainerA.getId(), cfsqltype: "integer"}}
                    );
                    expect(remaining.total).toBe(0);
                    persistService.deleteCookie();
                });

                it("Hashes and stores new password when one is provided", () => {
                    entityReload(trainerA);
                    var passwordBefore = trainerA.getPassword();
                    var newPassword    = "NewPass_#createUUID()#";

                    securityService.update(
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

                    securityService.update(
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

                    securityService.update(
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
                    securityService.update(
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

                it("Persists friendcode when provided", () => {
                    entityReload(trainerA);
                    var newFriendcode = mockTrainer.makeFriendcode();

                    securityService.update(
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
                it("Returns true when a trainer edits their own profile", () => {
                    entityReload(trainerA);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            password      = "",
                            email         = trainerA.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeTrue();
                });

                it("Returns false when a regular user attempts to edit a different trainer", () => {
                    entityReload(trainerA);
                    entityReload(trainerB);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerB.getId(),
                            username      = trainerB.getUsername(),
                            password      = "",
                            email         = trainerB.getEmail(),
                            icon          = trainerB.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false when a regular user supplies an invalid securityLevel", () => {
                    entityReload(trainerA);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            password      = "",
                            email         = trainerA.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "999",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false when a regular user tries to set a valid securityLevel on themselves", () => {
                    entityReload(trainerA);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    for(var level in ["10", "50", "60"]) {
                        expect(
                            securityService.validateUpdateProfile(
                                trainerid     = trainerA.getId(),
                                username      = trainerA.getUsername(),
                                password      = "",
                                email         = trainerA.getEmail(),
                                icon          = trainerA.getIcon(),
                                friendcode    = "",
                                securityLevel = level,
                                verified      = ""
                            )
                        ).toBeFalse();
                    }
                });

                it("Returns false when a regular user tries to set verified on themselves", () => {
                    entityReload(trainerA);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            password      = "",
                            email         = trainerA.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = "on"
                        )
                    ).toBeFalse();
                });

                it("Returns false when a regular user supplies an invalid verified value", () => {
                    entityReload(trainerA);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            password      = "",
                            email         = trainerA.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = "notvalid"
                        )
                    ).toBeFalse();
                });

                it("Returns false when the submitted email belongs to another trainer", () => {
                    entityReload(trainerA);
                    entityReload(trainerB);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerA.getUsername(),
                            password      = "",
                            email         = trainerB.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns false when the submitted username belongs to another trainer", () => {
                    entityReload(trainerA);
                    entityReload(trainerB);
                    session.securityLevel = 10;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerA.getId(),
                            username      = trainerB.getUsername(),
                            password      = "",
                            email         = trainerA.getEmail(),
                            icon          = trainerA.getIcon(),
                            friendcode    = "",
                            securityLevel = "",
                            verified      = ""
                        )
                    ).toBeFalse();
                });

                it("Returns true when an admin edits a different trainer including restricted fields", () => {
                    entityReload(trainerB);
                    session.securityLevel = 50;
                    session.trainerid     = trainerA.getId();

                    expect(
                        securityService.validateUpdateProfile(
                            trainerid     = trainerB.getId(),
                            username      = trainerB.getUsername(),
                            password      = "",
                            email         = trainerB.getEmail(),
                            icon          = trainerB.getIcon(),
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
                    securityService.sendVerificationCode(trainerA.getEmail(), false);

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
                    securityService.sendVerificationCode(trainerA.getEmail(), true);

                    expect(globalFunctions.countTestEmails()).toBe(before); // no new email
                    expect(session).toHaveKey("alert");
                    expect(session.alert.type).toBe("danger");
                });

                it("Resends after the cooldown expires and shows a success alert", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(dateAdd("d", -1, now())); // 1 day ago - past 900s
                    entitySave(trainerA);
                    ormFlush();

                    var before = globalFunctions.countTestEmails();
                    securityService.sendVerificationCode(trainerA.getEmail(), true);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);
                    expect(session).toHaveKey("alert");
                    expect(session.alert.type).toBe("success");
                });
            });

            describe("checkVerificationCode", () => {
                it("Returns false when verificationCode is absent from session", () => {
                    structDelete(session, "verificationCode");
                    expect(securityService.checkVerificationCode(trainerA.getEmail(), "ANYCODE")).toBeFalse();
                });

                it("Returns false when the session code does not match the submitted code", () => {
                    session.verificationCode = "CORRECTCODE";
                    expect(securityService.checkVerificationCode(trainerA.getEmail(), "WRONGCODE")).toBeFalse();
                });

                it("Returns false when the verification code has expired", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(dateAdd("d", -7, now())); // way past 15 min lifespan
                    entitySave(trainerA);
                    ormFlush();

                    session.verificationCode = "EXPIREDCODE";
                    expect(securityService.checkVerificationCode(trainerA.getEmail(), "EXPIREDCODE")).toBeFalse();
                });

                it("Returns false when the stored hash does not match", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(now()); // not expired
                    trainerA.setVerificationCode("NOTAVALIDHASH");
                    entitySave(trainerA);
                    ormFlush();

                    session.verificationCode = "TESTCODE";
                    expect(securityService.checkVerificationCode(trainerA.getEmail(), "TESTCODE")).toBeFalse();
                });

                it("Returns true, verifies trainer, and removes session code when everything is valid", () => {
                    entityReload(trainerA);
                    trainerA.setVerificationSentDate(createDate(1970, 1, 1));
                    entitySave(trainerA);
                    ormFlush();

                    // Use the service to generate a real code so the hash is correct
                    securityService.sendVerificationCode(trainerA.getEmail(), false);
                    var code = session.verificationCode;

                    var result = securityService.checkVerificationCode(trainerA.getEmail(), code);
                    expect(result).toBeTrue();
                    expect(session).notToHaveKey("verificationCode");

                    entityReload(trainerA);
                    expect(trainerA.getVerified()).toBeTrue();
                    expect(trainerA.getSecurityLevel()).toBe(10);
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
                    securityService.sendResetCode(trainerA.getEmail());

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
                    securityService.sendResetCode(trainerA.getEmail());
                    expect(globalFunctions.countTestEmails()).toBe(before);
                });
            });

            describe("verifyRecaptcha", () => {
                it("Returns true and stores valid=true in session when useRecaptcha is disabled", () => {
                    var result = securityService.verifyRecaptcha("test-token");

                    expect(result).toBeTrue();
                    expect(session).toHaveKey("recaptcha");
                    expect(session.recaptcha.valid).toBeTrue();
                    expect(session.recaptcha.token).toBe("test-token");
                });
            });

            describe("checkRecaptcha", () => {
                it("Returns true and blanks session.recaptcha when useRecaptcha is disabled", () => {
                    session.recaptcha = {
                        token    : "sometoken",
                        valid    : false,
                        timestamp: now(),
                        action   : ""
                    };

                    var result = securityService.checkRecaptcha("register");

                    expect(result).toBeTrue();
                    expect(session.recaptcha.token).toBe("");
                    expect(session.recaptcha.valid).toBeFalse();
                });

                it("Returns false when recaptcha is enabled but the session token is invalid", () => {
                    if(!application.cbController.getSetting("useRecaptcha")) return;

                    session.recaptcha = {
                        token    : "",
                        valid    : false,
                        timestamp: now(),
                        action   : ""
                    };
                    expect(securityService.checkRecaptcha("register")).toBeFalse();
                });

                it("Returns false when recaptcha is enabled but the timestamp has expired", () => {
                    if(!application.cbController.getSetting("useRecaptcha")) return;

                    session.recaptcha = {
                        token    : "validtoken",
                        valid    : true,
                        timestamp: dateAdd("s", -60, now()), // 60s ago - past 30s window
                        action   : "register"
                    };
                    expect(securityService.checkRecaptcha("register")).toBeFalse();
                });

                it("Returns false when recaptcha is enabled but the action does not match", () => {
                    if(!application.cbController.getSetting("useRecaptcha")) return;

                    session.recaptcha = {
                        token    : "validtoken",
                        valid    : true,
                        timestamp: now(),
                        action   : "login"
                    };
                    expect(securityService.checkRecaptcha("register")).toBeFalse();
                });
            });

            describe("isCrossSiteRequest", () => {
                beforeEach(() => {
                    requestHeaders = {};
                    mockSecurity   = createMock(className = "models.services.security");
                    mockSecurity.$(
                        method   = "getHeaderValue",
                        callback = (headername) => requestHeaders[headername] ?: ""
                    );
                });

                it("Allows requests without fetch metadata or origin (non-browser clients)", () => {
                    expect(mockSecurity.isCrossSiteRequest()).toBeFalse();
                });

                it("Allows same-origin requests", () => {
                    requestHeaders = {"Sec-Fetch-Site": "same-origin", "Origin": "https://#cgi.http_host#"};
                    expect(mockSecurity.isCrossSiteRequest()).toBeFalse();
                });

                it("Blocks cross-site and same-site fetch metadata", () => {
                    for(var site in ["cross-site", "same-site"]) {
                        requestHeaders = {"Sec-Fetch-Site": site};
                        expect(mockSecurity.isCrossSiteRequest()).toBeTrue(site);
                    }
                });

                it("Blocks a foreign or null origin", () => {
                    requestHeaders = {"Origin": "https://evil.com"};
                    expect(mockSecurity.isCrossSiteRequest()).toBeTrue();

                    requestHeaders = {"Origin": "https://#cgi.http_host#.evil.com"};
                    expect(mockSecurity.isCrossSiteRequest()).toBeTrue();

                    requestHeaders = {"Origin": "null"};
                    expect(mockSecurity.isCrossSiteRequest()).toBeTrue();
                });
            });

            describe("getRequestIP / getUserAgent / getReferer", () => {
                it("getRequestIP returns a non-empty string", () => {
                    var ip = securityService.getRequestIP();
                    expect(ip).toBeString();
                    expect(ip.len()).toBeGTE(1);
                });

                it("getUserAgent returns a string", () => {
                    expect(securityService.getUserAgent()).toBeString();
                });

                it("getReferer returns a string", () => {
                    expect(securityService.getReferer()).toBeString();
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
