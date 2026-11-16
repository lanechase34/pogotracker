component singleton accessors="true" {

    property name="auditService" inject="services.audit";
    property name="jsoup"        inject="javaloader:org.jsoup.Jsoup";
    property name="scraperHosts" inject="coldbox:setting:scraperHosts";
    property name="appName"      inject="coldbox:setting:appName";
    property name="domainProd"   inject="coldbox:setting:domainProd";

    property name="retryCount" type="numeric";
    property name="userAgents" type="array";

    public void function init() {
        setRetryCount(2);
        setUserAgents(getUserAgentsByOs(application.cbController.getSetting("osType")));
    }

    private array function getUserAgentsByOS(required string os) {
        switch(arguments.os) {
            case "windows":
                return ["Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0"];
            case "linux":
                return ["Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0"];
            default:
                throw("no valid os set");
        }
    }

    /**
     * Returns a random user agent
     */
    private string function getRandUserAgent() {
        var agentIndex = randRange(1, getUserAgents().len(), "SHA1PRNG");
        return getUserAgents()[agentIndex];
    }

    /**
     * Generate realistic headers
     */
    private struct function getRealisticHeaders(required string userAgent) {
        var headers = {
            "Accept"                   : "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language"          : "en-US,en;q=0.9",
            "DNT"                      : "1",
            "Connection"               : "keep-alive",
            "Upgrade-Insecure-Requests": "1"
        };

        // Determine platform based on user agent
        var platform = "Windows";
        if(findNoCase("Linux", arguments.userAgent)) {
            platform = "Linux";
        }

        // Add browser-specific headers
        if(findNoCase("Chrome", arguments.userAgent) && !findNoCase("Edg", arguments.userAgent)) {
            headers["sec-ch-ua"]          = """Not_A Brand"";v=""8"", ""Chromium"";v=""120"", ""Google Chrome"";v=""120""";
            headers["sec-ch-ua-mobile"]   = "?0";
            headers["sec-ch-ua-platform"] = """#platform#""";
            headers["Sec-Fetch-Dest"]     = "document";
            headers["Sec-Fetch-Mode"]     = "navigate";
            headers["Sec-Fetch-Site"]     = "none";
            headers["Sec-Fetch-User"]     = "?1";
        }
        else if(findNoCase("Edge", arguments.userAgent) || findNoCase("Edg", arguments.userAgent)) {
            headers["sec-ch-ua"]          = """Not_A Brand"";v=""8"", ""Chromium"";v=""120"", ""Microsoft Edge"";v=""120""";
            headers["sec-ch-ua-mobile"]   = "?0";
            headers["sec-ch-ua-platform"] = """#platform#""";
            headers["Sec-Fetch-Dest"]     = "document";
            headers["Sec-Fetch-Mode"]     = "navigate";
            headers["Sec-Fetch-Site"]     = "none";
            headers["Sec-Fetch-User"]     = "?1";
        }
        else if(findNoCase("Firefox", arguments.userAgent)) {
            headers["Sec-Fetch-Dest"] = "document";
            headers["Sec-Fetch-Mode"] = "navigate";
            headers["Sec-Fetch-Site"] = "none";
            headers["Sec-Fetch-User"] = "?1";
            headers["TE"]             = "trailers";
        }

        return headers;
    }

    /**
     * Uses json to fetch doc
     *
     * If returnJSON is true, return the format as json, otherwise jsoup object
     * If userAgent is blank, a random browser user agent is used
     */
    public any function getData(
        required string targetURL,
        boolean returnJSON = false,
        string userAgent   = ""
    ) {
        checkAllowedURL(arguments.targetURL);

        var attempts = 0;
        var response = javacast("null", "");
        while(attempts < getRetryCount() && isNull(response)) {
            try {
                var userAgent = len(arguments.userAgent) ? arguments.userAgent : getRandUserAgent();
                var headers   = getRealisticHeaders(userAgent);

                var doc = jsoup
                    .connect(arguments.targetURL)
                    .ignoreContentType(true)
                    .followRedirects(true)
                    .referrer("https://www.google.com/")
                    .userAgent(userAgent);

                headers.each((key, value) => {
                    doc.header(key, value);
                });

                // Redirects are followed, so check where we actually ended up before using the response
                var result = doc.execute();
                checkAllowedURL(result.url().toString());

                response = arguments.returnJSON ? result.body() : result.parse();
            }
            catch(any e) {
                auditService.auditSystem(
                    event  = "scraperService.getData",
                    detail = "Scraper attempt ###attempts + 1# failed for #arguments.targetURL#: #e.message# - #e.detail#"
                );
                attempts += 1;
                sleep(randRange(3000, 6000));
                if(attempts == getRetryCount()) rethrow;
            }
        }

        return response;
    }

    /**
     * Fetches a rendered wiki page as a jsoup document
     * Tries the MediaWiki parse api first, then falls back to the action=render page
     * Neither includes the site skin, so select page content directly (no #content wrapper)
     *
     * @host    wiki host, ex: pokemongo.fandom.com
     * @page    page title, ex: Medals
     * @apiPath where the wiki serves api.php - fandom at the root, bulbapedia under /w/
     */
    public any function getWikiPage(
        required string host,
        required string page,
        string apiPath = "/api.php"
    ) {
        var botUserAgent = "#reReplace(getAppName(), "\s+", "", "all")#/1.0 (+#getDomainProd()#)";
        var baseURI      = "https://#arguments.host#/wiki/";
        var encodedPage  = encodeForURL(arguments.page);

        try {
            var apiURL  = "https://#arguments.host##arguments.apiPath#?action=parse&page=#encodedPage#&prop=text&format=json&formatversion=2&disablelimitreport=1";
            var payload = deserializeJSON(
                getData(
                    targetURL  = apiURL,
                    returnJSON = true,
                    userAgent  = botUserAgent
                )
            );
            if(!isStruct(payload) || !payload.keyExists("parse")) {
                throw(
                    type    = "ScraperWikiParseFailed",
                    message = "Wiki parse api returned no page for #arguments.page#: #serializeJSON(payload.error ?: {})#"
                );
            }
            return jsoup.parse(payload.parse.text, baseURI);
        }
        catch(any e) {
            auditService.auditSystem(
                event  = "scraperService.getWikiPage",
                detail = "Wiki parse api failed for #arguments.page#, falling back to action=render: #e.message# - #e.detail#"
            );
        }

        var renderURL = "#baseURI##encodedPage#?action=render";
        return getData(targetURL = renderURL, userAgent = botUserAgent);
    }

    /**
     * CFHTTP to download an image from an allowed host and write it to the destination
     * Throws ScraperDownloadFailed on a non 200 response
     */
    public void function downloadImage(required string targetURL, required string destination) {
        checkAllowedURL(arguments.targetURL);
        // Redirects are not followed, anything other than a 200 (including a 3xx) is a failure
        cfhttp(
            url         = arguments.targetURL,
            result      = "local.imgResult",
            method      = "GET",
            redirect    = false,
            timeout     = 30,
            getAsBinary = "yes"
        );

        if(val(local.imgResult.status_code ?: 0) != 200) {
            throw(
                type    = "ScraperDownloadFailed",
                message = "Image download failed with status #local.imgResult.statusCode# for #arguments.targetURL#"
            );
        }

        // Write next to the destination and move it into place, so a failed write never leaves a broken image behind
        var finalPath = expandPath(arguments.destination);
        var tempPath  = getDirectoryFromPath(finalPath) & "tmp-#createUUID()#.#listLast(finalPath, ".")#";
        try {
            imageNew(local.imgResult.filecontent).write(tempPath);
            // Re-downloads (medal images) replace the existing file
            if(fileExists(finalPath)) fileDelete(finalPath);
            fileMove(tempPath, finalPath);
        }
        catch(any e) {
            if(fileExists(tempPath)) fileDelete(tempPath);
            rethrow;
        }
        return;
    }

    /**
     * Only scrape http(s) urls on the allowed hosts (or their subdomains)
     * Stops admin supplied links from reaching internal addresses (localhost, metadata endpoints, etc)
     *
     * @targetURL url to check, throws if not allowed
     */
    private void function checkAllowedURL(required string targetURL) {
        var host = "";
        try {
            // URL (not URI) is as lenient as jsoup, ex: trailing whitespace
            var parsed = createObject("java", "java.net.URL").init(trim(arguments.targetURL));
            if(listFindNoCase("http,https", parsed.getProtocol() ?: "")) {
                host = lCase(parsed.getHost() ?: "");
            }
        }
        catch(any e) {
        }

        var allowed = host.len() && getScraperHosts().some((allowedHost) => {
            return host == allowedHost || host.endsWith(".#allowedHost#");
        });

        if(!allowed) {
            throw(type = "ScraperHostNotAllowed", message = "Scraping is not allowed for #arguments.targetURL#");
        }
    }

}
