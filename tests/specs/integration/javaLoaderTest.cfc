component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Test Jsoup functions', () => {
            beforeEach(() => {
                setup();
                jsoup = getInstance('javaloader:org.jsoup.Jsoup');
            });

            it('Can load jsoup', () => {
                expect(jsoup).notToBeNull();
            });

            it('Can load /healthcheck with jsoup', () => {
                var event = get(route = '/healthcheck');
                expect(isJSON(event.getRenderedContent())).toBeTrue();
                var renderedJson = deserializeJSON(event.getRenderedContent());
                expect(renderedJson.data).toBe('Ok!');

                // Jsoup is not primarily for json responses - just check that the needle exists
                var jsoupTest = jsoup
                    .connect(event.route('/healthcheck').replace('/app', ''))
                    .ignoreContentType(true)
                    .get();
                expect(jsoupTest.text()).toInclude('Ok!');
            });

            it('Can get a user agent', () => {
                session.securityLevel = 60;

                var event    = execute(event = 'dev.testJsoup', renderResults = true);
                var response = event.getPrivateValue('cbox_renderdata');

                expect(response.statusCode).toBe(200);
                expect(isJSON(response.data.response)).toBeTrue();

                var data = deserializeJSON(response.data.response);
                expect(data['user-agent']).toInclude('Mozilla/5.0');

                session.securityLevel = 0;
            });
        });
    }

}



