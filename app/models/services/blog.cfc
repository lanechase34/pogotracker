component singleton accessors="true" {

    property name="cacheService"   inject="services.cache";
    property name="jsoup"          inject="javaloader:org.jsoup.Jsoup";
    property name="trainerService" inject="services.trainer";
    property name="scraperService" inject="services.scraper";

    /**
     * Gets blog list sorted by created desc
     */
    public array function get(required numeric count, required numeric offset) {
        var cacheKey = 'blog.get|count=#arguments.count#|offset=#arguments.offset#';
        var blogs    = cacheService.get(cacheKey);
        if(isNull(blogs)) {
            blogs = ormExecuteQuery(
                '
                from blog as blog
                order by blog.created desc
                ',
                {},
                false,
                {maxResults: arguments.count, offset: arguments.offset}
            );

            cacheService.put(cacheKey, blogs, 720, 720);
        }
        return blogs;
    }

    /**
     * Get single blog by PK
     */
    public component function getFromId(required numeric blogid, boolean useCache = true) {
        var cacheKey = 'blog.getFromId|blogid=#arguments.blogid#';
        var blog     = cacheService.get(cacheKey);
        if(isNull(blog) || !arguments.useCache) {
            blog = entityLoadByPK('blog', arguments.blogid);
            blog.getComment();

            if(arguments.useCache) cacheService.put(cacheKey, blog, 720, 720);
        }
        return blog;
    }

    /**
     * Get a blog from its header 
     * Returns blog cfc or empty
     */
    public any function getFromHeader(required string header) {
        var cacheKey = 'blog.getFromHeader|header=#lCase(arguments.header)#';
        var blog     = cacheService.get(cacheKey);
        if(isNull(blog)) {
            blog = entityLoad('blog', {header: arguments.header}, true);
            if(isNull(blog)) return; // Invalid blog return null here

            blog.getComment();
            cacheService.put(cacheKey, blog, 720, 720);
        }
        return blog;
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
            'blog',
            {
                'header'  : arguments.header,
                'meta'    : arguments.meta,
                'image'   : arguments.image,
                'alttext' : arguments.alt,
                'bodyjson': arguments.bodyjson,
                'body'    : arguments.body,
                'trainer' : arguments.trainer
            }
        );
        entitySave(newBlog);
        ormFlush();

        // Clear the blog cache whenever a new entry is saved
        cacheService.clear(filter = 'blog.');
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
        var blog           = getFromId(arguments.blogid, false);
        var previousHeader = lCase(blog.getHeader());

        blog.setTrainer(arguments.trainer);
        blog.setHeader(arguments.header);
        blog.setMeta(arguments.meta);
        blog.setBodyJson(arguments.bodyjson);
        blog.setBody(arguments.body);
        blog.setAltText(arguments.alt);

        if(arguments.image.len()) {
            blog.setImage(arguments.image);
        }
        entitySave(blog);
        ormFlush();

        // Clear the blog cache whenever a new entry is saved
        cacheService.clear(filter = 'blog.');
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
            .replace(chr(10), '<br/>', 'all');
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
            throw(type = 'EntityNotFound', mesasge = 'Blog not found');
        }

        /**
         * Sanitize user input and add new comment
         */
        var sanitizedComment = sanitizeComment(comment);
        var newComment       = entityNew(
            'comment',
            {
                trainer: trainer,
                blog   : blog,
                comment: serializeJSON(sanitizedComment)
            }
        );

        entitySave(newComment);
        ormFlush();

        // Clear the read blog cache
        cacheService.clear(filter = 'blog.getFromId|blogid=#blog.getId()#');
        cacheService.clear(filter = 'blog.getFromHeader|header=#lCase(blog.getHeader())#');
        return;
    }

    /**
     * Gets a struct of latest blog posts on the pokemon go website
     *
     * @count number of posts to return
     */
    public array function getNews(numeric count = application.cbController.getSetting('fetchCount')) {
        var cacheKey = 'blog.getNews';
        var news     = cacheService.get(cacheKey);

        if(isNull(news)) {
            news        = [];
            var baseUrl = 'https://pokemongolive.com';
            var newsUrl = 'https://pokemongolive.com/en/news';

            var newsDoc   = scraperService.getData(newsUrl);
            var blogPosts = newsDoc
                .body()
                .select('main##main')
                .select('div[class*=''_newsCards_'']')
                .select('a[class*=''_newsCard_'']');

            blogPosts.each((post, index) => {
                if(index > count) break;

                news.append({
                    link: '#baseUrl##post.attr('href')#',
                    img : post
                        .select('div[class*=''_newsCardImage_'']')
                        .select('div[class*=''_image_'']')
                        .select('picture')
                        .select('img')
                        .attr('src'),
                    date: dateAdd(
                        's',
                        (
                            post.select('div[class*=''_newsCardContent_'']')
                                .select('pg-date-format[class*=''_newsCardDate_'']')
                                .attr('timestamp')
                        ) / 1000,
                        dateConvert('utc2Local', 'January 1 1970 00:00')
                    ),
                    header: post
                        .select('div[class*=''_newsCardContent_'']')
                        .select('div[class*=''heading_'']')
                        .text()
                });
            });

            cacheService.put(cacheKey, news, 10, 10);
        }

        return news;
    }

    /**
     * Build array of upcoming events from leekduck
     *
     * @count number of events to add
     */
    public array function getEvents(numeric count = application.cbController.getSetting('fetchCount')) {
        var cacheKey = 'blog.getEvents'
        var events   = cacheService.get(cacheKey);

        if(isNull(events)) {
            events        = [];
            var baseUrl   = 'https://leekduck.com';
            var eventsUrl = 'https://leekduck.com/events/';

            var eventsDoc  = scraperService.getData(eventsUrl);
            var eventPosts = eventsDoc
                .body()
                .select('div.upcoming-events')
                .select('span.event-header-item-wrapper');
            eventPosts.each((post, index) => {
                if(events.len() == count) break;

                var postTimestamp = parseDateTime(date = post.attr('data-event-date-sort'), timezone = 'UTC');
                if(dateDiff('h', postTimestamp, now()) >= 4) continue;

                events.append({
                    type: post
                        .select('a')
                        .select('div.event-item-wrapper')
                        .select('p')
                        ?.first()
                        ?.text() ?: '#index# nope',
                    title: post
                        .select('a')
                        .select('div.event-item-wrapper')
                        .select('div.event-item')
                        .select('div.event-text-container')
                        .select('div.event-text')
                        .select('h2')
                        .text(),
                    timestamp: post.attr('data-event-local-time') == true ? post
                        .select('a')
                        .select('div.event-item-wrapper')
                        .select('div.event-item')
                        .select('div.event-text-container')
                        .select('div.event-text')
                        .select('p')
                        .text() : '#dayOfWeekShortAsString(dayOfWeek(postTimestamp))#, #monthShortAsString(month(postTimestamp))# #day(postTimestamp)#, at #timeFormat(postTimestamp, 'h:mm tt')# EST',
                    link         : '#baseUrl##post.select('a').attr('href')#',
                    datatimestamp: postTimestamp
                });
            });

            cacheService.put(cacheKey, events, 10, 10);
        }

        return events;
    }

}
