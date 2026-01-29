component singleton accessors="true" {

    property name="jsoup" inject="javaloader:org.jsoup.Jsoup";

    property name="proxies"    type="array";
    property name="retryCount" type="numeric";
    property name="userAgents" type="array";

    public void function init() {
        setRetryCount(2);

        setUserAgents([
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0'
        ]);
    }

    private string function getRandUserAgent(boolean random = false) {
        if(arguments.random) {
            var rand = randRange(1, getUserAgents().len(), 'SHA1PRNG');
            return getUserAgents()[rand];
        }

        return getUserAgents()[1];
    }

    public object function getData(required string url, boolean random = false) {
        var count = 0;
        while(count < getRetryCount() && isNull(doc)) {
            try {
                var doc = jsoup
                    .connect(arguments.url)
                    .ignoreContentType(true)
                    .followRedirects(true)
                    .referrer('https://www.google.com/')
                    .userAgent(getRandUserAgent(arguments.random))
                    .get();
            }
            catch(any e) {
                count += 1;
                sleep(randRange(3000, 6000));
                if(count == getRetryCount()) rethrow;
            }
        }

        return doc;
    }

}
