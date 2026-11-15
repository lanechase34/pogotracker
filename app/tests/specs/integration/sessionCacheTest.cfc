component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        auth           = getInstance("authenticationService@cbauth");
        trainerService = getInstance("services.trainer");
        requestStorage = getInstance("RequestStorage@cbstorages");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
    }

    /**
     * Start a new request without touching the trainer cache
     */
    private void function nextRequest() {
        requestStorage.delete("cbauth__user");
        setup();
    }

    function run() {
        describe("Trainer cache", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
            });

            it("Tracking a stat updates the trainer's level on their next request", () => {
                var trainer = mockTrainer.makeSignedIn();
                expect(trainerService.getCurrentLevel(auth.getUser().getId()).totalxp).toBe(""); // cached: no stats yet

                setup();
                post(
                    route  = "/stats/track",
                    params = {
                        trainerid: trainer.id,
                        xp       : 123456,
                        caught   : 1,
                        spun     : 1,
                        walked   : 1
                    }
                );

                nextRequest();
                expect(trainerService.getCurrentLevel(auth.getUser().getId()).totalxp).toBe(numberFormat(123456, ","));
            });

            it("An admin's edit of another trainer is seen by that trainer's next request", () => {
                var target = mockTrainer.make(autoLogin = false);
                trainerService.getFromId(target.id); // warm the cache
                var admin = mockTrainer.makeSignedIn(securityLevel = 50);
                var name  = "EDIT_#left(createUUID().replace("-", "", "all"), 10)#";

                setup();
                post(
                    route  = "/trainer/updateProfile",
                    params = {
                        trainerid    : target.id,
                        username     : name,
                        email        : target.email,
                        icon         : target.icon,
                        password     : "",
                        defaultView  : "normal",
                        defaultRegion: "Kanto",
                        defaultPage  : "/"
                    }
                );

                nextRequest();
                expect(trainerService.getFromId(target.id).username).toBe(name);

                mockTrainer.deleteTrainer(admin.id);
                mockTrainer.deleteTrainer(target.id);
            });

            it("A trainer deleted mid session is treated as a guest", () => {
                var trainer   = mockTrainer.makeSignedIn();
                var trainerid = trainer.id;

                queryExecute("DELETE FROM trainer WHERE id = :id", {id: {value: trainerid, cfsqltype: "integer"}});
                mockTrainer.refresh(trainerid);

                setup();
                var event = execute(route = "/", renderResults = true);

                expect(event.getResponse().getStatusCode()).toBe(200);
                expect(event.getPrivateValue("oCurrentUser", "")).toBe("");
                expect(auth.isLoggedIn()).toBeFalse();

                // and a secured page sends them to log in
                setup();
                expect(execute(route = "/mypokedex").getValue("relocate_uri")).toBe("/login");
            });
        });

        describe("After login redirect", () => {
            afterEach(() => {
                session.delete("linkedEvent");
                if(session.keyExists("mocktrainerid")) mockTrainer.deleteTrainer();
            });

            it("Never redirects to another host", () => {
                var trainer = mockTrainer.make(autoLogin = false);

                for(var target in ["//evil.com/x", "/\evil.com/x", "\\evil.com/x"]) {
                    mockTrainer.actAsGuest();
                    session.linkedEvent = target;
                    mockTrainer.login(trainer = trainer, relocate_uri = "/evil.com/x");
                }
            });

            it("Falls back to the trainer's default page", () => {
                var trainer = mockTrainer.make(autoLogin = false);
                getInstance("services.trainer").updateSettings(trainer.id, {defaultPage: "/mypokedex"});
                mockTrainer.refresh(trainer.id);

                mockTrainer.login(trainer = trainer, relocate_uri = "/mypokedex");
            });
        });
    }

}
