component singleton accessors="true" {

    property name="cache"          inject="cachebox:appCache";
    property name="jsoup"          inject="javaloader:org.jsoup.Jsoup";
    property name="imageService"   inject="Helpers@ImageMagick";
    property name="trainerService" inject="services.trainer";
    property name="scraperService" inject="services.scraper";
    property name="uploadPath"     inject="coldbox:setting:uploadPath";
    property name="maxThreads"     inject="coldbox:setting:maxThreads";
    property name="utilService"    inject="services.util";

    // Scraped news/events cache keys
    variables.NEWS_LIST_KEY      = "external.news.list";
    variables.EVENT_LIST_KEY     = "external.events.list";
    variables.EVENT_LOCATION_KEY = "external.events.locationSpecific";

    /**
     * Gets blog list sorted by created desc
     */
    public array function get(required numeric count, required numeric offset) {
        var cacheKey = "blog.get|count=#arguments.count#|offset=#arguments.offset#";
        var blogs    = cache.get(cacheKey);
        if(isNull(blogs)) {
            blogs = ormExecuteQuery(
                "
                from blog as blog
                order by blog.created desc
                ",
                {},
                false,
                {maxResults: arguments.count, offset: arguments.offset}
            );

            cache.set(cacheKey, blogs, 720, 720);
        }
        return blogs;
    }

    /**
     * Get single blog by PK
     */
    public component function getFromId(required numeric blogid, boolean useCache = true) {
        var cacheKey = "blog.getFromId|blogid=#arguments.blogid#";
        var blog     = cache.get(cacheKey);
        if(isNull(blog) || !arguments.useCache) {
            blog = entityLoadByPK("blog", arguments.blogid);
            blog.getComment();

            if(arguments.useCache) {
                cache.set(cacheKey, blog, 720, 720);
            }
        }
        return blog;
    }

    /**
     * Get a blog from its header 
     * Returns blog cfc or empty
     */
    public any function getFromHeader(required string header) {
        var cacheKey = "blog.getFromHeader|header=#lCase(arguments.header)#";
        var blog     = cache.get(cacheKey);
        if(isNull(blog)) {
            // Headers are unique ignoring case
            blog = ormExecuteQuery(
                "from blog where lower(header) = :header",
                {header: lCase(trim(arguments.header))},
                true
            );
            if(isNull(blog)) return; // Invalid blog return null here

            blog.getComment();
            cache.set(cacheKey, blog, 720, 720);
        }
        return blog;
    }

    /**
     * URL slug for a blog's /readblog/ page - the header with spaces replaced by -
     * Case is preserved, so this is the only casing blog.read serves without a redirect
     *
     * @header the blog's stored header
     */
    public string function getSlug(required string header) {
        return arguments.header.replace(" ", "-", "all");
    }

    public void function create(
        required component trainer,
        required string header,
        required string meta,
        required string image,
        required string alt,
        required string bodyjson,
        required string body
    ) {
        var newBlog = entityNew(
            "blog",
            {
                "header"  : trim(arguments.header),
                "meta"    : arguments.meta,
                "image"   : arguments.image,
                "alttext" : arguments.alt,
                "bodyjson": arguments.bodyjson,
                "body"    : arguments.body,
                "trainer" : arguments.trainer
            }
        );
        try {
            entitySave(newBlog);
            ormFlush();
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }

        // Clear the blog cache whenever a new entry is saved
        cache.clearByKeySnippet("blog.");
        return;
    }

    public void function edit(
        required component trainer,
        required numeric blogid,
        required string header,
        required string meta,
        required string image,
        required string alt,
        required string bodyjson,
        required string body
    ) {
        var blog = getFromId(arguments.blogid, false);

        blog.setTrainer(arguments.trainer);
        blog.setHeader(trim(arguments.header));
        blog.setMeta(arguments.meta);
        blog.setBodyJson(arguments.bodyjson);
        blog.setBody(arguments.body);
        blog.setAltText(arguments.alt);

        if(arguments.image.len()) {
            blog.setImage(arguments.image);
        }

        try {
            entitySave(blog);
            ormFlush();
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }

        // Clear the blog cache whenever a new entry is saved
        cache.clearByKeySnippet("blog.");
        return;
    }

    /**
     * Sanitizes user input comment of unwanted junk
     * Uses all mighty JSOUP!
     *
     * @comment 
     */
    public string function sanitizeComment(required string comment) {
        return jsoup
            .parse(comment)
            .text()
            .replace(chr(10), "<br/>", "all");
    }

    /**
     * Adds a user inputted comment to blog
     *
     * @trainerid trainerid
     * @blogid    blogid - attempt to load blog based on this id
     * @comment   unsafe user comment
     */
    public void function addComment(
        required numeric trainerid,
        required numeric blogid,
        required string comment
    ) {
        var trainer = trainerService.getFromId(trainerid = trainerid);
        var blog    = getFromId(blogid = blogid);

        if(isNull(blog)) {
            throw(type = "EntityNotFound", message = "Blog not found");
        }

        /**
         * Sanitize user input and add new comment
         */
        var sanitizedComment = sanitizeComment(comment);
        var newComment       = entityNew(
            "comment",
            {
                trainer: trainer,
                blog   : blog,
                comment: serializeJSON(sanitizedComment)
            }
        );

        entitySave(newComment);
        ormFlush();

        // Clear the read blog cache
        cache.clearByKeySnippet("blog.getFromId|blogid=#blog.getId()#");
        cache.clearByKeySnippet("blog.getFromHeader|header=#lCase(blog.getHeader())#");
        return;
    }

    /**
     * Gets a struct of latest blog posts on the pokemon go website
     * The full scraped list is cached once and pages are sliced from it, so infinite scroll never re-scrapes
     *
     * @count  number of posts to return
     * @offset number of posts to skip
     */
    public array function getNews(numeric count = application.cbController.getSetting("fetchCount"), numeric offset = 0) {
        return slicePage(getNewsList(), arguments.offset, arguments.count);
    }

    /**
     * Scrape and cache every news card on the pokemongo.com news page
     */
    private array function getNewsList() {
        var news = cache.get(variables.NEWS_LIST_KEY);

        if(isNull(news)) {
            news        = [];
            var baseUrl = "https://pokemongo.com";
            var newsUrl = "https://pokemongo.com/en/news";

            var newsDoc   = scraperService.getData(newsUrl);
            var blogPosts = newsDoc
                .body()
                .select("main##main")
                .select("div[class*='_newsCards_']")
                .select("a[class*='_newsCard_']");

            blogPosts.each((post) => {
                news.append({
                    link: "#baseUrl##post.attr("href")#",
                    img : post
                        .select("div[class*='_newsCardImage_']")
                        .select("div[class*='_image_']")
                        .select("picture")
                        .select("img")
                        .attr("src"),
                    date: dateAdd(
                        "s",
                        (
                            post.select("div[class*='_newsCardContent_']")
                                .select("pg-date-format[class*='_newsCardDate_']")
                                .attr("timestamp")
                        ) / 1000,
                        dateConvert("utc2Local", "January 1 1970 00:00")
                    ),
                    header: post
                        .select("div[class*='_newsCardContent_']")
                        .select("div[class*='heading_']")
                        .text()
                });
            });

            cache.set(variables.NEWS_LIST_KEY, news, 10, 10);
        }

        return news;
    }

    /**
     * Build array of upcoming events from leekduck
     * The event list is scraped once and cached
     *
     * @count  number of events to add
     * @offset number of upcoming events to skip
     */
    public array function getEvents(
        numeric count  = application.cbController.getSetting("fetchCount"),
        numeric offset = 0
    ) {
        // Copy so the cached list entries are never mutated
        var events = slicePage(
            getEventList(),
            arguments.offset,
            arguments.count
        ).map((event) => duplicate(event));

        events.each(
            (event) => {
                event.locationSpecific = isLocationSpecific(event.link);
            },
            true,
            maxThreads
        );

        return events;
    }

    /**
     * Scrape and cache the leekduck upcoming events list
     * Events that started more than 4 hours ago are excluded
     */
    private array function getEventList() {
        var events = cache.get(variables.EVENT_LIST_KEY);

        if(isNull(events)) {
            events        = [];
            var baseUrl   = "https://leekduck.com";
            var eventsUrl = "https://leekduck.com/events/";

            var eventsDoc  = scraperService.getData(eventsUrl);
            var eventPosts = eventsDoc
                .body()
                .select("div.upcoming-events")
                .select("span.event-header-item-wrapper");
            eventPosts.each((post, index) => {
                var postTimestamp = parseDateTime(date = post.attr("data-event-date-sort"), timezone = "UTC");
                if(dateDiff("h", postTimestamp, now()) >= 4) continue;

                events.append({
                    type: post
                        .select("a")
                        .select("div.event-item-wrapper")
                        .select("p")
                        ?.first()
                        ?.text() ?: "#index# nope",
                    title: post
                        .select("a")
                        .select("div.event-item-wrapper")
                        .select("div.event-item")
                        .select("div.event-text-container")
                        .select("div.event-text")
                        .select("h2")
                        .text(),
                    timestamp: post.attr("data-event-local-time") == true ? post
                        .select("a")
                        .select("div.event-item-wrapper")
                        .select("div.event-item")
                        .select("div.event-text-container")
                        .select("div.event-text")
                        .select("p")
                        .text() : "#dayOfWeekShortAsString(dayOfWeek(postTimestamp))#, #monthShortAsString(month(postTimestamp))# #day(postTimestamp)#, at #timeFormat(postTimestamp, "h:mm tt")# EST",
                    link         : "#baseUrl##post.select("a").attr("href")#",
                    datatimestamp: postTimestamp
                });
            });

            cache.set(variables.EVENT_LIST_KEY, events, 10, 10);
        }

        return events;
    }

    /**
     * Whether a leekduck event page is tagged location specific
     * An event's tags don't change, so this is cached per link for 12 hours
     *
     * @link full leekduck event url
     */
    private boolean function isLocationSpecific(required string link) {
        var cacheKey         = "#variables.EVENT_LOCATION_KEY#|link=#arguments.link#";
        var locationSpecific = cache.get(cacheKey);

        if(isNull(locationSpecific)) {
            locationSpecific = !scraperService
                .getData(arguments.link)
                .body()
                .select("div.page-tags")
                .select("div.tag.location-specific")
                .isEmpty();

            cache.set(cacheKey, locationSpecific, 720, 720);
        }

        return locationSpecific;
    }

    /**
     * One page of a cached list - items offset+1 through offset+count
     */
    private array function slicePage(
        required array items,
        required numeric offset,
        required numeric count
    ) {
        if(arguments.offset >= arguments.items.len() || arguments.count <= 0) return [];
        return arguments.items.slice(
            arguments.offset + 1,
            min(arguments.count, arguments.items.len() - arguments.offset)
        );
    }

    /**
     * Upload wrapper for blog images, resizes to correct full/card height
     *
     * @return The complete image UUID with extension
     *
     * @throws ImageMagick.UploadValidationException on conversion or resize failures
     */
    public string function imageUpload() {
        var image = imageService.validateUpload(
            formField  = "blogimage",
            outputs    = [{uploadDir: getUploadPath(), type: "webp"}],
            autoOrient = true,
            quality    = 95
        );

        // Add .webp extension to the filename
        image &= ".webp";
        var intermediatePath = "#getUploadPath()#/#image#";

        try {
            // Resize
            imageService.resize(
                path    = intermediatePath,
                outputs = [
                    {resizeDir: "#getUploadPath()#/cards", height: 250},
                    {resizeDir: "#getUploadPath()#/full", height: 350}
                ]
            );
        }
        catch(ImageMagick.ResizeException e) {
            throw(
                type    = "ImageMagick.UploadValidationException",
                message = "Image could not be processed.",
                detail  = "#e.message# | #e.detail#"
            );
        }
        finally {
            // Delete the intermediate converted image
            if(fileExists(intermediatePath)) {
                fileDelete(intermediatePath);
            }
        }

        return image;
    }

}
