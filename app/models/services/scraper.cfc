component singleton accessors="true" {

    property name="auditService" inject="services.audit";
    property name="jsoup"        inject="javaloader:org.jsoup.Jsoup";

    property name="proxies"    type="array";
    property name="retryCount" type="numeric";
    property name="userAgents" type="array";

    public void function init() {
        setRetryCount(2);
        setUserAgents(getUserAgentsByOs(application.cbController.getSetting('osType')));
    }

    private array function getUserAgentsByOS(required string os) {
        switch(arguments.os) {
            case 'windows':
                return [
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0',
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36',
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0'
                ];
            case 'linux':
                return [
                    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0',
                    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                    'Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0'
                ];
            default:
                throw('no valid os set');
        }
    }

    /**
     * Returns a random user agent
     */
    private string function getRandUserAgent() {
        var rand = randRange(1, getUserAgents().len(), 'SHA1PRNG');
        return getUserAgents()[rand];
    }

    /**
     * Generate realistic headers
     */
    private struct function getRealisticHeaders(required string userAgent) {
        var headers = {
            'Accept'                   : 'application/json, text/html, application/xhtml+xml, application/xml;q=0.9, image/avif, image/webp, */*;q=0.8',
            'Accept-Language'          : 'en-US,en;q=0.9',
            'DNT'                      : '1',
            'Connection'               : 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Cache-Control'            : 'max-age=0'
        };

        // Determine platform based on user agent
        var platform = 'Windows';
        if(findNoCase('Linux', arguments.userAgent)) {
            platform = 'Linux';
        }

        // Add browser-specific headers
        if(findNoCase('Chrome', arguments.userAgent) && !findNoCase('Edg', arguments.userAgent)) {
            headers['sec-ch-ua']          = '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"';
            headers['sec-ch-ua-mobile']   = '?0';
            headers['sec-ch-ua-platform'] = '"#platform#"';
            headers['Sec-Fetch-Dest']     = 'document';
            headers['Sec-Fetch-Mode']     = 'navigate';
            headers['Sec-Fetch-Site']     = 'none';
            headers['Sec-Fetch-User']     = '?1';
        }
        else if(findNoCase('Edge', arguments.userAgent) || findNoCase('Edg', arguments.userAgent)) {
            headers['sec-ch-ua']          = '"Not_A Brand";v="8", "Chromium";v="120", "Microsoft Edge";v="120"';
            headers['sec-ch-ua-mobile']   = '?0';
            headers['sec-ch-ua-platform'] = '"#platform#"';
            headers['Sec-Fetch-Dest']     = 'document';
            headers['Sec-Fetch-Mode']     = 'navigate';
            headers['Sec-Fetch-Site']     = 'none';
            headers['Sec-Fetch-User']     = '?1';
        }
        else if(findNoCase('Firefox', arguments.userAgent)) {
            headers['Sec-Fetch-Dest'] = 'document';
            headers['Sec-Fetch-Mode'] = 'navigate';
            headers['Sec-Fetch-Site'] = 'none';
            headers['Sec-Fetch-User'] = '?1';
            headers['TE']             = 'trailers';
        }

        return headers;
    }

    /**
     * Uses json to fetch doc
     *
     * If returnJSON is true, return the format as json, otherwise jsoup object
     */
    public any function getData(required string url, boolean returnJSON = false) {
        var count    = 0;
        var response = javacast('null', '');
        while(count < getRetryCount() && isNull(response)) {
            try {
                var userAgent = getRandUserAgent();
                var headers   = getRealisticHeaders(userAgent);

                var doc = jsoup
                    .connect(arguments.url)
                    .ignoreContentType(true)
                    .followRedirects(true)
                    .referrer('https://www.google.com/')
                    .userAgent(userAgent);

                headers.each((key, value) => {
                    doc.header(key, value);
                });

                if(arguments.returnJSON) {
                    response = doc.execute().body();
                }
                else {
                    response = doc.get();
                }
            }
            catch(any e) {
                auditService.audit(
                    ip      = 'localhost',
                    event   = 'scraperService.getData',
                    referer = '',
                    detail  = 'Scraper attempt ###count# failed for #arguments.url#: #e.message# - #e.detail#',
                    agent   = ''
                );
                count += 1;
                sleep(randRange(3000, 6000));
                if(count == getRetryCount()) rethrow;
            }
        }

        return response;
    }

}
