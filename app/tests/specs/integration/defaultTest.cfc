component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Default Behaviors', () => {
            beforeEach(() => {
                setup(); // Setup as a new ColdBox request
            });

            it('Ping database', () => {
                var sysdate = queryExecute('select current_timestamp').current_timestamp;
                expect(dateDiff('s', now(), sysdate)).toBeBetween(0, 5);
            });

            describe('Request Events', () => {
                it('Fires on start', () => {
                    var event = execute('main.onRequestStart');
                });

                it('Fires on end', () => {
                    var event = execute('main.onRequestEnd');
                });
            });

            describe('Session events', () => {
                it('Fires on start', () => {
                    var event = execute('main.onSessionStart');
                    expect(session.trainerid).toBe(-1);
                    expect(session.securityLevel).toBe(0);
                    expect(session.authenticated).toBeFalse();
                });
            });

            describe('Test addition', () => {
                it('Can add two numbers', () => {
                    expect(sum(1, 2)).toBe(3);
                });

                it('Can add two negative numbers', () => {
                    expect(sum(-1, -2)).toBe(-3);
                });
            });

            it('Can handle exceptions', () => {
                var chase;
                try {
                    var test = 1 / 0;
                }
                catch(any e) {
                    chase = e;
                }

                // You need to create an exception bean first and place it on the request context FIRST as a setup.
                var exceptionBean = createMock('coldbox.system.web.context.ExceptionBean').init(
                    errorStruct  = chase,
                    extraMessage = 'My unit test exception',
                    extraInfo    = 'Any extra info, simple or complex'
                );

                prepareMock(getRequestContext())
                    .setValue(
                        name    = 'exception',
                        value   = exceptionBean,
                        private = true
                    )
                    .setValue(
                        name    = 'currentRoutedURL',
                        value   = 'test.defaultTest',
                        private = true
                    )
                    .$('setHTTPHeader');

                // Verify bug is successfully logged
                var bugCountBefore = globalFunctions.countBugLog();

                var event1 = execute(event = 'error.onException'); // logs bug and emails bug
                var event2 = execute(event = 'error.displayException', renderResults = true); // generic error display only
                expect(event2.getRenderedContent()).toInclude('Something Went Wrong');

                var bugCountAfter = globalFunctions.countBugLog();
                expect(bugCountAfter - bugCountBefore).toBe(1);
            });
        });
    }

    private function sum(a, b) {
        return a + b;
    }

}
