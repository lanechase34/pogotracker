component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        cache       = getInstance("cachebox:appCache");
        blogService = getInstance("services.blog");

        fakeEvents = [];
        for(var i = 1; i <= 5; i++) {
            fakeEvents.append({
                type         : "Event",
                title        : "Fake Event #i#",
                timestamp    : "",
                link         : "https://leekduck.com/events/fake-event-#i#/",
                datatimestamp: now()
            });
        }

        fakeNews = [];
        for(var i = 1; i <= 4; i++) {
            fakeNews.append({
                link  : "https://pokemongo.com/en/news/fake-#i#",
                img   : "",
                date  : now(),
                header: "Fake News #i#"
            });
        }
    }

    function afterAll() {
        super.afterAll();
        clearExternalCache(); // Real data is re-scraped on next use
    }

    function run() {
        describe("Blog service - external news/events cache", () => {
            beforeEach(() => {
                setup();
                cache.set(
                    "external.events.list",
                    duplicate(fakeEvents),
                    10,
                    10
                );
                cache.set(
                    "external.news.list",
                    duplicate(fakeNews),
                    10,
                    10
                );
                // Even numbered fake events are location specific
                fakeEvents.each((event, index) => {
                    cache.set(
                        "external.events.locationSpecific|link=#event.link#",
                        index % 2 == 0,
                        720,
                        720
                    );
                });
            });

            it("Slices a page of events and attaches the location specific flag", () => {
                var events = blogService.getEvents(count = 2, offset = 1);

                expect(events.len()).toBe(2);
                expect(events[1].title).toBe("Fake Event 2");
                expect(events[2].title).toBe("Fake Event 3");
                expect(events[1].locationSpecific).toBeTrue();
                expect(events[2].locationSpecific).toBeFalse();
            });

            it("Does not modify the cached event list", () => {
                blogService.getEvents(count = 5, offset = 0);

                cache
                    .get("external.events.list")
                    .each((event) => {
                        expect(event).notToHaveKey("locationSpecific");
                    });
            });

            it("Returns a short last page and an empty page past the end", () => {
                expect(blogService.getEvents(count = 10, offset = 3).len()).toBe(2);
                expect(blogService.getEvents(count = 5, offset = 5)).toBe([]);
                expect(blogService.getEvents(count = 5, offset = 10)).toBe([]);
            });

            it("Slices a page of news", () => {
                var news = blogService.getNews(count = 2, offset = 2);

                expect(news.len()).toBe(2);
                expect(news[1].header).toBe("Fake News 3");
                expect(news[2].header).toBe("Fake News 4");
                expect(blogService.getNews(count = 2, offset = 4)).toBe([]);
            });

            it("Survives the cache clear done when a blog post is created/edited", () => {
                cache.clearByKeySnippet("blog.");

                expect(cache.get("external.events.list")).notToBeNull();
                expect(cache.get("external.news.list")).notToBeNull();
                expect(cache.get("external.events.locationSpecific|link=#fakeEvents[1].link#")).notToBeNull();
            });
        });
    }

    private void function clearExternalCache() {
        cache.clear("external.events.list");
        cache.clear("external.news.list");
        fakeEvents.each((event) => {
            cache.clear("external.events.locationSpecific|link=#event.link#");
        });
    }

}
