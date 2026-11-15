component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance("tests.resources.mockTrainer");
        trainer        = mockTrainer.make(autoLogin = false);
        statsService   = getInstance("services.stats");
        trainerService = getInstance("services.trainer");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);
    }

    function run() {
        // getLatestStat / getCurrentLevel read the newest stat with a single query
        describe("trainer.getLatestStat", () => {
            beforeEach(() => {
                setup();
            });

            it("Returns nothing when the trainer has no stats", () => {
                expect(isNull(statsService.getLatestStat(trainer.id))).toBeTrue();
                expect(trainerService.getCurrentLevel(trainer.id).level).toBe("--");
            });

            it("Returns the stat with the newest created date, not the highest id", () => {
                statsService.track(
                    trainerid = trainer.id,
                    xp        = 100,
                    caught    = 0,
                    spun      = 0,
                    walked    = 0
                );

                // Inserted after (higher id) but dated two days earlier
                testData.insertRow(
                    "stat",
                    {
                        trainerid: trainer.id,
                        xp       : 900,
                        caught   : 0,
                        spun     : 0,
                        walked   : 0,
                        created  : dateAdd("d", -2, now())
                    }
                );

                var latest = statsService.getLatestStat(trainer.id);
                expect(isNull(latest)).toBeFalse();
                expect(latest.xp).toBe(100);
                expect(trainerService.getCurrentLevel(trainer.id).totalxp).toBe(numberFormat(100, ","));
            });
        });
    }

}
