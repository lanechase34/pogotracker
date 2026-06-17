component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer     = getInstance('tests.resources.mockTrainer');
        securityService = getInstance('services.security');
        persistService  = getInstance('services.persist');
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists('mocktrainerid')) mockTrainer.delete();
    }

    function run() {
        describe('sessionService', () => {
            describe('rotate()', () => {
                beforeEach(() => {
                    setup();
                    sessionService = createMock(className = 'models.services.session');
                    sessionService.$('destroy');
                    sessionService.$('ensureSession');
                    sessionService.$('getCurrentSessionId');
                });

                it('Sets the new id on the session when rotation succeeds', () => {
                    sessionService.$('getRequestedSessionId', 'OLD-ID');
                    sessionService.$('changeSessionId', 'NEW-ID');

                    sessionService.rotate();

                    expect(session.sessionid).toBe('NEW-ID');
                    expect(sessionService.$count('destroy')).toBe(0);
                    expect(sessionService.$count('getCurrentSessionId')).toBe(0); // catch never entered
                });

                it('Continues safely when a concurrent request already rotated the id', () => {
                    // changeSessionId() throws, but the id has already moved off the inbound id
                    sessionService.$('getRequestedSessionId', 'OLD-ID');
                    sessionService
                        .$(method = 'changeSessionId')
                        .$throws(type = 'java.lang.IllegalStateException', message = 'UT010033: No session');
                    sessionService.$('getCurrentSessionId', 'NEW-ID');

                    sessionService.rotate();

                    expect(session.sessionid).toBe('NEW-ID');
                    expect(sessionService.$count('destroy')).toBe(0);
                });

                it('Continues safely for a brand-new session the client never presented', () => {
                    // No inbound id -> no fixation risk even though rotation failed
                    sessionService.$('getRequestedSessionId', '');
                    sessionService
                        .$(method = 'changeSessionId')
                        .$throws(type = 'java.lang.IllegalStateException', message = 'UT010033: No session');
                    sessionService.$('getCurrentSessionId', 'FRESH-ID');

                    sessionService.rotate();

                    expect(session.sessionid).toBe('FRESH-ID');
                    expect(sessionService.$count('destroy')).toBe(0);
                });

                it('Destroys the session and throws when the inbound id was never rotated (fixation risk)', () => {
                    // changeSessionId() throws AND we are still on the id the client presented
                    sessionService.$('getRequestedSessionId', 'FIXED-ID');
                    sessionService
                        .$(method = 'changeSessionId')
                        .$throws(type = 'java.lang.IllegalStateException', message = 'UT010033: No session');
                    sessionService.$('getCurrentSessionId', 'FIXED-ID');

                    expect(() => {
                        sessionService.rotate();
                    }).toThrow(type = 'SessionRotationFailed');

                    expect(sessionService.$count('destroy')).toBe(1);
                });
            });

            describe('create()', () => {
                beforeEach(() => {
                    setup();
                    sessionService = getInstance('services.session');
                });

                it('Creates an authenticated session and applies default settings for a new trainer', () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();

                    // Force empty settings so the isEmpty() branch backfills defaults
                    trainer.setSettings({});
                    entitySave(trainer);
                    ormFlush();

                    setup();
                    sessionService.create(email = trainer.getEmail(), persist = false);
                    execute(event = 'home.home', renderResults = true); // settle rotate

                    expect(session.authenticated).toBeTrue();
                    expect(session.trainerid).toBe(trainerid);
                    expect(session.settings).toHaveKey('defaultPage');
                    expect(session.linkedEvent).toBe('/'); // from defaultSettings.defaultPage
                    expect(request.linkedEvent).toBe(session.linkedEvent);

                    mockTrainer.delete(trainerid);
                });

                it('Stores a persist cookie when persist is true', () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();

                    setup();
                    sessionService.create(email = trainer.getEmail(), persist = true);
                    execute(event = 'home.home', renderResults = true);

                    expect(session.authenticated).toBeTrue();
                    expect(persistService.checkCookie()).toBeTrue();

                    mockTrainer.delete(trainerid);
                });

                it('Preserves an existing linkedEvent instead of defaulting it', () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();

                    setup();
                    session.linkedEvent = '/overview';
                    sessionService.create(email = trainer.getEmail(), persist = false);
                    execute(event = 'home.home', renderResults = true);

                    expect(session.linkedEvent).toBe('/overview');
                    expect(request.linkedEvent).toBe('/overview');

                    mockTrainer.delete(trainerid);
                });
            });

            describe('create() settings migration + audit (mocked deps)', () => {
                beforeEach(() => {
                    setup();
                });

                it('Audits the login when auditInfo is supplied', () => {
                    trainer   = mockTrainer.make(autoLogin = false);
                    trainerid = trainer.getId();

                    mockAudit = createEmptyMock(className = 'models.services.audit');
                    mockAudit.$('audit');

                    mockSession = createMock(className = 'models.services.session');
                    mockSession.$property(propertyName = 'securityService', mock = securityService);
                    mockSession.$property(propertyName = 'auditService', mock = mockAudit);
                    mockSession.$property(
                        propertyName = 'defaultSettings',
                        mock         = {
                            defaultView  : '',
                            defaultRegion: 'Kanto',
                            defaultPage  : '/'
                        }
                    );
                    mockSession.$('rotate');

                    auditInfo = {detail: 'Successful Login', event: 'login'};
                    mockSession.create(
                        email     = trainer.getEmail(),
                        persist   = false,
                        auditInfo = auditInfo
                    );

                    expect(mockAudit.$count('audit')).toBe(1);
                    expect(auditInfo.trainerid).toBe(trainerid); // stamped onto the struct before auditing

                    mockTrainer.delete(trainerid);
                });
            });

            describe('destroy()', () => {
                beforeEach(() => {
                    setup();
                    sessionService = getInstance('services.session');
                });

                it('Clears the persist cookie on a full logout', () => {
                    trainer   = mockTrainer.make();
                    trainerid = trainer.getId();
                    persistService.addCookie(trainer);
                    expect(persistService.checkCookie()).toBeTrue();

                    sessionService.destroy(idle = false);

                    expect(session.keyExists('trainerid')).toBeFalse();
                    expect(persistService.checkCookie()).toBeFalse();

                    mockTrainer.delete(trainerid);
                });

                it('Preserves the persist cookie on an idle logout', () => {
                    trainer   = mockTrainer.make();
                    trainerid = trainer.getId();
                    persistService.addCookie(trainer);
                    expect(persistService.checkCookie()).toBeTrue();

                    sessionService.destroy(idle = true);

                    expect(session.keyExists('trainerid')).toBeFalse();
                    expect(persistService.checkCookie()).toBeTrue();

                    persistService.deleteCookie(); // cleanup the preserved cookie
                    mockTrainer.delete(trainerid);
                });

                it('Does not throw when no trainer is in the session', () => {
                    if(session.keyExists('trainerid')) session.delete('trainerid');

                    sessionService.destroy(idle = true);

                    expect(session.keyExists('trainerid')).toBeFalse();
                });
            });

            describe('update()', () => {
                beforeEach(() => {
                    setup();
                    sessionService = getInstance('services.session');
                });

                it('Refreshes session data from the trainer record', () => {
                    trainer   = mockTrainer.make(); // logged in -> session.trainerid set
                    trainerid = trainer.getId();

                    newUsername = 'UPD_#trainer.getUsername()#';
                    trainer.setUsername(newUsername);
                    entitySave(trainer);
                    ormFlush();

                    sessionService.update(trainerid);

                    expect(session.username).toBe(newUsername);
                    expect(session.trainer.getId()).toBe(trainerid);

                    mockTrainer.delete(trainerid);
                });
            });

            describe('setAlert() / clearAlert()', () => {
                beforeEach(() => {
                    setup();
                    sessionService = getInstance('services.session');
                });

                it('Sets an alert with an explicit margin', () => {
                    sessionService.setAlert(
                        type        = 'danger',
                        dismissible = true,
                        icon        = 'bi-exclamation-diamond-fill',
                        message     = 'Something went wrong',
                        margin      = 5
                    );

                    expect(session.alert.type).toBe('danger');
                    expect(session.alert.dismissible).toBeTrue();
                    expect(session.alert.icon).toBe('bi-exclamation-diamond-fill');
                    expect(session.alert.message).toBe('Something went wrong');
                    expect(session.alert.margin).toBe(5);
                });

                it('Defaults the alert margin to 3', () => {
                    sessionService.setAlert(
                        type        = 'success',
                        dismissible = false,
                        icon        = 'bi-check-square-fill',
                        message     = 'All good'
                    );

                    expect(session.alert.margin).toBe(3);
                });

                it('Clears an existing alert', () => {
                    sessionService.setAlert(
                        type        = 'success',
                        dismissible = false,
                        icon        = 'bi-check-square-fill',
                        message     = 'All good'
                    );
                    expect(session.keyExists('alert')).toBeTrue();

                    sessionService.clearAlert();

                    expect(session.keyExists('alert')).toBeFalse();
                });
            });
        });
    }

}
