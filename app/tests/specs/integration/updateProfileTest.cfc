component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        auth           = getInstance("authenticationService@cbauth");
        trainerService = getInstance("services.trainer");
        defaults       = application.cbController.getSetting("defaultSettings");

        // Other trainer used for uniqueness conflicts, and as the untouched target of rejected edits
        otherTrainer = mockTrainer.make(securityLevel = 10, autoLogin = false);

        // Shared by the specs that never change them (rejected edits) - specs that do make their own
        sharedTrainer = mockTrainer.make(securityLevel = 10, autoLogin = false);
        sharedAdmin   = mockTrainer.make(securityLevel = 50, autoLogin = false);

        // Not a spec's own trainer - afterEach must not delete it
        session.delete("mocktrainerid");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(otherTrainer.id);
        mockTrainer.deleteTrainer(sharedTrainer.id);
        mockTrainer.deleteTrainer(sharedAdmin.id);
    }

    /**
     * Post the profile form as the logged in trainer
     */
    private any function postProfile(required struct trainer, struct overrides = {}) {
        setup();
        var params = {
            trainerid    : arguments.trainer.id,
            username     : arguments.trainer.username,
            email        : arguments.trainer.email,
            icon         : arguments.trainer.icon,
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
    private struct function savedSettings(required struct trainer) {
        trainerService.clearCache(arguments.trainer.id);
        return trainerService.getFromId(arguments.trainer.id).settings;
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
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) {
                    mockTrainer.deleteTrainer();
                }
                else {
                    mockTrainer.actAsGuest();
                }
            });

            it("Lets a regular user change their username", () => {
                var trainer     = mockTrainer.makeSignedIn();
                var newUsername = "UPD_#left(createUUID().replace("-", "", "all"), 10)#";

                var event = postProfile(trainer, {username: newUsername});
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                expect(mockTrainer.getSaved(trainer.id).username).toBe(newUsername);
            });

            it("Lets a regular user switch to another base icon", () => {
                var trainer = mockTrainer.makeSignedIn();
                var newIcon = trainer.icon == "bulbasaur" ? "squirtle" : "bulbasaur";

                var event = postProfile(trainer, {icon: newIcon});
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                expect(mockTrainer.getSaved(trainer.id).icon).toBe(newIcon);
            });

            it("Rejects an icon the trainer has not unlocked", () => {
                mockTrainer.actAs(sharedTrainer);

                // A new trainer has no caught pokemon, so mewtwo is still locked - its file exists, so only the unlock check stops it
                var event = postProfile(sharedTrainer, {icon: "mewtwo"});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();

                expect(mockTrainer.getSaved(sharedTrainer.id).icon).toBe(sharedTrainer.icon);
            });

            it("Offers and saves an unlocked icon whose name has a space", () => {
                var trainer = mockTrainer.makeSignedIn();
                getInstance("services.pokedex").registerAll(
                    trainerid = trainer.id,
                    region    = "Kanto",
                    shiny     = true
                );
                trainerService.clearCache(trainer.id);

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

                expect(mockTrainer.getSaved(trainer.id).icon).toBe("shinymew");
            });

            it("Keeps the trainer signed in after changing their own password", () => {
                // A real login - the session version it keeps is what the password change bumps
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(
                    trainer,
                    {password: "NewPass_#createUUID()#", currentPassword: mockTrainer.getMockPassword()}
                );
                expect(event.getPrivateValue("responseObj").success).toBeTrue();

                // The password change bumped the session version - this session kept up with it
                mockTrainer.refresh(trainer.id);
                setup();
                execute(route = "/mypokedex");
                expect(auth.isLoggedIn()).toBeTrue();
            });

            describe("Current password", () => {
                it("Rejects changing your own password without your current password", () => {
                    mockTrainer.actAs(sharedTrainer);
                    var before = mockTrainer.getSaved(sharedTrainer.id).password;

                    var event = postProfile(sharedTrainer, {password: "NewPass_#createUUID()#"});
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();
                    expect(event.getPrivateValue("responseObj").message).toBe("Current password is incorrect.");
                    // A validation failure, not a server error
                    expect(event.getPrivateValue("responseObj").statusCode).toBe(400);

                    expect(mockTrainer.getSaved(sharedTrainer.id).password).toBe(before);
                });

                it("Rejects changing your own password with the wrong current password", () => {
                    mockTrainer.actAs(sharedTrainer);
                    var before = mockTrainer.getSaved(sharedTrainer.id).password;

                    var event = postProfile(
                        sharedTrainer,
                        {password: "NewPass_#createUUID()#", currentPassword: "NotMyPassword_1"}
                    );
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();

                    expect(mockTrainer.getSaved(sharedTrainer.id).password).toBe(before);
                });

                it("Rejects changing your own email without your current password", () => {
                    mockTrainer.actAs(sharedTrainer);

                    var event = postProfile(sharedTrainer, {email: "changed_#createUUID()#@example.com"});
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();

                    expect(mockTrainer.getSaved(sharedTrainer.id).email).toBe(sharedTrainer.email);
                });

                it("Lets you change your own email with your current password", () => {
                    var trainer  = mockTrainer.makeSignedIn();
                    var newEmail = lCase("changed_#left(createUUID().replace("-", "", "all"), 10)#@example.com");

                    var event = postProfile(trainer, {email: newEmail, currentPassword: mockTrainer.getMockPassword()});
                    expect(event.getPrivateValue("responseObj").success).toBeTrue(
                        event.getPrivateValue("responseObj").message
                    );

                    expect(mockTrainer.getSaved(trainer.id).email).toBe(newEmail);
                    // The new email has to be verified before the account can be used again
                    expect(event.getPrivateValue("responseObj").reverify).toBeTrue();
                    expect(mockTrainer.getSaved(trainer.id).verified).toBeFalse();
                });

                it("Doesn't ask for it when nothing sensitive changes", () => {
                    var res = postProfile(mockTrainer.makeSignedIn()).getPrivateValue("responseObj");
                    expect(res.success).toBeTrue(res.message);
                    expect(res.reverify).toBeFalse();
                });
            });

            it("Rejects a regular user taking another trainer's username", () => {
                mockTrainer.actAs(sharedTrainer);

                var event = postProfile(sharedTrainer, {username: otherTrainer.username});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();
                // Caught by validation - the 409 is only for a username taken between validation and the update
                expect(event.getPrivateValue("responseObj").statusCode).toBe(400);
            });

            // Each admin only field on its own, so removing any one check fails a test
            // cbSecure().secureWhen -> NotAuthorized (error.onException turns it into a 403)
            describe("Admin only fields (secureWhen)", () => {
                it("Rejects a regular user setting only their security level", () => {
                    mockTrainer.actAs(sharedTrainer);

                    expect(() => postProfile(sharedTrainer, {securityLevel: "60"})).toThrow("NotAuthorized");

                    expect(mockTrainer.getSaved(sharedTrainer.id).securitylevel).toBe(10);
                });

                it("Rejects a regular user setting only their verified flag", () => {
                    mockTrainer.actAs(sharedTrainer);

                    expect(() => postProfile(sharedTrainer, {verified: "off"})).toThrow("NotAuthorized");

                    expect(mockTrainer.getSaved(sharedTrainer.id).verified).toBeTrue();
                });

                it("Rejects a regular user setting only their friendcode", () => {
                    mockTrainer.actAs(sharedTrainer);

                    expect(() => postProfile(sharedTrainer, {friendcode: mockTrainer.makeFriendcode()})).toThrow("NotAuthorized");

                    expect(mockTrainer.getSaved(sharedTrainer.id).friendcode).toBe(sharedTrainer.friendcode);
                });

                it("Rejects a regular user changing another trainer's account details", () => {
                    mockTrainer.actAs(sharedTrainer);

                    expect(() => postProfile(
                        otherTrainer,
                        {
                            username: "HIJACK_#left(createUUID().replace("-", "", "all"), 10)#",
                            email   : "hijack_#createUUID()#@example.com",
                            password: "Hijacked123!"
                        }
                    )).toThrow("NotAuthorized");

                    var row = mockTrainer.getSaved(otherTrainer.id);
                    expect(row.username).toBe(otherTrainer.username);
                    expect(row.email).toBe(otherTrainer.email);
                });

                it("Lets an admin set another trainer's security level, verified flag, and friendcode", () => {
                    var target     = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    var friendcode = mockTrainer.makeFriendcode();
                    mockTrainer.actAs(sharedAdmin);

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

                    var row = mockTrainer.getSaved(target.id);
                    expect(row.securitylevel).toBe(50);
                    expect(row.verified).toBeFalse();
                    expect(row.friendcode).toBe(friendcode);
                });
            });

            it("Rejects an admin setting a friendcode that belongs to another trainer", () => {
                mockTrainer.actAs(sharedAdmin);

                var event = postProfile(sharedAdmin, {friendcode: otherTrainer.friendcode});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();
            });

            describe("Settings", () => {
                it("Lets a regular user save their own settings", () => {
                    var trainer = mockTrainer.makeSignedIn();

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
                    mockTrainer.refresh(trainer.id);
                    expect(auth.getUser().getSettings().defaultRegion).toBe("Unova");
                });

                it("Lets an admin save another trainer's settings without changing their own", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    mockTrainer.actAs(sharedAdmin);

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
                    expect(auth.getUserId()).toBe(sharedAdmin.id);
                    expect(savedSettings(sharedAdmin).defaultRegion).toBe("Kanto");
                });

                it("Rejects a regular user saving another trainer's settings", () => {
                    mockTrainer.actAs(sharedTrainer);

                    expect(() => postProfile(otherTrainer, {defaultRegion: "Unova"})).toThrow("NotAuthorized");
                    expect(savedSettings(otherTrainer)).toBeEmpty();
                });
            });

            describe("Edit profile form", () => {
                it("Defaults to the logged in trainer's settings", () => {
                    var trainer = mockTrainer.makeSignedIn();
                    postProfile(
                        trainer,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );

                    mockTrainer.refresh(trainer.id);
                    setup();
                    var selected = getSelectedSettings(get(route = "/trainer/editProfile", renderResults = true));
                    expect(selected.defaultView).toBe("shiny");
                    expect(selected.defaultRegion).toBe("Unova");
                    expect(selected.defaultPage).toBe("/mypokedex");
                });

                it("Admin edit trainer defaults to the edited trainer's settings, not the admin's", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    trainerService.updateSettings(
                        target.id,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );
                    mockTrainer.actAs(sharedAdmin);

                    // Admin has the default settings
                    expect(auth.getUser().getSettings().defaultRegion).toBe("Kanto");

                    setup();
                    var selected = getSelectedSettings(
                        get(route = "/admin/editTrainer/trainerid/#target.id#", renderResults = true)
                    );
                    expect(selected.defaultView).toBe("shiny");
                    expect(selected.defaultRegion).toBe("Unova");
                    expect(selected.defaultPage).toBe("/mypokedex");
                });

                it("Admin edit trainer falls back to default settings when the trainer has none", () => {
                    var admin = mockTrainer.makeSignedIn(securityLevel = 50);

                    // Give the admin non-default settings so a fallback to the admin's session would be caught
                    postProfile(
                        admin,
                        {
                            defaultView  : "shiny",
                            defaultRegion: "Unova",
                            defaultPage  : "/mypokedex"
                        }
                    );
                    expect(savedSettings(otherTrainer)).toBeEmpty();

                    setup();
                    var selected = getSelectedSettings(
                        get(route = "/admin/editTrainer/trainerid/#otherTrainer.id#", renderResults = true)
                    );
                    expect(selected.defaultRegion).toBe(defaults.defaultRegion);
                    expect(selected.defaultPage).toBe(defaults.defaultPage);
                    expect(selected.defaultView).toBe(defaults.defaultView);
                });
            });
        });

        describe("View profile", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Sends a trainer who is not a friend back to their own profile", () => {
                mockTrainer.actAs(sharedTrainer);

                setup();
                var event = get(route = "/profile/#otherTrainer.id#");
                expect(event.getValue("relocate_URI", "")).toBe("/profile");
            });
        });
    }

}
