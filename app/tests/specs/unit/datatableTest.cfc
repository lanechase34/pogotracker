component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pagination     = getInstance("services.pagination");
        pokemonService = getInstance("services.pokemon");
        trainerService = getInstance("services.trainer");
        auditService   = getInstance("services.audit");
        bugService     = getInstance("services.bug");

        // Rows only this spec writes - found again by searching the marker
        mockTrainer = getInstance("tests.resources.mocktrainer");
        trainer     = mockTrainer.make(securityLevel = 10, autoLogin = false);
        trainerid   = session.mocktrainerid;
        marker      = "DTTEST#left(createUUID().replace("-", "", "all"), 12)#";

        bugService.logBug(
            ip        = "127.0.0.1",
            event     = "#marker#.event",
            message   = "#marker# message",
            stack     = "stack",
            trainerid = trainerid
        );
        auditService.audit(
            ip        = "127.0.0.1",
            event     = "#marker#.event",
            referer   = "",
            detail    = "#marker# detail",
            agent     = "testbox",
            trainerid = trainerid
        );
        auditService.logRequest(
            ip         = "127.0.0.1",
            urlpath    = "/#marker#/#repeatString("x", 200)#",
            method     = "GET",
            agent      = "testbox",
            referer    = "",
            response   = "{}",
            statuscode = 200,
            trainerid  = trainerid
        );

        // Totals are cached for 5 minutes - count them fresh
        [
            "bug.totalRecords",
            "audit.totalRecords",
            "audit.totalRequestRecords",
            "trainer.totalRecords"
        ].each((key) => {
            getInstance("cachebox:appCache").clear(key);
        });
    }

    function afterAll() {
        mockTrainer.delete(trainerid);
        super.afterAll();
    }

    /**
     * Call a datatable method with the blank search/sort the handler sends by default, overridden by args
     *
     * @service service with the datatable method
     * @method  getTable (pokemon) or get/getRequests
     * @args    arguments to override
     */
    private struct function table(
        required any service,
        required string method,
        struct args = {}
    ) {
        var defaults = {records: 10, offset: 0, search: ""};
        if(method == "getTable") {
            defaults.append({
                orderCol1: "",
                orderDir1: "",
                orderCol2: "",
                orderDir2: ""
            });
        }
        else {
            defaults.append({orderCol: "", orderDir: ""});
        }
        return invoke(service, method, defaults.append(args));
    }

    /**
     * Shared datatable response checks
     */
    private void function expectDatatable(
        required struct result,
        required numeric total,
        boolean exact = true
    ) {
        expect(result).toHaveKey("data");
        expect(result).toHaveKey("recordsTotal");
        expect(result).toHaveKey("recordsFiltered");
        expect(result.data).toBeArray();
        if(exact) {
            expect(result.recordsTotal).toBe(total);
        }
        else {
            expect(result.recordsTotal).toBeGTE(total);
        }
        expect(result.recordsFiltered).toBeLTE(result.recordsTotal);
    }

    function run() {
        describe("Admin datatables", () => {
            describe("pokemonService.getTable", () => {
                it("Pages the non-costume pokemon", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM pokemon JOIN generation ON generation.generation = pokemon.generation WHERE pokemon.costume = false").total;
                    var result = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 0}
                    );

                    expectDatatable(result, total);
                    expect(result.recordsFiltered).toBe(total);
                    expect(result.data).toHaveLength(min(10, total));
                    expect(result.data[1]).toHaveKey("pokemonid,generation,number,gender,name,costumetype,sprite,shiny,shadow,shadowshiny,fastmoves,chargemoves,evolutiontext,shadowicon,ses");
                });

                it("Defaults to generation then number order", () => {
                    var result = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 0}
                    );
                    expect(result.data[1].number).toBe(1);
                    expect(result.data[1].generation).toBe("Kanto");
                });

                it("Sorts by a requested column", () => {
                    var result = table(
                        pokemonService,
                        "getTable",
                        {
                            records  : 25,
                            offset   : 0,
                            orderCol1: 1,
                            orderDir1: "desc"
                        }
                    );
                    var numbers = result.data.map((row) => row.number);
                    expect(numbers).toBe(numbers.duplicate().sort("numeric", "desc"));
                });

                it("Ignores a sort column that isn't sortable", () => {
                    var result = table(
                        pokemonService,
                        "getTable",
                        {
                            records  : 10,
                            offset   : 0,
                            orderCol1: 9,
                            orderDir1: "asc"
                        }
                    );
                    expect(result.data[1].number).toBe(1);
                });

                it("Pages without overlap", () => {
                    var first = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 0}
                    ).data.map((row) => row.pokemonid);
                    var second = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 10}
                    ).data.map((row) => row.pokemonid);
                    expect(first.filter((id) => second.contains(id))).toBeEmpty();
                });

                it("Searches by name and by number", () => {
                    var byName = table(
                        pokemonService,
                        "getTable",
                        {
                            records: 50,
                            offset : 0,
                            search : "bulbasaur"
                        }
                    );
                    expect(byName.recordsFiltered).toBeGTE(1);
                    expect(byName.recordsFiltered).toBeLT(byName.recordsTotal);
                    expect(byName.data.map((row) => row.name)).toInclude("Bulbasaur");

                    var byNumber = table(
                        pokemonService,
                        "getTable",
                        {records: 50, offset: 0, search: "1"}
                    );
                    expect(byNumber.data.filter((row) => row.number == 1)).notToBeEmpty();
                });

                it("Matches the entity's move and evolution text", () => {
                    var row = table(
                        pokemonService,
                        "getTable",
                        {
                            records: 50,
                            offset : 0,
                            search : "bulbasaur"
                        }
                    ).data.filter((row) => row.name == "Bulbasaur")[1];
                    var bulbasaur = entityLoadByPK("pokemon", row.pokemonid);

                    expect(row.fastmoves).toBe(bulbasaur.getMovesText("fast", "all"));
                    expect(row.chargemoves).toBe(bulbasaur.getMovesText("charge", "all"));
                    expect(row.evolutiontext).toBe(bulbasaur.getEvolutionText());
                    expect(row.evolutiontext).toInclude("Ivysaur");
                    expect(row.ses).toBe(bulbasaur.getSes());
                });

                it("Pages the costume pokemon separately", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM pokemon JOIN generation ON generation.generation = pokemon.generation WHERE pokemon.costume = true").total;
                    var result = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 0, costume: true}
                    );

                    expectDatatable(result, total);
                    result.data.each((row) => {
                        expect(row.ses).notToInclude("-");
                    });
                });

                it("Returns an empty page past the end", () => {
                    var result = table(
                        pokemonService,
                        "getTable",
                        {records: 10, offset: 100000}
                    );
                    expect(result.data).toBeEmpty();
                });
            });

            describe("trainerService.get", () => {
                it("Pages every trainer", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM trainer").total;
                    var result = table(trainerService, "get", {records: 10, offset: 0});

                    expectDatatable(result, total);
                    expect(result.recordsFiltered).toBe(total);
                    expect(result.data[1]).toHaveKey("trainerid,edit,icon,iconAltText,username,email,verified,securitylevel,lastlogin");
                });

                it("Finds a trainer by username with the entity's display values", () => {
                    var username = trainer.getUsername();
                    var result   = table(
                        trainerService,
                        "get",
                        {
                            records: 10,
                            offset : 0,
                            search : username
                        }
                    );

                    expect(result.recordsFiltered).toBe(1);
                    var row = result.data[1];
                    expect(row.trainerid).toBe(trainerid);
                    expect(row.email).toBe(trainer.getEmail());
                    expect(row.icon).toBe(trainer.getIconPath());
                    expect(row.iconAltText).toBe(trainer.getIconAltText());
                    expect(row.securitylevel).toBe("Regular User");
                    expect(row.lastlogin).toBe(
                        isNull(trainer.getLastLogin()) ? "---" : dateTimeFormat(
                            trainer.getLastLogin(),
                            "mmm-dd-yyyy HH:nn:ss"
                        )
                    );
                });

                it("Sorts by username", () => {
                    var usernames = table(
                        trainerService,
                        "get",
                        {
                            records : 25,
                            offset  : 0,
                            orderCol: 2,
                            orderDir: "asc"
                        }
                    ).data.map((row) => row.username);
                    var expected = queryExecute(
                        "SELECT username FROM trainer ORDER BY username ASC NULLS LAST, id ASC LIMIT 25",
                        {},
                        {returntype: "array"}
                    ).map((row) => row.username);
                    expect(usernames).toBe(expected);
                });
            });

            describe("bugService.get", () => {
                it("Pages every bug", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM bug").total;
                    var result = table(bugService, "get", {records: 10, offset: 0});

                    expectDatatable(result, total);
                    expect(result.data[1]).toHaveKey("id,timestamp,ip,event,message,username,stack");
                });

                it("Finds a bug by message with its trainer's username", () => {
                    var result = table(
                        bugService,
                        "get",
                        {records: 10, offset: 0, search: marker}
                    );

                    expect(result.recordsFiltered).toBe(1);
                    expect(result.data[1].event).toBe("#marker#.event");
                    expect(result.data[1].username).toBe(trainer.getUsername());
                });

                it("Sorts newest first", () => {
                    var ids = table(
                        bugService,
                        "get",
                        {
                            records : 10,
                            offset  : 0,
                            orderCol: 0,
                            orderDir: "desc"
                        }
                    ).data.map((row) => row.id);
                    var expected = queryExecute(
                        "SELECT id FROM bug ORDER BY created DESC, id ASC LIMIT 10",
                        {},
                        {returntype: "array"}
                    ).map((row) => row.id);
                    expect(ids).toBe(expected);
                });
            });

            describe("auditService.get", () => {
                it("Pages every audit", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM audit").total;
                    var result = table(auditService, "get", {records: 10, offset: 0});

                    expectDatatable(result, total);
                    expect(result.data[1]).toBeArray();
                    expect(result.data[1]).toHaveLength(7);
                });

                it("Finds an audit by detail with its trainer's username", () => {
                    var result = table(
                        auditService,
                        "get",
                        {records: 10, offset: 0, search: marker}
                    );

                    expect(result.recordsFiltered).toBe(1);
                    var row = result.data[1];
                    expect(row[3]).toBe("#marker#.event");
                    expect(row[5]).toBe("#marker# detail");
                    expect(row[7]).toBe(trainer.getUsername());
                });
            });

            describe("auditService.getRequests", () => {
                it("Pages every request", () => {
                    var total  = queryExecute("SELECT COUNT(*) AS total FROM request_log").total;
                    var result = table(
                        auditService,
                        "getRequests",
                        {records: 10, offset: 0}
                    );

                    expectDatatable(result, total, false); // requests are logged in the background
                    expect(result.data[1]).toBeArray();
                    expect(result.data[1]).toHaveLength(9);
                });

                it("Finds a request by path, truncating long paths", () => {
                    var result = table(
                        auditService,
                        "getRequests",
                        {records: 10, offset: 0, search: marker}
                    );

                    expect(result.recordsFiltered).toBe(1);
                    var row = result.data[1];
                    expect(row[3]).toHaveLength(153);
                    expect(row[3]).toInclude(marker);
                    expect(right(row[3], 3)).toBe("...");
                    expect(row[7]).toBe(200);
                    expect(row[9]).toBe(trainer.getUsername());
                });

                it("Searches the status code", () => {
                    var result = table(
                        auditService,
                        "getRequests",
                        {records: 10, offset: 0, search: "200"}
                    );
                    expect(result.recordsFiltered).toBeGTE(1);
                });
            });
        });
    }

}
