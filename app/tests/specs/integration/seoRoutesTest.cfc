component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        domain   = getController().getSetting("domain");
        siteName = getController().getSetting("siteName");
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Run a request as an anonymous visitor
     */
    private any function anonymousGet(required string route) {
        setup();
        getInstance("authenticationService@cbauth").logout();
        return get(route = route);
    }

    /**
     * Pull the JSON-LD block out of rendered html and parse it, failing when it is missing or invalid
     */
    private struct function getJsonLd(required string html) {
        var match = reFind(
            "<script type=""application/ld\+json"">([\s\S]*?)<\/script>",
            html,
            1,
            true
        );
        expect(match.pos[1]).toBeGT(0, "No JSON-LD script block was rendered");

        var json = mid(html, match.pos[2], match.len[2]);
        expect(isJSON(json)).toBeTrue("JSON-LD is not valid JSON: #left(json, 500)#");
        return deserializeJSON(json);
    }

    private array function getGraphTypes(required struct jsonLd) {
        return jsonLd["@graph"].map((node) => node["@type"]);
    }

    private struct function getGraphNode(required struct jsonLd, required string type) {
        var nodes = jsonLd["@graph"].filter((node) => node["@type"] == type);
        expect(nodes).toHaveLength(1, "Expected exactly one #type# node");
        return nodes[1];
    }

    function run() {
        describe("GET /pokemon (Pokedex index)", () => {
            it("Is public - anonymous visitors get a 200, not a login redirect", () => {
                var event = anonymousGet("/pokemon");
                expect(event.getStatusCode()).toBe(200);
                expect(event.getCurrentEvent()).toBe("pokemon.index");
                expect(event.getValue("relocate_URI", "")).toBe("");
            });

            it("Renders a crawlable list of links to detail pages", () => {
                var html = anonymousGet("/pokemon").getRenderedContent();
                expect(html).toInclude("<h1 class=""pokedex-hero-title mb-0"">Pokémon GO Database</h1>");
                // Detail links are server rendered as plain anchors, so crawlers can follow them without JS
                expect(html).toInclude("href=""/pokemon/1""");
                expect(reFind("<a class=""pokedex-entry"" href=""/pokemon/[^""]+""", html)).toBeGT(0);
            });

            it("Has its own title, description, and canonical", () => {
                var event = anonymousGet("/pokemon");
                var html  = event.getRenderedContent();
                expect(event.getPrivateValue("title")).toInclude("Database");
                expect(event.getPrivateValue("title")).toInclude("| #siteName#");
                expect(event.getPrivateValue("metaDescription")).notToBeEmpty();
                expect(html).toInclude("<link rel=""canonical"" href=""#domain#/pokemon"">");
                expect(html).toInclude("<meta name=""robots"" content=""index, follow"">");
            });

            it("Has CollectionPage and BreadcrumbList structured data", () => {
                var jsonLd = getJsonLd(anonymousGet("/pokemon").getRenderedContent());
                expect(getGraphTypes(jsonLd)).toInclude("CollectionPage");
                expect(getGraphTypes(jsonLd)).toInclude("BreadcrumbList");
                expect(getGraphNode(jsonLd, "CollectionPage")["@id"]).toBe("#domain#/pokemon");
            });
        });

        describe("GET /home", () => {
            it("Permanently redirects to /", () => {
                var event = anonymousGet("/home");
                expect(event.getValue("relocate_URI")).toBe("/");
                expect(event.getValue("relocate_statusCode")).toBe(301);
            });
        });

        describe("GET / (home page)", () => {
            it("Has a visible h1 instead of the hidden fallback", () => {
                var html = anonymousGet("/").getRenderedContent();
                expect(html).toInclude("<h1 class=""home-hero-title");
                expect(html).notToInclude("<h1 class=""visually-hidden"">");
                expect(reMatch("<h1[\s>]", html)).toHaveLength(1);
            });

            it("Has crawlable links to the Pokedex and registration", () => {
                var html = anonymousGet("/").getRenderedContent();
                expect(html).toInclude("href=""/pokemon""");
                expect(html).toInclude("href=""/register""");
            });

            it("Canonical is always the root url", () => {
                var html = anonymousGet("/").getRenderedContent();
                expect(html).toInclude("<link rel=""canonical"" href=""#domain#/"">");
            });

            it("Has valid site wide structured data with an unescaped description", () => {
                var jsonLd = getJsonLd(anonymousGet("/").getRenderedContent());
                expect(getGraphTypes(jsonLd)).toBe(["WebSite", "WebApplication"]);
                expect(getGraphNode(jsonLd, "WebApplication").description).toBe(
                    getController().getSetting("metaDescription")
                );
            });
        });

        describe("GET /pokemon/1 (Bulbasaur detail page)", () => {
            it("Title leads with the name and uses the short site name", () => {
                var event = anonymousGet("/pokemon/1");
                expect(event.getPrivateValue("title")).toBe("Bulbasaur - Pokémon GO Max CP, Moves & Stats | #siteName#");
            });

            it("Meta description includes real stats", () => {
                var event = anonymousGet("/pokemon/1");
                expect(event.getPrivateValue("metaDescription")).toInclude("118 ATK / 111 DEF / 128 HP");
            });

            it("Keeps the default share image (sprites are too small for social cards)", () => {
                var event = anonymousGet("/pokemon/1");
                expect(event.privateValueExists("ogImage")).toBeFalse();
                expect(event.getRenderedContent()).toInclude("og-default.png");
            });

            it("Has a visible breadcrumb back to the Pokedex", () => {
                var html = anonymousGet("/pokemon/1").getRenderedContent();
                expect(html).toInclude("<nav aria-label=""Breadcrumb"">");
                expect(html).toInclude(
                    "<a href=""/pokemon""><i class=""bi bi-grid-3x3-gap-fill"" aria-hidden=""true""></i>Pokédex</a>"
                );
            });

            it("Has WebPage and BreadcrumbList structured data", () => {
                var jsonLd = getJsonLd(anonymousGet("/pokemon/1").getRenderedContent());
                expect(getGraphTypes(jsonLd)).toInclude("WebPage");

                var page = getGraphNode(jsonLd, "WebPage");
                expect(page["@id"]).toBe("#domain#/pokemon/1");
                expect(page.name).toBe("Bulbasaur");
                expect(page.primaryImageOfPage.contentUrl).toInclude("/includes/images/sprites/");

                var crumb = getGraphNode(jsonLd, "BreadcrumbList");
                expect(crumb.itemListElement.map((item) => item.name)).toBe(["Home", "Pokédex", "Bulbasaur"]);
                expect(crumb.itemListElement.map((item) => item.position)).toBe([1, 2, 3]);
            });
        });

        describe("GET /readblog/:blogheader", () => {
            /**
             * A blog whose header round trips through the url (hyphens in a header can't be read back)
             */
            var getTestBlogHeader = () => {
                var blog = queryExecute(
                    "select header from blog where header not like '%-%' order by id asc",
                    {},
                    {maxrows: 1}
                );
                return blog.recordCount ? blog.header : "";
            };

            it("Uses the short site name in the title", () => {
                var header = getTestBlogHeader();
                if(!header.len()) return;

                var event = anonymousGet("/readblog/#header.replace(" ", "-", "all")#");
                expect(event.getStatusCode()).toBe(200);
                expect(event.getPrivateValue("title")).toBe("#header# | #siteName#");
            });

            it("Has BlogPosting structured data", () => {
                var header = getTestBlogHeader();
                if(!header.len()) return;

                var slug   = header.replace(" ", "-", "all");
                var jsonLd = getJsonLd(anonymousGet("/readblog/#slug#").getRenderedContent());
                expect(getGraphTypes(jsonLd)).toInclude("BlogPosting");
                expect(getGraphTypes(jsonLd)).toInclude("BreadcrumbList");

                var posting = getGraphNode(jsonLd, "BlogPosting");
                expect(posting.headline).toBe(left(header, 110));
                expect(posting.mainEntityOfPage).toBe("#domain#/readblog/#slug#");
                expect(posting).toHaveKey("datePublished");
                expect(posting).toHaveKey("author");
            });

            it("Canonical keeps the stored header's casing", () => {
                var header = getTestBlogHeader();
                if(!header.len()) return;

                var slug = header.replace(" ", "-", "all");
                var html = anonymousGet("/readblog/#slug#").getRenderedContent();
                expect(html).toInclude("<link rel=""canonical"" href=""#encodeForHTMLAttribute("#domain#/readblog/#slug#")#"">");
            });

            it("Permanently redirects any other casing to the stored header's slug", () => {
                var header = getTestBlogHeader();
                var slug   = header.replace(" ", "-", "all");
                // Needs a header with letters whose case can change
                if(!header.len() || compare(lCase(slug), slug) == 0) return;

                // Warm the cache with the correct url first - the cache key is case insensitive
                anonymousGet("/readblog/#slug#");
                var event = anonymousGet("/readblog/#lCase(slug)#");
                expect(event.getValue("relocate_URI")).toBe("/readblog/#slug#");
                expect(event.getValue("relocate_statusCode")).toBe(301);
            });
        });
    }

}
