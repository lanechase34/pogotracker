component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");
        trainer     = mockTrainer.makeSignedIn(); // tracks stats through the handler

        currDate  = dateFormat(now(), "short");
        dayOfWeek = dayOfWeek(currDate);

        startDate = dateAdd("d", -(dayOfWeek - 1), currDate);
        endDate   = dateAdd("d", (7 - dayOfWeek), currDate);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer();
    }

    function run() {
        describe("Stats service tests", () => {
            beforeEach(() => {
                setup();
                statsService = getInstance("services.stats");
            });

            it("Has no stats tracked for today", () => {
                expect(statsService.getFromDay(trainerid = trainer.id, suppliedDate = now())).toBeNull();
            });

            it("Has no stats returned for range", () => {
                var getStats = statsService.getStats(
                    trainerid = trainer.id,
                    startDate = startDate,
                    endDate   = endDate
                );
                expect(getStats).toBeStruct();
                expect(getStats).toHaveKey("data");
                expect(getStats.data.count()).toBe(0);

                expect(getStats).toHaveKey("labels");
                expect(getStats.labels).toBeArray();
                expect(getStats.labels.len()).toBe(0);
            });

            it("Can track stats for today", () => {
                var event = post(
                    route  = "/stats/track",
                    params = {
                        trainerid: trainer.id,
                        xp       : 1,
                        caught   : 2,
                        spun     : 3,
                        walked   : 4
                    }
                );

                // Verify successful response
                expect(event.getStatusCode()).toBe(200);
                var response = deserializeJSON(event.getRenderedContent());
                expect(response.success).toBeTrue();

                // Check stats were tracked
                var currStats = statsService.getFromDay(trainerid = trainer.id, suppliedDate = now());
                expect(currStats).toBeStruct();
                expect(currStats.xp).toBe(1);
                expect(currStats.caught).toBe(2);
                expect(currStats.spun).toBe(3);
                expect(currStats.walked).toBe(4);
            });

            it("Can get stats for the current week", () => {
                // Create data for the current week
                var dayCount = dateDiff("d", startDate, endDate);
                for(var i = 0; i <= dayCount; i++) {
                    var currDate = dateTimeFormat(dateAdd("d", i, startDate));
                    if(
                        dateDiff(
                            "d",
                            dateFormat(currDate, "short"),
                            dateFormat(now(), "short")
                        ) == 0
                    )
                        continue; // skip current day

                    testData.insertRow(
                        "stat",
                        {
                            created  : currDate,
                            trainerid: trainer.id,
                            xp       : i + 1,
                            caught   : i + 2,
                            spun     : i + 3,
                            walked   : i + 4
                        }
                    );
                }

                // Load data for the curr week
                var getStats = statsService.getStats(
                    trainerid = trainer.id,
                    startDate = startDate,
                    endDate   = endDate
                );
                expect(getStats).toBeStruct();
                expect(getStats).toHaveKey("data");
                expect(getStats.data.count()).toBe(7);

                expect(getStats).toHaveKey("labels");
                expect(getStats.labels).toBeArray();
                expect(getStats.labels.len()).toBe(7);

                expect(getStats).toHaveKey("summary");

                // Check the cache for key
                var cacheKey = "#trainer.id#|stats.getStats|startDate=#dateFormat(startDate, "short")#|endDate=#dateFormat(endDate, "short")#";
                expect(getInstance("cachebox:trainerCache").get(cacheKey)).notToBeNull();
            });

            it("Can get the leaderboard", () => {
                for(var stat in ["xp", "caught", "spun", "walked"]) {
                    var leaderboard = statsService.getLeaderboard(date = now(), stat = stat);
                    expect(leaderboard).toBeArray();
                    expect(leaderboard.len()).toBeGTE(1);
                    expect(leaderboard.some((row) => row.username == trainer.username)).toBeTrue();
                }
            });

            it("Rejects a duplicate stat on the same day", () => {
                // Today's stat was already tracked by "Can track stats for today"
                expect(
                    statsService.track(
                        trainerid = trainer.id,
                        xp        = 200,
                        caught    = 2,
                        spun      = 2,
                        walked    = 2
                    )
                ).toBeFalse();

                var today = statsService.getFromDay(trainerid = trainer.id, suppliedDate = now());
                expect(today.xp).toBe(1);
                expect(
                    queryExecute(
                        "SELECT COUNT(*) AS total FROM stat WHERE trainerid = :trainerid AND CAST(created AS date) = CURRENT_DATE",
                        {trainerid: {value: trainer.id, cfsqltype: "integer"}}
                    ).total
                ).toBe(1);
            });
        });
    }

}
