/**
 * trainer.getLatestStat / getCurrentLevel read the newest stat with a single query
 */
component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer  = getInstance("tests.resources.mocktrainer");
        trainer      = mockTrainer.make();
        statsService = getInstance("services.stats");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe("trainer.getLatestStat", () => {
            beforeEach(() => {
                setup();
            });

            it("Returns nothing when the trainer has no stats", () => {
                expect(isNull(trainer.getLatestStat())).toBeTrue();
                expect(trainer.getCurrentLevel().level).toBe("--");
            });

            it("Returns the stat with the newest created date, not the highest id", () => {
                statsService.track(
                    trainer = trainer,
                    xp      = 100,
                    caught  = 0,
                    spun    = 0,
                    walked  = 0
                );

                // Inserted after (higher id) but dated two days earlier
                entitySave(
                    entityNew(
                        "stat",
                        {
                            "trainer": trainer,
                            "xp"     : 900,
                            "caught" : 0,
                            "spun"   : 0,
                            "walked" : 0,
                            "created": dateAdd("d", -2, now())
                        }
                    )
                );
                ormFlush();

                var latest = trainer.getLatestStat();
                expect(isNull(latest)).toBeFalse();
                expect(latest.getXp()).toBe(100);
                expect(trainer.getCurrentLevel().totalxp).toBe(numberFormat(100, ","));
            });
        });
    }

}
