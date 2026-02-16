component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
        trainer     = mockTrainer.make();

        currDate  = dateFormat(now(), 'short');
        dayOfWeek = dayOfWeek(currDate);

        startDate = dateAdd('d', -(dayOfWeek - 1), currDate);
        endDate   = dateAdd('d', (7 - dayOfWeek), currDate);
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe('Stats service tests', () => {
            beforeEach(() => {
                setup();
                statsService = getInstance('services.stats');
            });

            it('Can be created', () => {
                expect(statsService).toBeComponent();
            });

            it('Has no stats tracked for today', () => {
                expect(statsService.getFromDay(trainer = trainer, suppliedDate = now())).toBeNull();
            });

            it('Has no stats returned for range', () => {
                getStats = statsService.get(
                    trainer   = trainer,
                    datePart  = 'd',
                    startDate = startDate,
                    endDate   = endDate
                );
                expect(getStats).toBeStruct();
                expect(getStats).toHaveKey('data');
                expect(getStats.data.count()).toBe(0);

                expect(getStats).toHaveKey('labels');
                expect(getStats.labels).toBeArray();
                expect(getStats.labels.len()).toBe(0);
            });

            it('Can track stats for today', () => {
                event = post(
                    route  = '/stats/track',
                    params = {
                        trainerid: session.trainerid,
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
                currStats = statsService.getFromDay(trainer = trainer, suppliedDate = now());
                expect(currStats).toBeComponent();
                expect(currStats.getXP()).toBe(1);
                expect(currStats.getCaught()).toBe(2);
                expect(currStats.getSpun()).toBe(3);
                expect(currStats.getWalked()).toBe(4);
            });

            it('Can get stats for the current week', () => {
                // Create data for the current week
                count = dateDiff('d', startDate, endDate);
                for(var i = 0; i <= count; i++) {
                    currDate = dateTimeFormat(dateAdd('d', i, startDate));
                    if(
                        dateDiff(
                            'd',
                            dateFormat(currDate, 'short'),
                            dateFormat(now(), 'short')
                        ) == 0
                    )
                        continue; // skip current day

                    currStat = entityNew(
                        'stat',
                        {
                            'created': currDate,
                            'trainer': session.trainer,
                            'xp'     : i + 1,
                            'caught' : i + 2,
                            'spun'   : i + 3,
                            'walked' : i + 4
                        }
                    );
                    entitySave(currStat);
                }
                ormFlush();

                // Load data for the curr week
                getStats = statsService.get(
                    trainer   = trainer,
                    datePart  = 'd',
                    startDate = startDate,
                    endDate   = endDate
                );
                expect(getStats).toBeStruct();
                expect(getStats).toHaveKey('data');
                expect(getStats.data.count()).toBe(7);

                expect(getStats).toHaveKey('labels');
                expect(getStats.labels).toBeArray();
                expect(getStats.labels.len()).toBe(7);

                expect(getStats).toHaveKey('summary');

                if(application.cbController.getSetting('useCache')) {
                    // Check the cache for key
                    cacheKey = '#trainer.getId()#|stats.getStats|startDate=#dateFormat(startDate, 'short')#|endDate=#dateFormat(endDate, 'short')#';
                    expect(getInstance('services.cache').get(cacheKey)).notToBeNull();
                }
            });

            it('Can get the leaderboard', () => {
                var stats = ['xp', 'caught', 'spun', 'walked'];
                stats.each((stat) => {
                    leaderboard = statsService.getLeaderboard(date = now(), stat = stat);
                    expect(leaderboard).toBeArray();
                    expect(leaderboard.len()).toBeGTE(1);
                    found = false;
                    leaderboard.each((row) => {
                        if(row.username == session.username) {
                            found = true;
                            break;
                        }
                    });
                    expect(found).toBeTrue();
                });
            });
        });
    }

}
