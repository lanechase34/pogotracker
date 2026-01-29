component extends="coldbox.system.testing.BaseTestCase" {

    property name="trainerService"  inject="services.trainer";
    property name="securityService" inject="services.security";
    property name="sessionService"  inject="services.session";

    /**
     * Makes mock user for testing
     */
    component function make(numeric securityLevel = 10, boolean autoLogin = true) {
        var username = 'TEST_#left(createUUID().replace('-', '', 'all'), 10)#';
        var email    = '#username#@gmail.com';
        var password = createUUID();

        securityService.register(
            username   = username,
            password   = password,
            email      = email,
            friendcode = makeFriendcode(),
            icon       = 'charmander'
        );

        var trainer = securityService.getTrainer(email)[1];
        trainer.setVerified(true);
        trainer.setSecurityLevel(arguments.securityLevel);
        entitySave(trainer);
        ormFlush();

        if(arguments.autoLogin) {
            login(trainer);
        }
        else {
            execute(route = '/', renderResults = true);
            expect(session.authenticated).toBeFalse();
        }

        session.mocktrainerid = trainer.getId();
        return trainerService.getFromId(session.mocktrainerid);
    }

    /**
     * Deletes the mock user created
     * Deletes any associated data
     */
    void function delete(numeric trainerid = session.mocktrainerid) {
        var trainer = trainerService.getFromId(arguments.trainerid);

        ormExecuteQuery('delete from requestlog where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from audit where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from blog where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from bug where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from comment where trainer = :trainer', {trainer: trainer});

        ormExecuteQuery(
            'delete from custompokedex where custom in (from custom where trainer = :trainer)',
            {trainer: trainer}
        );
        ormExecuteQuery('delete from custom where trainer = :trainer', {trainer: trainer});

        ormExecuteQuery('delete from friend where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from friend where friend = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from persist where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from pokedex where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from stat where trainer = :trainer', {trainer: trainer});

        // ormExecuteQuery('delete from team where trainer = :trainer', {trainer: trainer});
        ormExecuteQuery('delete from trainermedal where trainer = :trainer', {trainer: trainer});

        entityDelete(trainer);
        ormFlush();
        sessionService.destroy(false);
        expect(session.keyExists('trainerid')).toBeFalse();
    }

    /**
     * Log in the mock trainer
     */
    void function login(required component trainer, string relocate_uri = '/') {
        // Force valid recaptcha
        session.recaptcha = {
            token    : 'a',
            valid    : true,
            timestamp: now(),
            action   : 'doLogin'
        };

        // Mock submitting login form
        event = post(
            route  = '/login/doLogin',
            params = {
                '#application.cbController.getSetting('csrfTokenField')#': csrfGenerateToken(forceNew = true),
                email   : arguments.trainer.getEmail(),
                password: createUUID()
            }
        );

        // After log in, you will be redirected to home page - did a lucee update break this?
        var response = event.getResponse();
        if(isStruct(response) && (response?.keyExists('statuscode') ?: false)) {
            expect(response.statuscode).toBe(200);
            expect(event.getValue('relocate_uri')).toBe(arguments.relocate_uri);
        }
        else {
            expect(response.getStatusCode()).toBe(200);
            expect(event.getValue('relocate_uri')).toBe(arguments.relocate_uri);
        }

        // Force the session rotate to work
        execute(route = '/', renderResults = true);

        // Verify session data
        expect(session.trainerid).toBe(arguments.trainer.getId());
        expect(session.securityLevel).toBe(arguments.trainer.getSecurityLevel());
        expect(session.authenticated).toBeTrue();
        expect(session.verified).toBeTrue();
        expect(session.securityLevel).toBeGTE(10);
    }

    /**
     * Log out the mock trainer
     */
    void function logout() {
        temp  = session.mocktrainerid;
        event = get(route = '/logout');
        expect(event.getResponse().getStatusCode()).toBe(200);
        expect(event.getValue('relocate_URI')).toBe('/'); // home page

        // session deleted
        expect(session).notToHaveKey('trainerid');

        // Force the session rotate to work
        execute(route = '/', renderResults = true);

        expect(session.trainerid).toBe(-1);
        expect(session.authenticated).toBeFalse();
        expect(session.verified).toBeFalse();
        expect(session.securityLevel).toBe(0);

        session.mocktrainerid = temp;
    }

    string function makeFriendcode() {
        return '#left(randRange(1, 999999999999) & '00000000000', 12)#';
    }

}
