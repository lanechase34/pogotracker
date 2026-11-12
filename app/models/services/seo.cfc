component singleton accessors="true" {

    property name="domain"          inject="coldbox:setting:domain";
    property name="metaDescription" inject="coldbox:setting:metaDescription";
    property name="siteName"        inject="coldbox:setting:siteName";

    /**
     * Serialize structured data for the JSON-LD script block in layouts/header
     * Escapes closing tag sequences so content can never end the script tag early
     */
    public string function toJsonLd(required struct data) {
        return serializeJSON(arguments.data).replace("</", "<\/", "all");
    }

    /**
     * Default site wide graph - WebSite + WebApplication
     */
    public struct function getSiteGraph() {
        return [
            "@context": "https://schema.org",
            "@graph"  : [getWebSite(), getWebApplication()]
        ];
    }

    /**
     * Pokemon detail page - WebPage with the sprite as its primary image + breadcrumb
     *
     * @name        pokemon's full name
     * @description page meta description
     * @pageURL     canonical url of the page
     * @image       absolute url to the pokemon's sprite
     */
    public struct function getPokemonDetail(
        required string name,
        required string description,
        required string pageURL,
        required string image
    ) {
        return [
            "@context": "https://schema.org",
            "@graph"  : [
                [
                    "@type"             : "WebPage",
                    "@id"               : arguments.pageURL,
                    "url"               : arguments.pageURL,
                    "name"              : arguments.name,
                    "description"       : arguments.description,
                    "isPartOf"          : ["@id": getWebSiteId()],
                    "breadcrumb"        : ["@id": "#arguments.pageURL###breadcrumb"],
                    "primaryImageOfPage": [
                        "@type"     : "ImageObject",
                        "contentUrl": arguments.image,
                        "caption"   : arguments.name
                    ]
                ],
                getBreadcrumb(
                    id    = "#arguments.pageURL###breadcrumb",
                    items = [
                        {name: "Home", url: "#getDomain()#/"},
                        {name: "Pokédex", url: "#getDomain()#/pokemon"},
                        {name: arguments.name, url: arguments.pageURL}
                    ]
                ),
                getWebSite()
            ]
        ];
    }

    /**
     * Pokedex index page - CollectionPage + breadcrumb
     *
     * @name        page name
     * @description page meta description
     * @pageURL     canonical url of the page
     */
    public struct function getPokedexIndex(
        required string name,
        required string description,
        required string pageURL
    ) {
        return [
            "@context": "https://schema.org",
            "@graph"  : [
                [
                    "@type"      : "CollectionPage",
                    "@id"        : arguments.pageURL,
                    "url"        : arguments.pageURL,
                    "name"       : arguments.name,
                    "description": arguments.description,
                    "isPartOf"   : ["@id": getWebSiteId()],
                    "breadcrumb" : ["@id": "#arguments.pageURL###breadcrumb"]
                ],
                getBreadcrumb(
                    id    = "#arguments.pageURL###breadcrumb",
                    items = [
                        {name: "Home", url: "#getDomain()#/"},
                        {name: "Pokédex", url: arguments.pageURL}
                    ]
                ),
                getWebSite()
            ]
        ];
    }

    /**
     * Blog post - BlogPosting + breadcrumb
     *
     * @blog    blog orm entity
     * @pageURL canonical url of the page
     */
    public struct function getBlogPosting(required component blog, required string pageURL) {
        var created = arguments.blog.getCreated();
        var meta    = arguments.blog.getMeta();

        var posting = [
            "@type"           : "BlogPosting",
            "@id"             : "#arguments.pageURL###article",
            "mainEntityOfPage": arguments.pageURL,
            "headline"        : left(arguments.blog.getHeader(), 110),
            "description"     : !isNull(meta) && meta.len() ? meta : arguments.blog.getExcerpt(160),
            "image"           : arguments.blog.getOgImage(),
            "publisher"       : ["@id": getOrganizationId()],
            "isPartOf"        : ["@id": getWebSiteId()]
        ];
        if(!isNull(created)) {
            // Resolve inside the guard - Lucee leaves a var undefined when assigned null
            var modified             = arguments.blog.getUpdated() ?: created;
            posting["datePublished"] = toISO8601(created);
            posting["dateModified"]  = toISO8601(modified);
        }

        var trainer = arguments.blog.getTrainer();
        if(!isNull(trainer)) {
            posting["author"] = ["@type": "Person", "name": trainer.getUsername()];
        }
        else {
            posting["author"] = ["@id": getOrganizationId()];
        }

        return [
            "@context": "https://schema.org",
            "@graph"  : [
                posting,
                getBreadcrumb(
                    id    = "#arguments.pageURL###breadcrumb",
                    items = [
                        {name: "Home", url: "#getDomain()#/"},
                        {name: arguments.blog.getHeader(), url: arguments.pageURL}
                    ]
                ),
                getOrganization(),
                getWebSite()
            ]
        ];
    }

    /**
     * BreadcrumbList from an ordered array of {name, url}
     */
    public struct function getBreadcrumb(required string id, required array items) {
        return [
            "@type"          : "BreadcrumbList",
            "@id"            : arguments.id,
            "itemListElement": arguments.items.map((item, index) => [
                "@type"   : "ListItem",
                "position": index,
                "name"    : item.name,
                "item"    : item.url
            ])
        ];
    }

    private struct function getWebSite() {
        return [
            "@type"        : "WebSite",
            "@id"          : getWebSiteId(),
            "name"         : getSiteName(),
            "alternateName": ["PogoTracker", "pogotracker.app"],
            "url"          : "#getDomain()#/"
        ];
    }

    private struct function getWebApplication() {
        return [
            "@type"              : "WebApplication",
            "name"               : getSiteName(),
            "url"                : "#getDomain()#/",
            "description"        : getMetaDescription(),
            "applicationCategory": "GameApplication",
            "operatingSystem"    : "Web",
            "offers"             : [
                "@type"        : "Offer",
                "price"        : "0",
                "priceCurrency": "USD"
            ]
        ];
    }

    private struct function getOrganization() {
        return [
            "@type": "Organization",
            "@id"  : getOrganizationId(),
            "name" : getSiteName(),
            "url"  : "#getDomain()#/",
            "logo" : "#getDomain()#/includes/images/favicon-192.png"
        ];
    }

    private string function getWebSiteId() {
        return "#getDomain()#/##website";
    }

    private string function getOrganizationId() {
        return "#getDomain()#/##organization";
    }

    /**
     * ISO 8601 date time with offset (schema.org Date/DateTime)
     */
    private string function toISO8601(required date value) {
        return dateTimeFormat(arguments.value, "iso");
    }

}
