component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");
        developer   = mockTrainer.make(securityLevel = 60, autoLogin = false);
    }

    function afterAll() {
        mockTrainer.deleteTrainer(developer.id);
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

        describe("Live leekduck markup", () => {
            beforeEach(() => {
                setup();
                jsoup          = getInstance("javaloader:org.jsoup.Jsoup");
                scraperService = getInstance("services.scraper");
            });

            it("Still renders the upcoming events list blogService.getEventList reads", () => {
                var posts = scraperService
                    .getData("https://leekduck.com/events/")
                    .body()
                    .select("div.upcoming-events")
                    .select("span.event-header-item-wrapper");
                expect(posts.size()).toBeGT(
                    0,
                    "No div.upcoming-events span.event-header-item-wrapper on leekduck.com/events/"
                );

                var post = posts.first();
                expect(post.attr("data-event-date-sort")).notToBeEmpty();
                expect(post.select("a").attr("href")).toInclude("/events/");
                expect(
                    post.select("a")
                        .select("div.event-item-wrapper")
                        .select("p")
                        .text()
                ).notToBeEmpty("Event type (div.event-item-wrapper p) missing");
                expect(
                    post.select("a")
                        .select("div.event-item-wrapper")
                        .select("div.event-item")
                        .select("div.event-text-container")
                        .select("div.event-text")
                        .select("h2")
                        .text()
                ).notToBeEmpty("Event title (div.event-text h2) missing");
            });

            it("Still renders an event page the way the createEventTest fixture has it", () => {
                // A past event, so its content is fixed - any difference is a markup change and the fixtures need refetching
                var slug    = "june-communityday2026";
                var link    = "https://leekduck.com/events/#slug#/";
                var fixture = jsoup
                    .parse(fileRead(expandPath("/tests/resources/fixtures/leekduck/#slug#.html"), "utf-8"), link)
                    .body();
                var live = scraperService.getData(link).body();

                expect(live.select("h1.page-title").text()).toBe(fixture.select("h1.page-title").text());
                expect(live.select("ul.pkmn-list-flex").size()).toBeGT(0, "No ul.pkmn-list-flex on #link#");

                var spawnNames = (doc) => {
                    var names = [];
                    doc.select(".pkmn-list-item")
                        .select(".pkmn-name")
                        .each((element) => names.append(element.text()));
                    return names;
                };
                var liveSpawns = spawnNames(live);
                expect(liveSpawns).notToBeEmpty("No .pkmn-list-item .pkmn-name on #link#");
                expect(liveSpawns).toBe(spawnNames(fixture));

                var scheduleRows = (doc) => {
                    var starts = [];
                    doc.select("div.schedule-row[data-start]")
                        .each((element) => starts.append(element.attr("data-start")));
                    return starts;
                };
                var liveRows = scheduleRows(live);
                expect(liveRows).notToBeEmpty("No div.schedule-row[data-start] on #link#");
                expect(liveRows).toBe(scheduleRows(fixture));
            });
        });
    }

}



