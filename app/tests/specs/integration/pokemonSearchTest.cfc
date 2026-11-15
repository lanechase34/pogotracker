component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("GET /pokemon/search", () => {
            beforeEach(() => {
                setup();
            });

            describe("Valid requests", () => {
                it("Searching 'Bulbasaur' returns a 200 success envelope of results with id, text, image, alt, and a non-empty ses", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "Bulbasaur", page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    expect(response.success).toBeTrue();

                    expect(response).toHaveKey("data");
                    expect(response.data).toHaveKey("results");
                    expect(response.data).toHaveKey("pagination");
                    expect(response.data.results).toBeArray();
                    expect(response.data.pagination).toHaveKey("more");

                    expect(response.data.results.len()).toBeGT(0);
                    var matched = response.data.results.filter((r) => r.text == "Bulbasaur");
                    expect(matched.len()).toBe(1);

                    var entry = response.data.results[1];
                    expect(entry).toHaveKey("id");
                    expect(entry).toHaveKey("text");
                    expect(entry).toHaveKey("image");
                    expect(entry).toHaveKey("alt");
                    expect(entry).toHaveKey("ses");

                    // ses is needed for client-side navigation
                    response.data.results.each((r) => {
                        expect(r.ses.len()).toBeGT(0);
                    });
                });

                it("Searching a nonexistent name returns 200 with an empty results array and more:false", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "NotARealPokemon", page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    expect(response.success).toBeTrue();
                    expect(response.data.results.len()).toBe(0);
                    expect(response.data.pagination.more).toBeFalse();
                });

                it("Generic term 'a' returns a full first page (20 results) with more:true", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "a", page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    expect(response.data.results.len()).toBe(20);
                    expect(response.data.pagination.more).toBeTrue();
                });

                it("Page 2 of 'a' search returns results that do not overlap with page 1", () => {
                    var result1 = deserializeJSON(
                        get(route = "/pokemon/search", params = {search: "a", page: 1}).getRenderedContent()
                    );
                    setup();

                    var event2  = get(route = "/pokemon/search", params = {search: "a", page: 2});
                    var result2 = deserializeJSON(event2.getRenderedContent());
                    expect(event2.getStatusCode()).toBe(200);
                    expect(result2.data.results.len()).toBeGT(0);

                    var ids1    = result1.data.results.map((r) => r.id);
                    var overlap = result2.data.results.filter((r) => ids1.contains(r.id));
                    expect(overlap.len()).toBe(0);
                });

                it("Search is case-insensitive - 'CHARIZARD' finds Charizard", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "CHARIZARD", page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    var matched = response.data.results.filter((r) => r.text == "Charizard");
                    expect(matched.len()).toBe(1);
                });

                it("Mid-string search 'saur' returns Bulbasaur, Ivysaur, and Venusaur", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "saur", page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    var names = response.data.results.map((r) => r.text);
                    expect(names.find("Bulbasaur")).toBeGT(0);
                    expect(names.find("Ivysaur")).toBeGT(0);
                    expect(names.find("Venusaur")).toBeGT(0);
                });

                it("Out-of-bounds page returns 200 with empty results and more:false", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "Bulbasaur", page: 9999});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    expect(response.data.results.len()).toBe(0);
                    expect(response.data.pagination.more).toBeFalse();
                });

                it("Omitting search param (defaults to empty) returns a 200 with results", () => {
                    // search is optional - missing it should not trigger a 400
                    var event    = get(route = "/pokemon/search", params = {page: 1});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(200);
                    expect(response.success).toBeTrue();
                    expect(response.data.results).toBeArray();
                });
            });

            describe("Invalid requests", () => {
                it("Missing page param returns 400 with the error message", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "Bulbasaur"});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(400);
                    expect(response.success).toBeFalse();
                    expect(response).toHaveKey("message");
                    expect(response.message.len()).toBeGT(0);
                });

                it("Non-numeric page returns 400", () => {
                    var event    = get(route = "/pokemon/search", params = {search: "Bulbasaur", page: "notanumber"});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(400);
                    expect(response.success).toBeFalse();
                });

                it("Missing both search and page returns 400", () => {
                    var event    = get(route = "/pokemon/search", params = {});
                    var response = deserializeJSON(event.getRenderedContent());
                    expect(event.getStatusCode()).toBe(400);
                    expect(response.success).toBeFalse();
                });

                it("POST to the search endpoint returns 405 Method Not Allowed", () => {
                    var event = post(route = "/pokemon/search", params = {search: "Bulbasaur", page: 1});
                    expect(event.getStatusCode()).toBe(405);
                });
            });
        });
    }

}
