component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        seoService = getInstance("services.seo");
        domain     = getController().getSetting("domain");
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Serialize through the service and parse it back, failing if the output is not valid JSON
     */
    private struct function roundTrip(required struct data) {
        var json = seoService.toJsonLd(data);
        expect(isJSON(json)).toBeTrue("toJsonLd output is not valid JSON: #json#");
        return deserializeJSON(json);
    }

    private array function getGraphTypes(required struct parsed) {
        return parsed["@graph"].map((node) => node["@type"]);
    }

    private struct function getGraphNode(required struct parsed, required string type) {
        var nodes = parsed["@graph"].filter((node) => node["@type"] == type);
        expect(nodes).toHaveLength(1, "Expected exactly one #type# node");
        return nodes[1];
    }

    function run() {
        describe("SEO Service", () => {
            describe("toJsonLd", () => {
                it("Produces valid JSON", () => {
                    var parsed = roundTrip({"name": "Pokémon GO ""quoted"" & <b>tags</b>"});
                    expect(parsed.name).toBe("Pokémon GO ""quoted"" & <b>tags</b>");
                });

                it("Escapes closing tag sequences so the script block cannot be closed early", () => {
                    var json = seoService.toJsonLd({"name": "evil</script><script>alert(1)"});
                    expect(json).notToInclude("</");
                    expect(json).toInclude("<\/script>");

                    // The escape is transparent to JSON parsers
                    expect(deserializeJSON(json).name).toBe("evil</script><script>alert(1)");
                });

                it("Preserves the exact case of schema.org keys", () => {
                    var json = seoService.toJsonLd(seoService.getSiteGraph());
                    expect(json).toIncludeWithCase("""@context""");
                    expect(json).toIncludeWithCase("""@graph""");
                    expect(json).toIncludeWithCase("""applicationCategory""");
                    expect(json).toIncludeWithCase("""alternateName""");
                });
            });

            describe("getSiteGraph", () => {
                it("Contains the WebSite and WebApplication nodes", () => {
                    var parsed = roundTrip(seoService.getSiteGraph());
                    expect(parsed["@context"]).toBe("https://schema.org");
                    expect(getGraphTypes(parsed)).toBe(["WebSite", "WebApplication"]);
                });

                it("Keeps the meta description intact (no javascript escapes)", () => {
                    var parsed = roundTrip(seoService.getSiteGraph());
                    var app    = getGraphNode(parsed, "WebApplication");
                    expect(app.description).toBe(getController().getSetting("metaDescription"));
                    expect(app.description).notToInclude("\x");
                });
            });

            describe("getBreadcrumb", () => {
                it("Numbers list items from 1 in order", () => {
                    var crumb = roundTrip(
                        seoService.getBreadcrumb(
                            id    = "#domain#/pokemon/1##breadcrumb",
                            items = [
                                {name: "Home", url: "#domain#/"},
                                {name: "Pokédex", url: "#domain#/pokemon"},
                                {name: "Bulbasaur", url: "#domain#/pokemon/1"}
                            ]
                        )
                    );

                    expect(crumb["@type"]).toBe("BreadcrumbList");
                    expect(crumb["@id"]).toBe("#domain#/pokemon/1##breadcrumb");
                    expect(crumb.itemListElement).toHaveLength(3);
                    expect(crumb.itemListElement.map((item) => item.position)).toBe([1, 2, 3]);
                    expect(crumb.itemListElement.map((item) => item.name)).toBe(["Home", "Pokédex", "Bulbasaur"]);
                    expect(crumb.itemListElement[3].item).toBe("#domain#/pokemon/1");
                });
            });

            describe("getPokemonDetail", () => {
                it("Builds a WebPage with the sprite and a 3 level breadcrumb", () => {
                    var pageURL = "#domain#/pokemon/1";
                    var parsed  = roundTrip(
                        seoService.getPokemonDetail(
                            name        = "Bulbasaur",
                            description = "Bulbasaur description",
                            pageURL     = pageURL,
                            image       = "#domain#/includes/images/sprites/1.webp"
                        )
                    );

                    expect(getGraphTypes(parsed)).toBe(["WebPage", "BreadcrumbList", "WebSite"]);

                    var page = getGraphNode(parsed, "WebPage");
                    expect(page["@id"]).toBe(pageURL);
                    expect(page.name).toBe("Bulbasaur");
                    expect(page.primaryImageOfPage.contentUrl).toBe("#domain#/includes/images/sprites/1.webp");
                    expect(page.breadcrumb["@id"]).toBe("#pageURL###breadcrumb");

                    var crumb = getGraphNode(parsed, "BreadcrumbList");
                    expect(crumb.itemListElement.map((item) => item.item)).toBe(["#domain#/", "#domain#/pokemon", pageURL]);
                });
            });

            describe("getPokedexIndex", () => {
                it("Builds a CollectionPage with a 2 level breadcrumb", () => {
                    var pageURL = "#domain#/pokemon";
                    var parsed  = roundTrip(
                        seoService.getPokedexIndex(
                            name        = "Pokémon GO Database",
                            description = "All pokemon",
                            pageURL     = pageURL
                        )
                    );

                    expect(getGraphTypes(parsed)).toBe(["CollectionPage", "BreadcrumbList", "WebSite"]);
                    expect(getGraphNode(parsed, "CollectionPage")["@id"]).toBe(pageURL);
                    expect(getGraphNode(parsed, "BreadcrumbList").itemListElement).toHaveLength(2);
                });
            });

            describe("getBlogPosting", () => {
                var isoPattern = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$";

                it("Builds a BlogPosting with ISO 8601 dates from a saved blog", () => {
                    var blogs = entityLoad("blog", {}, "id asc", {maxresults: 1});
                    expect(blogs).notToBeEmpty("Test data needs at least one blog");
                    var blog = blogs[1];

                    var pageURL = "#domain#/readblog/#blog.getHeader().replace(" ", "-", "all")#";
                    var parsed  = roundTrip(seoService.getBlogPosting(blog = blog, pageURL = pageURL));

                    expect(getGraphTypes(parsed)).toBe([
                        "BlogPosting",
                        "BreadcrumbList",
                        "Organization",
                        "WebSite"
                    ]);

                    var posting = getGraphNode(parsed, "BlogPosting");
                    expect(posting.headline).toBe(left(blog.getHeader(), 110));
                    expect(posting.mainEntityOfPage).toBe(pageURL);
                    expect(posting.image).toBe(blog.getOgImage());
                    expect(reFind(isoPattern, posting.datePublished)).toBeGT(
                        0,
                        "datePublished is not ISO 8601: #posting.datePublished#"
                    );
                    expect(reFind(isoPattern, posting.dateModified)).toBeGT(
                        0,
                        "dateModified is not ISO 8601: #posting.dateModified#"
                    );
                    expect(posting).toHaveKey("author");
                    expect(posting.publisher["@id"]).toBe("#domain#/##organization");
                });

                it("Does not throw for a blog without dates, trainer, or meta", () => {
                    // Never saved - created/updated/trainer/meta are all null
                    var blog = entityNew("blog", {header: "Unsaved SEO Test Blog", image: "seo-test.webp"});

                    var parsed  = roundTrip(seoService.getBlogPosting(blog = blog, pageURL = "#domain#/readblog/x"));
                    var posting = getGraphNode(parsed, "BlogPosting");

                    expect(posting).notToHaveKey("datePublished");
                    expect(posting).notToHaveKey("dateModified");
                    expect(posting.author["@id"]).toBe("#domain#/##organization");
                });
            });
        });
    }

}
