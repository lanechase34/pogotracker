component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function afterAll() {
        super.afterAll();
        if(session.keyExists('mocktrainerid')) mockTrainer.delete();
    }

    function run() {
        describe('Verify security', () => {
            beforeEach(() => {
                setup();
                securityService = getInstance('services.security');

                // New session for each test
                session.clear();
                event = execute('main.onSessionStart');
            });

            it('Can be cretaed', () => {
                expect(securityService).toBeComponent();
                expect(securityService.getSecurityMap()).toBeStruct();
            });

            describe('Security level tests', () => {
                it('Unregistered user can access the home page', () => {
                    event           = execute(event = 'home.home', renderResults = true);
                    renderedContent = event.getRenderedContent();

                    expect(event.getResponse().getStatusCode()).toBe(200);
                    expect(renderedContent).toInclude('data-handler=home');
                    expect(renderedContent).toInclude('data-action=home');
                });

                it('Unregistered user cannot access pokedex - gets redirected to the login page', () => {
                    // Simulate user clicking pokedex nav on side bar
                    event = execute(route = '/mypokedex');

                    expect(event.getValue('event')).toBe('pokedex.myPokedex');
                    // Relocated to login page
                    expect(event.getValue('relocate_uri')).toBe('/login');
                    // Session updated with the linked event
                    expect(session.linkedEvent).toBe('/mypokedex');
                });

                it('A regular user cannot access admin', () => {
                    // Log in as a regular user
                    regularTrainer = mockTrainer.make(securityLevel = 10);
                    mockTrainer.login(regularTrainer);

                    // Attempt to visit admin page
                    event = execute(route = '/admin');

                    // This was interrupted and the unauthorized handler was fired
                    expect(event.getValue('event')).toBe('error.unauthorized');

                    // Tracked unauthorized event
                    expect(event.getPrivateValue('unauthorizedEvent')).toBe('admin.index');
                });
            });

            afterEach(() => {
                if(session.keyExists('mocktrainerid')) mockTrainer.delete();
            });
        });
    }

}
