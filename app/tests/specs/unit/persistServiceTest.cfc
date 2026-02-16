component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer = getInstance('tests.resources.mocktrainer');
        // Set up trainer to be shared throughout test suite
        trainer     = mockTrainer.make();

        loopCount       = 100;
        range           = 5;
        persistDuration = application.cbController.getSetting('persistDuration');
        persistUse      = application.cbController.getSetting('persistUse');
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete();
    }

    function run() {
        describe('Persist service', () => {
            beforeEach(() => {
                setup();
                persistService = getInstance('services.persist');
            });

            it('Can be created', () => {
                expect(persistService).toBeComponent();
            });

            it('Can create a persist cookie', () => {
                expect(countPersist(trainerid = trainer.getId())).toBe(0);

                beforeCount = countPersist();
                cookieCount = cookie.count();

                // Create the persist cookie
                persistService.addCookie(trainer);

                // Trainer should now have one persist cookie record
                expect(countPersist(trainerid = trainer.getId())).toBe(1);
                expect(countPersist()).toBe(beforeCount + 1);
                expect(cookie.count()).toBe(cookieCount + 1);
                expect(persistService.checkCookie()).toBeTrue();
            });

            it('Can rotate a persist cookie', () => {
                expect(persistService.checkCookie()).toBeTrue();
                persist = entityLoad('persist', {trainer: trainer}, true);
                expect(persist).notToBeNull();

                before = persistService.getCookie();
                persistService.rotateCookie(persist);

                expect(before).notToBeWithCase(persistService.getCookie());

                entityReload(persist);
                expect(dateDiff('s', persist.getUpdated(), now())).toBeLTE(10);
            });

            it('Can delete a persist cookie', () => {
                expect(persistService.checkCookie()).toBeTrue();
                persistService.deleteCookie();
                expect(persistService.checkCookie()).toBeFalse();
            });

            describe('Persist cookie task tests', () => {
                it('Can delete cookies that have expired', () => {
                    keep   = countPersist();
                    delete = 0;
                    for(var i = 1; i <= loopCount; i++) {
                        // Create cookies that have a create date between -persistDuration +/- 10 days ago
                        currRand = randRange(-1 * range, range);
                        currDate = dateAdd('d', (-1 * persistDuration) + currRand, now());
                        // Cookies that have a negative or 0 days added will be older than the threshold
                        if(currRand > 0) keep += 1;
                        else delete += 1;

                        var persist = entityNew(
                            'persist',
                            {
                                created    : currDate,
                                trainer    : trainer,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : now(),
                                lastrotated: now()
                            }
                        );
                        entitySave(persist);
                    }
                    ormFlush();

                    expect(countPersist()).toBe(keep + delete);
                    persistService.cleanupCookies();
                    expect(countPersist()).toBe(keep);
                });

                it('Can delete cookies that have not been used in interval', () => {
                    keep   = countPersist();
                    delete = 0
                    for(var i = 1; i <= loopCount; i++) {
                        currRand = randRange(-1 * range, range);
                        currDate = dateAdd('d', (-1 * persistUse) + currRand, now());

                        // Cookies that are older or equal to the persistUse amount will be deleted
                        if(currRand > 0) keep += 1;
                        else delete += 1;

                        var persist = entityNew(
                            'persist',
                            {
                                trainer    : trainer,
                                cookie     : createUUID(),
                                agent      : createUUID(),
                                lastused   : currDate,
                                lastrotated: now()
                            }
                        );
                        entitySave(persist);
                    }
                    ormFlush();

                    expect(countPersist()).toBe(keep + delete);
                    persistService.cleanupCookies();
                    expect(countPersist()).toBe(keep);
                });
            });

            // Life cycle
            describe('User persist login life cycle tests', () => {
                it('Can submit login form with remember me option and get a persist token', () => {
                });

                it('Can have an ''idle'' logout and automatically persist log back in', () => {
                });

                it('Can persist login when session becomes invalidated (jsessionid deleted)', () => {
                });

                it('Clicking logout deletes the persist cookie', () => {
                });

                it('Clicking logout does nothing if no persist cookie', () => {
                });
            })
        });
    }

    numeric function countPersist(numeric trainerid = -1) {
        var whereClause = 'WHERE 1 = 1';
        var params      = {};
        if(arguments.trainerid >= 1) {
            whereClause &= ' AND trainerid = :trainerid';
            params.insert('trainerid', {value: arguments.trainerid, cfsqltype: 'integer'});
        }

        var count = queryExecute(
            '
            select count(id) as count
            from persist
            #whereClause#
        ',
            params
        );

        return count.count;
    }

}
