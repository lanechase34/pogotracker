component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        auth           = getInstance("authenticationService@cbauth");
        trainerService = getInstance("services.trainer");
        defaults       = application.cbController.getSetting("defaultSettings");

        // Other trainer used for uniqueness conflicts
        otherTrainer   = mockTrainer.make(securityLevel = 10, autoLogin = false);
        otherTrainerId = otherTrainer.getId();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete(otherTrainerId);
    }

    /**
     * Post the profile form as the logged in trainer
     */
    private any function postProfile(required component trainer, struct overrides = {}) {
        setup();
        var params = {
            trainerid    : arguments.trainer.getId(),
            username     : arguments.trainer.getUsername(),
            email        : arguments.trainer.getEmail(),
            icon         : arguments.trainer.getIcon(),
            password     : "",
            defaultView  : "normal",
            defaultRegion: "Kanto",
            defaultPage  : "/"
        };
        params.append(arguments.overrides);

        return post(route = "/trainer/updateProfile", params = params);
    }

    /**
     * Settings as currently saved - a fresh load, not a possibly memoized instance from earlier in the test
     */
    private struct function savedSettings(required component trainer) {
        trainerService.clearCache(arguments.trainer.getId());
        return trainerService.getFromId(arguments.trainer.getId()).getSettings();
    }

    /**
     * Parse the rendered edit profile modal and return the selected setting values
     */
    private struct function getSelectedSettings(required any event) {
        var doc = getInstance("javaloader:org.jsoup.Jsoup").parse(arguments.event.getRenderedContent());
        return {
            defaultView  : doc.select("##inputDefaultView option[selected]").attr("value"),
            defaultRegion: doc.select("##inputDefaultRegion option[selected]").attr("value"),
            defaultPage  : doc.select("##inputDefaultPage option[selected]").attr("value")
        };
    }

    function run() {
        describe("Update profile", () => {
            beforeEach(() => {
                extraTrainerIds = [];
            });

            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
                extraTrainerIds.each((id) => mockTrainer.delete(id));
            });

            it("Lets a regular user save their profile without changing username/email", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer);
                var res   = event.getPrivateValue("responseObj");

                expect(res.success).toBeTrue(res.message);
            });

            it("Lets a regular user change their username", () => {
                var trainer     = mockTrainer.make(securityLevel = 10, autoLogin = true);
                var newUsername = "UPD_#left(createUUID().replace("-", "", "all"), 10)#";

                var event = postProfile(trainer, {username: newUsername});
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                entityReload(trainer);
                expect(trainer.getUsername()).toBe(newUsername);
            });

            it("Lets a regular user switch to another base icon", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                var newIcon = trainer.getIcon() == "bulbasaur" ? "squirtle" : "bulbasaur";

                var event = postProfile(trainer, {icon: newIcon});
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                entityReload(trainer);
                expect(trainer.getIcon()).toBe(newIcon);
            });

            it("Rejects an icon the trainer has not unlocked", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                var before  = trainer.getIcon();

                // A new trainer has no caught pokemon, so mewtwo is still locked - its file exists, so only the unlock check stops it
                var event = postProfile(trainer, {icon: "mewtwo"});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();

                entityReload(trainer);
                expect(trainer.getIcon()).toBe(before);
            });

            it("Offers and saves an unlocked icon whose name has a space", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                getInstance("services.pokedex").registerAll(
                    trainer = trainer,
                    region  = "Kanto",
                    shiny   = true
                );
                trainerService.clearCache(trainer.getId());

                // The option shows "Shiny Mew" but its value matches the file name
                setup();
                var doc = getInstance("javaloader:org.jsoup.Jsoup").parse(
                    get(route = "/trainer/editProfile", renderResults = true).getRenderedContent()
                );
                var option = doc.select("##iconList option[value=shinymew]");
                expect(option.size()).toBe(1);
                expect(option.text()).toBe("Shiny Mew");

                var event = postProfile(trainer, {icon: "shinymew"});
                expect(event.getPrivateValue("responseObj").success).toBeTrue(
                    event.getPrivateValue("responseObj").message
                );

                entityReload(trainer);
                expect(trainer.getIcon()).toBe("shinymew");
            });

            it("Keeps the trainer signed in after changing their own password", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(
                    trainer,
                    {password: "NewPass_#createUUID()#", currentPassword: mockTrainer.getMockPassword()}
                );
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                // The password change bumped the session version - this session kept up with it
                mockTrainer.refresh(trainer.getId());
                setup();
                execute(route = "/mypokedex");
                expect(auth.isLoggedIn()).toBeTrue();
            });

            describe("Current password", () => {
                it("Rejects changing your own password without your current password", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    var before  = trainer.getPassword();

                    var event = postProfile(trainer, {password: "NewPass_#createUUID()#"});
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();
                    expect(event.getPrivateValue("responseObj").message).toBe("Current password is incorrect.");

                    entityReload(trainer);
                    expect(trainer.getPassword()).toBe(before);
                });

                it("Rejects changing your own password with the wrong current password", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    var before  = trainer.getPassword();

                    var event = postProfile(
                        trainer,
                        {password: "NewPass_#createUUID()#", currentPassword: "NotMyPassword_1"}
                    );
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();

                    entityReload(trainer);
                    expect(trainer.getPassword()).toBe(before);
                });

                it("Rejects changing your own email without your current password", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    var email   = trainer.getEmail();

                    var event = postProfile(trainer, {email: "changed_#createUUID()#@example.com"});
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();

                    entityReload(trainer);
                    expect(trainer.getEmail()).toBe(email);
                });

                it("Lets you change your own email with your current password", () => {
                    var trainer  = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    var newEmail = lCase("changed_#left(createUUID().replace("-", "", "all"), 10)#@example.com");

                    var event = postProfile(trainer, {email: newEmail, currentPassword: mockTrainer.getMockPassword()});
                    expect(event.getPrivateValue("responseObj").success).toBeTrue(
                        event.getPrivateValue("responseObj").message
                    );

                    entityReload(trainer);
                    expect(trainer.getEmail()).toBe(newEmail);
                });

                it("Doesn't ask for it when nothing sensitive changes", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                    var event = postProfile(trainer);
                    expect(event.getPrivateValue("responseObj").success).toBeTrue();
                });
            });

            it("Rejects a regular user taking another trainer's username", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer, {username: otherTrainer.getUsername()});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();
            });

            it("Rejects a regular user setting their own security level", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                // cbSecure().secureWhen -> NotAuthorized (error.onException turns it into a 403)
                expect(() => postProfile(trainer, {securityLevel: "60", verified: "on"})).toThrow("NotAuthorized");

                entityReload(trainer);
                expect(trainer.getSecurityLevel()).toBe(10);
            });

            // Each admin only field on its own - the test above sends two, so it would still pass if either check were removed
            describe("Admin only fields (secureWhen)", () => {
                it("Rejects a regular user setting only their security level", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                    expect(() => postProfile(trainer, {securityLevel: "60"})).toThrow("NotAuthorized");

                    entityReload(trainer);
                    expect(trainer.getSecurityLevel()).toBe(10);
                });

                it("Rejects a regular user setting only their verified flag", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                    expect(() => postProfile(trainer, {verified: "off"})).toThrow("NotAuthorized");

                    entityReload(trainer);
                    expect(trainer.getVerified()).toBeTrue();
                });

                it("Rejects a regular user setting only their friendcode", () => {
                    var trainer    = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    var friendcode = trainer.getFriendcode();

                    expect(() => postProfile(trainer, {friendcode: mockTrainer.makeFriendcode()})).toThrow("NotAuthorized");

                    entityReload(trainer);
                    expect(trainer.getFriendcode()).toBe(friendcode);
                });

                it("Rejects a regular user changing another trainer's account details", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    var username = target.getUsername();
                    var email    = target.getEmail();
                    mockTrainer.make(securityLevel = 10, autoLogin = true);

                    expect(() => postProfile(
                        target,
                        {
                            username: "HIJACK_#left(createUUID().replace("-", "", "all"), 10)#",
                            email   : "hijack_#createUUID()#@example.com",
                            password: "Hijacked123!"
                        }
                    )).toThrow("NotAuthorized");

                    entityReload(target);
                    expect(target.getUsername()).toBe(username);
                    expect(target.getEmail()).toBe(email);
                });

                it("Lets an admin set another trainer's security level, verified flag, and friendcode", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    var friendcode = mockTrainer.makeFriendcode();
                    mockTrainer.make(securityLevel = 50, autoLogin = true);

                    var event = postProfile(
                        target,
                        {
                            securityLevel: "50",
                            verified     : "off",
                            friendcode   : friendcode
                        }
                    );
                    expect(event.getPrivateValue("responseObj").success).toBeTrue(
                        event.getPrivateValue("responseObj").message
                    );

                    entityReload(target);
                    expect(target.getSecurityLevel()).toBe(50);
                    expect(target.getVerified()).toBeFalse();
                    expect(target.getFriendcode()).toBe(friendcode);
                });
            });

            it("Rejects an admin setting a friendcode that belongs to another trainer", () => {
                var trainer = mockTrainer.make(securityLevel = 50, autoLogin = true);

                var event = postProfile(trainer, {friendcode: otherTrainer.getFriendcode()});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();
            });

            describe("Settings", () => {
                it("Lets a regular user save their own settings", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                    var event = postProfile(
                        trainer,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );
                    expect(event.getPrivateValue("responseObj").success).toBeTrue();

                    var settings = savedSettings(trainer);
                    expect(settings.defaultView).toBe("shiny");
                    expect(settings.defaultRegion).toBe("Unova");
                    expect(settings.defaultPage).toBe("/mypokedex");

                    // The logged in trainer has the new settings on the next request
                    mockTrainer.refresh(trainer.getId());
                    expect(auth.getUser().getSettings().defaultRegion).toBe("Unova");
                });

                it("Lets an admin save another trainer's settings without changing their own", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    var admin = mockTrainer.make(securityLevel = 50, autoLogin = true);

                    var event = postProfile(
                        target,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );
                    expect(event.getPrivateValue("responseObj").success).toBeTrue();

                    var settings = savedSettings(target);
                    expect(settings.defaultView).toBe("shiny");
                    expect(settings.defaultRegion).toBe("Unova");
                    expect(settings.defaultPage).toBe("/mypokedex");

                    // Admin's own settings and login are untouched
                    expect(auth.getUserId()).toBe(admin.getId());
                    expect(savedSettings(admin).defaultRegion).toBe("Kanto");
                });

                it("Rejects a regular user saving another trainer's settings", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    mockTrainer.make(securityLevel = 10, autoLogin = true);

                    expect(() => postProfile(target, {defaultRegion: "Unova"})).toThrow("NotAuthorized");
                    expect(savedSettings(target)).toBeEmpty();
                });
            });

            describe("Edit profile form", () => {
                it("Defaults to the logged in trainer's settings", () => {
                    var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
                    postProfile(
                        trainer,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );

                    mockTrainer.refresh(trainer.getId());
                    setup();
                    var selected = getSelectedSettings(get(route = "/trainer/editProfile", renderResults = true));
                    expect(selected.defaultView).toBe("shiny");
                    expect(selected.defaultRegion).toBe("Unova");
                    expect(selected.defaultPage).toBe("/mypokedex");
                });

                it("Admin edit trainer defaults to the edited trainer's settings, not the admin's", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    target.setSettings({
                        defaultView  : "shiny",
                        defaultRegion: "Unova",
                        defaultPage  : "/mypokedex"
                    });
                    mockTrainer.make(securityLevel = 50, autoLogin = true);

                    // Admin has the default settings
                    expect(auth.getUser().getSettings().defaultRegion).toBe("Kanto");

                    setup();
                    var selected = getSelectedSettings(
                        get(route = "/admin/editTrainer/trainerid/#target.getId()#", renderResults = true)
                    );
                    expect(selected.defaultView).toBe("shiny");
                    expect(selected.defaultRegion).toBe("Unova");
                    expect(selected.defaultPage).toBe("/mypokedex");
                });

                it("Admin edit trainer falls back to default settings when the trainer has none", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    var admin = mockTrainer.make(securityLevel = 50, autoLogin = true);

                    // Give the admin non-default settings so a fallback to the admin's session would be caught
                    postProfile(
                        admin,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );
                    expect(savedSettings(target)).toBeEmpty();

                    setup();
                    var selected = getSelectedSettings(
                        get(route = "/admin/editTrainer/trainerid/#target.getId()#", renderResults = true)
                    );
                    expect(selected.defaultRegion).toBe(defaults.defaultRegion);
                    expect(selected.defaultPage).toBe(defaults.defaultPage);
                    expect(selected.defaultView).toBe(defaults.defaultView);
                });
            });
        });

        describe("View profile", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Sends a trainer who is not a friend back to their own profile", () => {
                mockTrainer.make(securityLevel = 10, autoLogin = true);

                setup();
                var event = get(route = "/profile/#otherTrainerId#");
                expect(event.getValue("relocate_URI", "")).toBe("/profile");
            });
        });
    }

}
