component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");

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

            it("Rejects a regular user taking another trainer's username", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer, {username: otherTrainer.getUsername()});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();
            });

            it("Rejects a regular user setting their own security level", () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer, {securityLevel: "60", verified: "on"});
                expect(event.getPrivateValue("responseObj").success).toBeFalse();

                entityReload(trainer);
                expect(trainer.getSecurityLevel()).toBe(10);
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

                    var settings = trainer.getSettings();
                    expect(settings.defaultView).toBe("shiny");
                    expect(settings.defaultRegion).toBe("Unova");
                    expect(settings.defaultPage).toBe("/mypokedex");

                    // Session is refreshed with the new settings
                    expect(session.settings.defaultRegion).toBe("Unova");
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

                    var settings = target.getSettings();
                    expect(settings.defaultView).toBe("shiny");
                    expect(settings.defaultRegion).toBe("Unova");
                    expect(settings.defaultPage).toBe("/mypokedex");

                    // Admin's own settings and session are untouched
                    expect(session.trainerid).toBe(admin.getId());
                    expect(session.settings.defaultRegion).toBe("Kanto");
                    expect(admin.getSettings().defaultRegion).toBe("Kanto");
                });

                it("Rejects a regular user saving another trainer's settings", () => {
                    var target = mockTrainer.make(securityLevel = 10, autoLogin = false);
                    extraTrainerIds.append(target.getId());
                    mockTrainer.make(securityLevel = 10, autoLogin = true);

                    var event = postProfile(target, {defaultRegion: "Unova"});
                    expect(event.getPrivateValue("responseObj").success).toBeFalse();
                    expect(target.getSettings()).toBeEmpty();
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
                    expect(session.settings.defaultRegion).toBe("Kanto");

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
                    expect(target.getSettings()).toBeEmpty();

                    var defaults = application.cbController.getSetting("defaultSettings");
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
    }

}
