component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mocktrainer");
        auth           = getInstance("authenticationService@cbauth");
        trainerService = getInstance("services.trainer");
        requestStorage = getInstance("RequestStorage@cbstorages");
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists("mocktrainerid")) mockTrainer.delete();
    }

    /**
     * Start a new request without touching the trainer cache
     */
    private void function nextRequest() {
        requestStorage.delete("cbauth__user");
        ormClearSession();
        setup();
    }

    function run() {
        describe("Trainer cache", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Tracking a stat updates the trainer's level on their next request", () => {
                var trainer = mockTrainer.make();
                expect(auth.getUser().getCurrentLevel().totalxp).toBe(""); // memoized: no stats yet

                setup();
                post(
                    route  = "/stats/track",
                    params = {
                        trainerid: trainer.getId(),
                        xp       : 123456,
                        caught   : 1,
                        spun     : 1,
                        walked   : 1
                    }
                );

                nextRequest();
                expect(auth.getUser().getCurrentLevel().totalxp).toBe(numberFormat(123456, ","));
            });

            it("An admin's edit of another trainer is seen by that trainer's next request", () => {
                var target = mockTrainer.make(autoLogin = false);
                var cached = trainerService.getFromId(target.getId()); // warm the cache
                var admin  = mockTrainer.make(securityLevel = 50);
                var name   = "EDIT_#left(createUUID().replace("-", "", "all"), 10)#";

                setup();
                post(
                    route  = "/trainer/updateProfile",
                    params = {
                        trainerid    : target.getId(),
                        username     : name,
                        email        : target.getEmail(),
                        icon         : target.getIcon(),
                        password     : "",
                        defaultView  : "normal",
                        defaultRegion: "Kanto",
                        defaultPage  : "/"
                    }
                );

                nextRequest();
                expect(trainerService.getFromId(target.getId()).getUsername()).toBe(name);

                mockTrainer.delete(admin.getId());
                mockTrainer.delete(target.getId());
            });

            it("A trainer deleted mid session is treated as a guest", () => {
                var trainer   = mockTrainer.make(autoLogin = false);
                var trainerid = trainer.getId();
                mockTrainer.actAs(trainer);

                queryExecute("delete from trainer where id = :id", {id: {value: trainerid, cfsqltype: "integer"}});
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
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Never redirects to another host", () => {
                for(var target in ["//evil.com/x", "/\evil.com/x", "\\evil.com/x"]) {
                    var trainer = mockTrainer.make(autoLogin = false);

                    session.linkedEvent = target;
                    mockTrainer.login(trainer = trainer, relocate_uri = "/evil.com/x");

                    mockTrainer.delete(trainer.getId());
                }
            });

            it("Falls back to the trainer's default page", () => {
                var trainer = mockTrainer.make(autoLogin = false);
                trainer.setSettings({defaultPage: "/mypokedex"});
                mockTrainer.refresh(trainer.getId());

                mockTrainer.login(trainer = trainer, relocate_uri = "/mypokedex");
            });
        });
    }

}
