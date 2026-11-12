component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");
        requestStub = getInstance("tests.resources.requestStub");

        personas = {
            unverified: mockTrainer.make(
                securityLevel = 10,
                verified      = false,
                autoLogin     = false
            ),
            user     : mockTrainer.make(securityLevel = 10, autoLogin = false),
            admin    : mockTrainer.make(securityLevel = 50, autoLogin = false),
            developer: mockTrainer.make(securityLevel = 60, autoLogin = false)
        };
    }

    function afterAll() {
        personas.each((name, trainer) => mockTrainer.delete(trainer.getId()));
        super.afterAll();
    }

    private void function actAs(required string persona) {
        if(arguments.persona == "guest") {
            mockTrainer.actAsGuest();
        }
        else {
            mockTrainer.actAs(personas[arguments.persona]);
        }
    }

    /**
     * What happened to the request: allowed, login, verify, 403 (or something unexpected, spelled out)
     */
    private string function outcome(required any event, required string expectedEvent) {
        var relocated = arguments.event.getValue("relocate_uri", "");
        if(relocated == "/login") return "login";
        if(relocated == "/verify") return "verify";
        if(arguments.event.getCurrentEvent() == "error.unauthorized") return "403";
        if(relocated.len()) return "relocated to #relocated#";
        return arguments.event.getCurrentEvent() == arguments.expectedEvent ? "allowed" : "ran #arguments.event.getCurrentEvent()#";
    }

    function run() {
        describe("Access matrix", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            // route, the event it runs when allowed, persona -> expected outcome
            var matrix = [
                {
                    name    : "public page",
                    route   : "/",
                    event   : "home.home",
                    expected: {
                        guest     : "allowed",
                        unverified: "verify", // unverified trainers can only verify or log out (interceptors/guestonly.cfc)
                        user      : "allowed",
                        admin     : "allowed",
                        developer : "allowed"
                    }
                },
                {
                    name    : "guest-only page",
                    route   : "/login",
                    event   : "login.loginForm",
                    expected: {
                        guest     : "allowed",
                        unverified: "verify",
                        user      : "relocated to /",
                        admin     : "relocated to /",
                        developer : "relocated to /"
                    }
                },
                {
                    name    : "verify page",
                    route   : "/verify",
                    event   : "login.verifyForm",
                    expected: {
                        guest     : "login",
                        unverified: "allowed",
                        user      : "relocated to /",
                        admin     : "relocated to /",
                        developer : "relocated to /"
                    }
                },
                {
                    name    : "user page",
                    route   : "/mypokedex",
                    event   : "pokedex.myPokedex",
                    expected: {
                        guest     : "login",
                        unverified: "verify",
                        user      : "allowed",
                        admin     : "allowed",
                        developer : "allowed"
                    }
                },
                {
                    name    : "admin page",
                    route   : "/admin",
                    event   : "admin.index",
                    expected: {
                        guest     : "login",
                        unverified: "verify",
                        user      : "403",
                        admin     : "allowed",
                        developer : "allowed"
                    }
                },
                {
                    name    : "admin action in a public handler",
                    route   : "/blog/writeForm",
                    event   : "blog.writeForm",
                    expected: {
                        guest     : "login",
                        unverified: "verify",
                        user      : "403",
                        admin     : "allowed",
                        developer : "allowed"
                    }
                },
                {
                    name    : "developer page",
                    route   : "/dev",
                    event   : "dev.index",
                    expected: {
                        guest     : "login",
                        unverified: "verify",
                        user      : "403",
                        admin     : "403",
                        developer : "allowed"
                    }
                }
            ];

            for(var row in matrix) {
                it(
                    title = "#row.name# (#row.route#)",
                    body  = (data) => {
                        var mismatches = [];
                        data.row.expected.each((persona, want) => {
                            setup();
                            actAs(persona);
                            var got = outcome(execute(route = data.row.route), data.row.event);
                            if(got != want) mismatches.append("#persona#: expected #want#, got #got#");
                        });
                        expect(mismatches).toBeEmpty(mismatches.toList("; "));
                    },
                    data = {row: row}
                );
            }
        });

        describe("Json callers", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Guests get a 401", () => {
                setup();
                actAs("guest");
                var event = requestStub.asJsonRequest(() => execute(route = "/pokedex/getPokedex"));

                expect(event.getPrivateValue("cbox_renderdata").statusCode).toBe(401);
                expect(event.getValue("relocate_uri", "")).toBe("");
            });

            it("Unverified trainers get a 403 instead of the verify redirect", () => {
                setup();
                actAs("unverified");
                var event = requestStub.asJsonRequest(() => execute(route = "/pokedex/getPokedex"));

                expect(event.getPrivateValue("cbox_renderdata").statusCode).toBe(403);
                expect(event.getValue("relocate_uri", "")).toBe("");
            });

            it("Trainers without the permission get a 403", () => {
                setup();
                actAs("user");
                var event = requestStub.asJsonRequest(() => execute(route = "/admin/getCacheData", renderResults = true));

                expect(event.getCurrentEvent()).toBe("error.unauthorized");
                var data = event.getPrivateValue("cbox_renderdata");
                expect(data.statusCode).toBe(403);
                expect(data.data.success).toBeFalse();
            });
        });

        describe("Permission changes", () => {
            afterEach(() => {
                if(session.keyExists("mocktrainerid")) mockTrainer.delete();
            });

            it("Demoting a trainer takes effect on their next request", () => {
                setup();
                var admin = mockTrainer.make(securityLevel = 50);
                expect(outcome(execute(route = "/admin"), "admin.index")).toBe("allowed");

                queryExecute(
                    "update trainer set securitylevel = 10 where id = :id",
                    {id: {value: admin.getId(), cfsqltype: "integer"}}
                );
                mockTrainer.refresh(admin.getId());

                setup();
                expect(outcome(execute(route = "/admin"), "admin.index")).toBe("403");
            });
        });

        describe("Security visualizer", () => {
            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Is not exposed - disabled, or secured to admins if it is ever turned on", () => {
                var visualizer = getController().getModuleSettings("cbsecurity").visualizer;
                if(visualizer.enabled) {
                    expect(visualizer.secured).toBeTrue("An enabled visualizer must be secured");
                    expect(visualizer.securityRule?.permissions ?: "").toBe("admin");
                }

                // Even an admin can't see it while it's disabled
                setup();
                actAs("admin");
                var event = execute(route = "/cbsecurity", renderResults = true);
                if(!visualizer.enabled) {
                    expect(event.getRenderedContent()).toInclude("Page Not Found");
                }
            });
        });
    }

}
