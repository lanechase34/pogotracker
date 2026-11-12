component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mocktrainer");
        developer   = mockTrainer.make(securityLevel = 60, autoLogin = false);
    }

    function afterAll() {
        mockTrainer.delete(developer.getId());
        super.afterAll();
    }

    function run() {
        describe("Test Jsoup functions", () => {
            beforeEach(() => {
                setup();
                jsoup = getInstance("javaloader:org.jsoup.Jsoup");
            });

            it("Can load /healthcheck with jsoup", () => {
                var event = get(route = "/healthcheck");
                expect(isJSON(event.getRenderedContent())).toBeTrue();
                var renderedJson = deserializeJSON(event.getRenderedContent());
                expect(renderedJson.data).toBe("Ok!");

                // Jsoup is not primarily for json responses - just check that the needle exists
                var jsoupTest = jsoup
                    .connect(event.route("/healthcheck").replace("/root", ""))
                    .ignoreContentType(true)
                    .ignoreHttpErrors(true)
                    .execute();
                expect(jsoupTest.body()).toInclude(
                    "Ok!",
                    "Live /healthcheck returned HTTP #jsoupTest.statusCode()# from #jsoupTest.url().toString()#: #jsoupTest.body()#"
                );
            });

            it("Can get a user agent", () => {
                mockTrainer.actAs(developer);

                var event    = execute(event = "dev.testJsoup", renderResults = true);
                var response = event.getPrivateValue("cbox_renderdata");

                expect(response.statusCode).toBe(200);
                expect(isJSON(response.data.response)).toBeTrue();

                var data = deserializeJSON(response.data.response);
                expect(data["user-agent"]).toInclude("Mozilla/5.0");

                mockTrainer.actAsGuest();
            });
        });
    }

}



