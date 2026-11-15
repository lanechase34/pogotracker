component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer  = getInstance("tests.resources.mockTrainer");
        trainer      = mockTrainer.make(autoLogin = false);
        statsService = getInstance("services.stats");
        cache        = getInstance("cachebox:appCache");

        // Last month, so there are always two days for the two stats (one stat per trainer per day)
        boardDate = dateAdd(
            "s",
            -1,
            createDateTime(year(now()), month(now()), 1, 0, 0, 0)
        );
        var first = createDateTime(year(boardDate), month(boardDate), 1, 12, 0, 0);

        // Two stats in the month with a delta no seeded trainer can beat
        [
            {created: first, xp: 1},
            {created: dateAdd("d", 1, first), xp: 5000000000000}
        ].each((stat) => {
            testData.insertRow(
                "stat",
                {
                    trainerid: trainer.id,
                    created  : stat.created,
                    xp       : stat.xp,
                    caught   : 0,
                    spun     : 0,
                    walked   : 0
                }
            );
        });
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);
        // Don't leave the huge test delta in the cached leaderboard
        cache.clearByKeySnippet("stats.getLeaderboard");
    }

    function run() {
        describe("statsService.getLeaderboard", () => {
            beforeEach(() => {
                setup();
                cache.clearByKeySnippet("stats.getLeaderboard");
            });

            it("Returns the true top 10 by monthly delta, largest first", () => {
                var leaderboard = statsService.getLeaderboard(date = boardDate, stat = "xp");

                var low         = createDateTime(year(boardDate), month(boardDate), 1, 0, 0, 0);
                var high        = dateAdd("s", -1, dateAdd("m", 1, low));
                var daysElapsed = dateDiff("d", low, boardDate) + 1;

                var expected = queryExecute(
                    "
                    SELECT MAX(stat.xp) - MIN(stat.xp) AS delta
                    FROM trainer
                    INNER JOIN stat ON stat.trainerid = trainer.id AND stat.created >= :low AND stat.created <= :high
                    WHERE trainer.verified = true AND trainer.username IS NOT NULL
                    GROUP BY trainer.id
                    HAVING COUNT(stat.id) > 1
                    ORDER BY delta DESC
                    LIMIT 10
                    ",
                    {low: {value: low, cfsqltype: "timestamp"}, high: {value: high, cfsqltype: "timestamp"}}
                );

                expect(leaderboard.len()).toBe(expected.recordCount);
                expect(leaderboard[1].username).toBe(trainer.username);

                leaderboard.each((row, index) => {
                    expect(row.delta).toBeCloseTo(expected.delta[index] / daysElapsed, 0.0001);
                    if(index > 1) {
                        expect(leaderboard[index - 1].delta >= row.delta).toBeTrue();
                    }
                });
            });

            it("Caches per year and month, not just month", () => {
                statsService.getLeaderboard(date = now(), stat = "xp");

                expect(cache.get("stats.getLeaderboard|date=#year(now())#-#month(now())#|stat=xp")).notToBeNull();
                // Same month last year is a different key - nothing cached for it yet
                expect(cache.get("stats.getLeaderboard|date=#year(now()) - 1#-#month(now())#|stat=xp")).toBeNull();
            });
        });
    }

}
