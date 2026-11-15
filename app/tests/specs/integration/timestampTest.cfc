component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        accountService = getInstance("services.account");

        // Fresh row for the insert stamps, then shared by the update specs
        trainerid = mockTrainer.make(autoLogin = false).id;
    }

    function afterAll() {
        mockTrainer.deleteTrainer(trainerid);
        super.afterAll();
    }

    /**
     * Move the trainer's created/updated into the past, so the next update's stamp is later without waiting
     * Setting updated explicitly keeps the trigger from stamping this update itself
     *
     * @trainerid trainer pk
     */
    private void function backdate(required numeric trainerid) {
        var past = createDateTime(2025, 1, 1, 0, 0, 0);
        testData.updateRow(
            "trainer",
            arguments.trainerid,
            {created: past, updated: past}
        );
    }

    function run() {
        describe("Created and updated timestamps", () => {
            beforeEach(() => {
                setup();
            });

            it("Sets created and updated when a row is inserted", () => {
                var row = mockTrainer.getSaved(trainerid);

                // Inserts may be slow in the test env
                expect(row.created).notToBeNull();
                expect(dateDiff("s", row.created, now())).toBeLT(30);
                expect(row.updated).notToBeNull();
                expect(dateDiff("s", row.updated, now())).toBeLT(30);
            });

            it("Moves updated forward and leaves created alone when a row is updated", () => {
                backdate(trainerid);
                var before  = mockTrainer.getSaved(trainerid);
                var newIcon = before.icon == "squirtle" ? "bulbasaur" : "squirtle";

                accountService.updateTrainer(
                    trainerid = trainerid,
                    username  = before.username,
                    password  = "",
                    email     = before.email,
                    icon      = newIcon
                );

                var after = mockTrainer.getSaved(trainerid);
                expect(after.icon).toBe(newIcon);
                expect(after.updated).toBeGT(before.updated);
                expect(after.created).toBe(before.created);
                expect(after.created).toBeLT(after.updated);
            });

            describe("Stamped by the database for plain sql", () => {
                // One stat per trainer per day - each spec starts without one for today
                beforeEach(() => {
                    queryExecute(
                        "DELETE FROM stat WHERE trainerid = :trainerid AND CAST(created AS date) = CURRENT_DATE",
                        {trainerid: {value: trainerid, cfsqltype: "integer"}}
                    );
                });

                it("Defaults created and updated on insert", () => {
                    var statid = testData.insertRow(
                        "stat",
                        {
                            trainerid: trainerid,
                            xp       : 1,
                            caught   : 0,
                            spun     : 0,
                            walked   : 0
                        }
                    );
                    var row = testData.getRowById("stat", statid);

                    expect(dateDiff("s", row.created, now())).toBeLT(30);
                    expect(row.updated).toBe(row.created);
                });

                it("Keeps a created date the insert supplies", () => {
                    var created = createDateTime(2025, 1, 2, 3, 4, 5);
                    var statid  = testData.insertRow(
                        "stat",
                        {
                            trainerid: trainerid,
                            xp       : 1,
                            caught   : 0,
                            spun     : 0,
                            walked   : 0,
                            created  : created
                        }
                    );

                    expect(testData.getRowById("stat", statid).created).toBe(created);
                });

                it("Stamps at millisecond precision, like the jvm", () => {
                    var statid = testData.insertRow(
                        "stat",
                        {
                            trainerid: trainerid,
                            xp       : 1,
                            caught   : 0,
                            spun     : 0,
                            walked   : 0
                        }
                    );
                    testData.updateRow("stat", statid, {xp: 2});

                    var precise = queryExecute(
                        "
                        SELECT created = DATE_TRUNC('milliseconds', created) AS createdms,
                            updated = DATE_TRUNC('milliseconds', updated) AS updatedms
                        FROM stat
                        WHERE id = :id
                        ",
                        {id: {value: statid, cfsqltype: "integer"}}
                    );
                    expect(precise.createdms).toBeTrue();
                    expect(precise.updatedms).toBeTrue();
                });

                it("Moves updated forward on update and leaves created alone", () => {
                    backdate(trainerid);
                    var before = mockTrainer.getSaved(trainerid);

                    testData.updateRow("trainer", trainerid, {lastlogin: now()});

                    var after = mockTrainer.getSaved(trainerid);
                    expect(after.updated).toBeGT(before.updated);
                    expect(after.created).toBe(before.created);
                });

                it("Keeps an updated value the update sets itself", () => {
                    var updated = createDateTime(2025, 6, 7, 8, 9, 10);
                    testData.updateRow("trainer", trainerid, {updated: updated});

                    expect(mockTrainer.getSaved(trainerid).updated).toBe(updated);
                });
            });
        });
    }

}
