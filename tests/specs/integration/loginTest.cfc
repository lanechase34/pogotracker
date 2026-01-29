component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();

        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists('mocktrainerid')) mockTrainer.delete();
    }

    function run() {
        describe('Login handler tests', () => {
            beforeEach(() => {
                setup();

                securityService = getInstance('services.security');
                sessionService  = getInstance('services.session');
            });

            it('Authenticate with a valid email/password and receive a session', () => {
                email    = 'lanechase34@outlook.com';
                password = createUUID();

                login = securityService.login(email, password);
                expect(login).toBeTrue();

                sessionService.create(email, false);
                execute(event = 'home.home', renderResults = true); // Force the session rotate to work

                expect(session.authenticated).toBeTrue();
                sessionService.destroy(false);
                expect(session.keyExists('trainerid')).toBeFalse();
            });

            it('Can rotate a session and retrieve new sessionid', () => {
                trainer   = mockTrainer.make();
                trainerid = session.trainerid;
                sessionid = session.sessionid;

                sessionService.rotate();
                execute(event = 'home.home', renderResults = true); // Force the session rotate to work

                expect(trainerid).toBe(session.trainerid);
                expect(sessionid).notToBe(session.sessionid); // sessionid should rotate
                mockTrainer.delete();
            });

            describe('Registration -> Login lifecycle', () => {
                it('Can get the login form', () => {
                    event = get(route = '/login');
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude('data-handler=login');
                    expect(event.getRenderedContent()).toInclude('data-action=loginform');
                });

                it('Can register a new user', () => {
                    // Force valid recaptcha
                    session.recaptcha = {
                        token    : 'a',
                        valid    : true,
                        timestamp: now(),
                        action   : 'register'
                    };

                    // Mock user
                    username     = left(replace('register_#createUUID()#', '-', '', 'all'), 30);
                    testingEmail = '#username#@gmail.com'; // used in subsequent tests

                    event = post(
                        route  = '/login/register',
                        params = {
                            '#application.cbController.getSetting('csrfTokenField')#': csrfGenerateToken(
                                forceNew = true
                            ),
                            username  : username,
                            password  : createUUID(),
                            email     : testingEmail,
                            friendcode: mockTrainer.makeFriendcode(),
                            icon      : 'mudkip'
                        }
                    );

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue('relocate_URI')).toBe('/verify');

                    // Force the session rotate to work
                    execute(route = '/', renderResults = true);

                    expect(session.trainerid).toBeGT(0);
                    expect(session.securityLevel).toBe(5); // unverified trainer
                    expect(session.authenticated).toBeTrue();
                    expect(session.verified).toBeFalse();
                });

                it('Can verify a new user', () => {
                    before = globalFunctions.countTestEmails();

                    // Send verification code
                    event = get(route = '/verify', renderResults = true);
                    expect(event.getResponse().getStatusCode()).toBe(200);

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);

                    // Read most recent email to get the code
                    email = globalFunctions.readEmail();
                    code  = email.select('##verificationCode').text();

                    // Mock submitting verification code
                    event = post(
                        route  = '/login/verify',
                        params = {
                            '#application.cbController.getSetting('csrfTokenField')#': csrfGenerateToken(
                                forceNew = true
                            ),
                            code: code
                        }
                    );

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue('relocate_URI')).toBe('/'); // home page

                    // Verify session
                    expect(session.securityLevel).toBe(10); // Regular Trainer
                    expect(session.authenticated).toBeTrue();
                    expect(session.verified).toBeTrue();

                    sleep(4000);
                });

                it('User can log out', () => {
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
                });

                it('Can get to forgot password form', () => {
                    event = get(route = '/forgot');
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude('data-handler=login');
                    expect(event.getRenderedContent()).toInclude('data-action=forgotpasswordform');
                });

                it('Can request a reset password email and reset password', () => {
                    before = globalFunctions.countTestEmails();

                    event = post(
                        route  = '/login/forgotPassword',
                        params = {
                            '#application.cbController.getSetting('csrfTokenField')#': csrfGenerateToken(
                                forceNew = true
                            ),
                            email: testingEmail
                        }
                    );

                    expect(globalFunctions.countTestEmails()).toBe(before + 1);

                    email = globalFunctions.readEmail();
                    link  = email.select('##resetLink').attr('href');

                    uri  = right(link, link.len() - link.find('8081') - 3);
                    code = right(uri, uri.len() - 7);

                    // Get the reset password form using the link emailed
                    event = get(route = uri, params = {});
                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getRenderedContent()).toInclude('data-handler=login');
                    expect(event.getRenderedContent()).toInclude('data-action=resetpasswordform');

                    // Reset the password
                    event = post(
                        route  = '/login/resetPassword',
                        params = {
                            '#application.cbController.getSetting('csrfTokenField')#': csrfGenerateToken(
                                forceNew = true
                            ),
                            resetCode: code,
                            password : createUUID()
                        }
                    );

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(event.getValue('relocate_URI')).toBe('/login'); // login form
                    expect(session).toHaveKey('alert');
                    expect(session.alert.message).toBe('Successfully reset password.');

                    expect(session.trainerid).toBe(-1);
                    expect(session.authenticated).toBeFalse();
                    expect(session.verified).toBeFalse();
                });
            });

            afterEach(() => {
                if(session.keyExists('mocktrainerid')) mockTrainer.delete();
            });
        });
    }

}
