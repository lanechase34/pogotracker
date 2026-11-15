component singleton accessors="true" {

    property name="cache"            inject="cachebox:appCache";
    property name="jsoup"            inject="javaloader:org.jsoup.Jsoup";
    property name="imageService"     inject="Helpers@ImageMagick";
    property name="trainerService"   inject="services.trainer";
    property name="scraperService"   inject="services.scraper";
    property name="uploadPath"       inject="coldbox:setting:uploadPath";
    property name="maxThreads"       inject="coldbox:setting:maxThreads";
    property name="utilService"      inject="services.util";
    property name="auditService"     inject="services.audit";
    property name="profanityService" inject="services.profanity";
    property name="pagination"       inject="services.pagination";
    property name="permissions"      inject="coldbox:setting:permissions";
    // pageSize, profanityStrikes, strikeWindowDays
    property name="commentSettings"  inject="coldbox:setting:comments";

    // A comment's columns with its author's username and icon - FROM comment LEFT JOIN trainer
    variables.COMMENT_COLUMNS = "
        comment.id, comment.created, comment.updated, comment.comment, comment.trainerid, comment.blogid,
        trainer.username AS authorusername, trainer.icon AS authoricon
    ";
    variables.COMMENT_FROM = "
        FROM comment
        LEFT JOIN trainer ON trainer.id = comment.trainerid
    ";

    // Audit events for comment moderation
    variables.BLOCKED_COMMENT_EVENT = "blog.addComment.blocked";
    variables.COMMENT_BAN_EVENT     = "blog.commentBanned";
    variables.DELETED_COMMENT_EVENT = "blog.deleteComment";

    // Sort column per admin comment table column (getCommentTable)
    variables.COMMENT_TABLE_COLS = [
        "comment.created",
        "blog.header",
        "trainer.username"
    ];

    // A blog row with its author's username and icon
    variables.BLOG_SELECT = "
        SELECT blog.id, blog.created, blog.updated, blog.header, blog.image, blog.alttext, blog.bodyjson, blog.body,
            blog.upvote, blog.meta, blog.trainerid, trainer.username AS authorusername, trainer.icon AS authoricon
        FROM blog
        LEFT JOIN trainer ON trainer.id = blog.trainerid
    ";

    // Scraped news/events cache keys
    variables.NEWS_LIST_KEY      = "external.news.list";
    variables.EVENT_LIST_KEY     = "external.events.list";
    variables.EVENT_LOCATION_KEY = "external.events.locationSpecific";

    /**
     * Gets blog list sorted by created desc
     * Each blog is a struct of its columns plus excerpt, ogimage and author (see toBlog)
     * A page past the last blog is empty and isn't cached, so the cached pages are bounded by the blog count
     */
    public array function getBlogs(required numeric pageSize, required numeric offset) {
        var pageLimit  = arguments.pageSize;
        var pageOffset = arguments.offset;
        if(pageOffset > 0 && pageOffset >= getBlogCount()) {
            return [];
        }
        return cache.getOrSet(
            getBlogsCacheKey(pageSize = pageLimit, offset = pageOffset),
            () => queryExecute(
                "
                #variables.BLOG_SELECT#
                ORDER BY blog.created DESC, blog.id DESC
                LIMIT :pageSize
                OFFSET :offset
                ",
                {pageSize: {value: pageLimit, cfsqltype: "integer"}, offset: {value: pageOffset, cfsqltype: "integer"}},
                {returnType: "array"}
            ).map((row) => {
                // The list only shows the excerpt - don't keep every listed blog's full body cached here too
                var blog = toBlog(row);
                blog.delete("body");
                blog.delete("bodyjson");
                return blog;
            }),
            720,
            720
        );
    }

    /**
     * Number of blogs - cleared with the rest of the blog cache (clearCache)
     */
    public numeric function getBlogCount() {
        return cache.getOrSet(
            "blog.getBlogCount",
            () => queryExecute(
                "SELECT COUNT(*) AS total FROM blog",
                {},
                {returnType: "array"}
            )[1].total,
            720,
            720
        );
    }

    /**
     * Get single blog by PK - its comments come from getCommentPage
     * Returns null when there is no such blog
     */
    public any function getFromId(required numeric blogid, boolean useCache = true) {
        var cacheKey = getFromIdCacheKey(arguments.blogid);
        var blog     = arguments.useCache ? cache.get(cacheKey) : javacast("null", "");
        if(isNull(blog)) {
            blog = loadBlog("blog.id = :blogid", {blogid: {value: arguments.blogid, cfsqltype: "integer"}});
            if(isNull(blog)) return;

            if(arguments.useCache) {
                cache.set(cacheKey, blog, 720, 720);
            }
        }
        return blog;
    }

    /**
     * Get a blog from its url slug (getSlug), matched ignoring case - its comments come from getCommentPage
     * Only the slug's blogid is cached here, so each blog is cached once (by getFromId)
     * Returns null when there is no such blog
     *
     * @slug the /readblog/ slug
     */
    public any function getFromSlug(required string slug) {
        var cacheKey = getFromSlugCacheKey(arguments.slug);
        var blogid   = cache.get(cacheKey);
        if(isNull(blogid)) {
            // Slugs are unique ignoring case (unq_blog_slug), which also serves this lookup
            var rows = queryExecute(
                "SELECT id FROM blog WHERE LOWER(REPLACE(header, ' ', '-')) = :slug",
                {slug: {value: lCase(trim(arguments.slug)), cfsqltype: "varchar"}},
                {returnType: "array"}
            );
            if(!rows.len()) return; // Invalid blog return null here

            blogid = rows[1].id;
            cache.set(cacheKey, blogid, 720, 720);
        }
        return getFromId(blogid);
    }

    /**
     * One blog matching the where clause, or null
     *
     * @whereSQL condition on the blog table, with named params
     * @params   query params for whereSQL
     */
    private any function loadBlog(required string whereSQL, required struct params) {
        var rows = queryExecute(
            "#variables.BLOG_SELECT# WHERE #arguments.whereSQL# LIMIT 1",
            arguments.params,
            {returnType: "array"}
        );
        if(!rows.len()) return;

        return toBlog(rows[1]);
    }

    /**
     * A page of a blog's comments - the newest comments.pageSize of them older than beforeid, oldest first
     * The first page (no beforeid) is what every reader sees, so only it is cached; a new or deleted comment clears it
     *
     * @blogid   blog pk
     * @beforeid only comments older than this one - 0 for the newest page
     * @useCache whether the first page may come from, and fill, the cache
     *
     * @return {comments, total: comments older than beforeid (all of them for the first page), remaining: older ones not in this page, oldestid}
     */
    public struct function getCommentPage(
        required numeric blogid,
        numeric beforeid = 0,
        boolean useCache = true
    ) {
        var isFirstPage = arguments.beforeid <= 0;
        var cacheKey    = getCommentsCacheKey(arguments.blogid);
        var page        = isFirstPage && arguments.useCache ? cache.get(cacheKey) : javacast("null", "");
        if(!isNull(page)) return page;

        var params = {
            blogid  : {value: arguments.blogid, cfsqltype: "integer"},
            pageSize: {value: commentSettings.pageSize, cfsqltype: "integer"}
        };
        var olderSQL = "";
        if(!isFirstPage) {
            olderSQL        = "AND comment.id < :beforeid";
            params.beforeid = {value: arguments.beforeid, cfsqltype: "integer"};
        }

        // Newest first so LIMIT takes the newest, then flipped to read top to bottom. ids rise with created,
        // so the (blogid, id) index serves both the filter and the order
        var rows = queryExecute(
            "
            SELECT #variables.COMMENT_COLUMNS#, COUNT(*) OVER () AS total
            #variables.COMMENT_FROM#
            WHERE comment.blogid = :blogid
                #olderSQL#
            ORDER BY comment.id DESC
            LIMIT :pageSize
            ",
            params,
            {returnType: "array"}
        );

        var total    = rows.len() ? val(rows[1].total) : 0;
        var comments = rows
            .reverse()
            .map((row) => {
                var comment = withAuthor(row);
                comment.delete("total");
                return comment;
            });
        page = {
            comments : comments,
            total    : total,
            remaining: total - comments.len(),
            oldestid : comments.len() ? comments[1].id : 0
        };

        if(isFirstPage && arguments.useCache) {
            cache.set(cacheKey, page, 720, 720);
        }
        return page;
    }

    /**
     * One comment with its author, or null
     *
     * @commentid comment pk
     */
    public any function getComment(required numeric commentid) {
        var rows = queryExecute(
            "SELECT #variables.COMMENT_COLUMNS# #variables.COMMENT_FROM# WHERE comment.id = :commentid",
            {commentid: {value: arguments.commentid, cfsqltype: "integer"}},
            {returnType: "array"}
        );
        if(!rows.len()) return;
        return withAuthor(rows[1]);
    }

    /**
     * Every blog's id and header, newest first - for the admin comment review filter
     */
    public array function getHeaders() {
        return queryExecute(
            "SELECT id, header FROM blog ORDER BY created DESC, id DESC",
            {},
            {returnType: "array"}
        );
    }

    /**
     * Datatable GET for the admin comment review - every comment, or one blog's
     * Rows: commentid, created, blogheader, blogslug, username, trainerid, comment, commentbanned
     *
     * @records  rows per page
     * @offset   rows to skip
     * @search   matched against the comment, blog header and trainer username
     * @orderCol sort column index (COMMENT_TABLE_COLS)
     * @orderDir asc/desc
     * @blogid   only this blog's comments - 0 for all
     */
    public struct function getCommentTable(
        required numeric records,
        required numeric offset,
        string search   = "",
        string orderCol = "",
        string orderDir = "",
        numeric blogid  = 0
    ) {
        var fromSQL = "
            FROM comment
            INNER JOIN blog ON blog.id = comment.blogid
            LEFT JOIN trainer ON trainer.id = comment.trainerid
        ";
        var filters = pagination.buildFilters(
            searchColumns = [
                "comment.comment",
                "blog.header",
                "trainer.username"
            ],
            search = arguments.search
        );
        if(arguments.blogid > 0) {
            filters.baseWhere          = pagination.appendWhere(filters.baseWhere, "comment.blogid = :blogid");
            filters.whereSQL           = pagination.appendWhere(filters.whereSQL, "comment.blogid = :blogid");
            filters.baseParams.blogid  = {value: arguments.blogid, cfsqltype: "integer"};
            filters.whereParams.blogid = {value: arguments.blogid, cfsqltype: "integer"};
        }

        var orderBy = pagination.orderBy(
            columns     = variables.COMMENT_TABLE_COLS,
            orders      = [{column: arguments.orderCol, dir: arguments.orderDir}],
            defaultSort = "comment.created DESC",
            tiebreak    = "comment.id DESC"
        );
        var whereSQL = filters.whereSQL;

        var page = pagination.paginate(
            records     = arguments.records,
            offset      = arguments.offset,
            fromSQL     = fromSQL,
            baseWhere   = filters.baseWhere,
            whereSQL    = whereSQL,
            baseParams  = filters.baseParams,
            whereParams = filters.whereParams,
            fetchRows   = (pageParams) => queryExecute(
                "
                SELECT comment.id, comment.created, comment.comment, comment.trainerid, blog.header AS blogheader,
                    COALESCE(trainer.username, '') AS username, COALESCE(trainer.commentbanned, false) AS commentbanned
                #fromSQL#
                #whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returnType: "array"}
            )
        );

        return {
            data: page.rows.map((row) => {
                return {
                    commentid    : row.id,
                    created      : dateTimeFormat(row.created, "short"),
                    blogheader   : row.blogheader,
                    blogslug     : getSlug(row.blogheader),
                    username     : row.username,
                    trainerid    : row.trainerid,
                    comment      : row.comment,
                    commentbanned: row.commentbanned ? true : false
                };
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
    }

    /**
     * Cache key for a page of blogs getBlogs loads
     *
     * @pageSize number of blogs
     * @offset   number of blogs skipped
     */
    private string function getBlogsCacheKey(required numeric pageSize, required numeric offset) {
        return "blog.getBlogs|pageSize=#arguments.pageSize#|offset=#arguments.offset#";
    }

    /**
     * Cache key for the blog getFromId loads
     *
     * @blogid blog pk
     */
    private string function getFromIdCacheKey(required numeric blogid) {
        return "blog.getFromId|blogid=#arguments.blogid#";
    }

    /**
     * Cache key for the blogid getFromSlug loads - slugs are unique ignoring case
     *
     * @slug the /readblog/ slug
     */
    private string function getFromSlugCacheKey(required string slug) {
        return "blog.getFromSlug|slug=#lCase(trim(arguments.slug))#";
    }

    /**
     * Cache key for the comments getComments loads
     *
     * @blogid blog pk
     */
    private string function getCommentsCacheKey(required numeric blogid) {
        return "blog.getComments|blogid=#arguments.blogid#";
    }

    /**
     * Evict every cached blog entry - lists, blogs, comments and image sizes - so the next load reads the database
     * Call after anything that changes a blog
     */
    public void function clearCache() {
        cache.clearByKeySnippet("blog.");
        return;
    }

    /**
     * A blog row as the views use it - its columns plus
     * excerpt (plain text, 200 chars), readpath (getReadPath), ogimage (full image url) and author (see withAuthor)
     *
     * @row BLOG_SELECT row
     */
    private struct function toBlog(required struct row) {
        var blog      = withAuthor(arguments.row);
        blog.excerpt  = buildExcerpt(blog.body ?: "", 200);
        blog.readpath = getReadPath(blog.header);
        blog.ogimage  = "#application.cbController.getSetting("domain")#/includes/uploads/full/#blog.image ?: ""#";
        return blog;
    }

    /**
     * Swap the joined authorusername/authoricon columns for an author struct - username, iconpath, iconalttext
     * author is empty when the row has no trainer
     *
     * @row row with authorusername and authoricon columns
     */
    private struct function withAuthor(required struct row) {
        var result    = duplicate(arguments.row);
        result.author = trainerService.buildAuthor(
            username = result.authorusername ?: "",
            icon     = result.authoricon ?: ""
        );
        result.delete("authorusername");
        result.delete("authoricon");
        return result;
    }

    /**
     * Plain-text excerpt of a blog body, stripped of all HTML
     * Jsoup handles tag removal, entity decoding, and whitespace collapsing
     *
     * @body   blog html body
     * @length maximum number of characters to return
     */
    private string function buildExcerpt(required string body, required numeric length) {
        if(!len(arguments.body)) {
            return "";
        }
        return left(jsoup.parse(arguments.body).text(), arguments.length);
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

    /**
     * Path to a blog's /readblog/ page - its slug (getSlug), URL encoded so any character in the header links safely
     *
     * @header the blog's stored header
     */
    public string function getReadPath(required string header) {
        return "/readblog/#encodeForURL(getSlug(arguments.header))#";
    }

    /**
     * Saves a new blog
     * The arguments have already passed the blog.write constraints - header is unique, the image was uploaded (imageUpload) and body is the parsed html
     *
     * A header whose slug matches another blog's (unq_blog_slug) throws UniqueViolation
     *
     * @trainerid pk of the admin writing it
     * @header    header
     * @meta      meta description
     * @image     uploaded image file name (imageUpload)
     * @alt       image alt text
     * @bodyjson  editor json
     * @body      body html
     */
    public void function create(
        required numeric trainerid,
        required string header,
        required string meta,
        required string image,
        required string alt,
        required string bodyjson,
        required string body
    ) {
        try {
            queryExecute(
                "
                INSERT INTO blog (header, meta, image, alttext, bodyjson, body, trainerid)
                VALUES (:header, :meta, :image, :alttext, :bodyjson, :body, :trainerid)
                ",
                {
                    header   : {value: trim(arguments.header), cfsqltype: "varchar"},
                    meta     : {value: arguments.meta, cfsqltype: "varchar"},
                    image    : {value: arguments.image, cfsqltype: "varchar"},
                    alttext  : {value: arguments.alt, cfsqltype: "varchar"},
                    bodyjson : {value: arguments.bodyjson, cfsqltype: "varchar"},
                    body     : {value: arguments.body, cfsqltype: "varchar"},
                    trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
                }
            );
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }

        // Clear the blog cache whenever a new entry is saved
        clearCache();
        return;
    }

    /**
     * Saves changes to an existing blog
     * The arguments have already passed the blog.edit constraints - the blog exists, header is unique ignoring this blog, and body is the parsed html
     *
     * A header whose slug matches another blog's (unq_blog_slug) throws UniqueViolation
     *
     * @trainerid pk of the admin editing it
     * @blogid    pk of the blog
     * @header    header
     * @meta      meta description
     * @image     new uploaded image file name (imageUpload) - empty keeps the current image
     * @alt       image alt text
     * @bodyjson  editor json
     * @body      body html
     */
    public void function edit(
        required numeric trainerid,
        required numeric blogid,
        required string header,
        required string meta,
        required string image,
        required string alt,
        required string bodyjson,
        required string body
    ) {
        // The image only changes when a new one was uploaded
        try {
            queryExecute(
                "
                UPDATE blog
                SET trainerid = :trainerid,
                    header    = :header,
                    meta      = :meta,
                    bodyjson  = :bodyjson,
                    body      = :body,
                    alttext   = :alttext,
                    image     = COALESCE(:image, image)
                WHERE id = :blogid
                ",
                {
                    trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                    header   : {value: trim(arguments.header), cfsqltype: "varchar"},
                    meta     : {value: arguments.meta, cfsqltype: "varchar"},
                    bodyjson : {value: arguments.bodyjson, cfsqltype: "varchar"},
                    body     : {value: arguments.body, cfsqltype: "varchar"},
                    alttext  : {value: arguments.alt, cfsqltype: "varchar"},
                    image    : {
                        value    : arguments.image,
                        cfsqltype: "varchar",
                        null     : !arguments.image.len()
                    },
                    blogid: {value: arguments.blogid, cfsqltype: "integer"}
                }
            );
        }
        catch(any e) {
            utilService.rethrowUniqueViolation(e);
        }

        // Clear the blog cache whenever a new entry is saved
        clearCache();
        return;
    }

    /**
     * A comment as it is stored - trimmed, with every line ending made \n
     *
     * @comment user comment
     */
    public string function normalizeComment(required string comment) {
        return trim(arguments.comment.replace(chr(13) & chr(10), chr(10), "all").replace(chr(13), chr(10), "all"));
    }

    /**
     * Adds a trainer's comment to a blog
     * Returns the new comment
     *
     * @trainerid trainerid
     * @blogid    blogid of an existing blog
     * @comment   comment, already normalized (normalizeComment) and validated
     */
    public struct function addComment(
        required numeric trainerid,
        required numeric blogid,
        required string comment
    ) {
        var inserted = queryExecute(
            "INSERT INTO comment (trainerid, blogid, comment) VALUES (:trainerid, :blogid, :comment) RETURNING id",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                blogid   : {value: arguments.blogid, cfsqltype: "integer"},
                comment  : {value: arguments.comment, cfsqltype: "varchar"}
            },
            {returnType: "array"}
        );

        // Only this blog's comment list - the blog itself stays cached
        cache.clear(getCommentsCacheKey(arguments.blogid));
        return getComment(inserted[1].id);
    }

    /**
     * Deletes a comment and bans its author from commenting
     * An admin deleting their own comment is not banned
     * Returns the deleted comment's blogid, or null when there was no such comment
     *
     * @commentid comment pk
     * @deletedBy pk of the admin deleting it
     */
    public any function deleteComment(required numeric commentid, required numeric deletedBy) {
        var deleted = [];
        var banned  = false;
        transaction {
            deleted = queryExecute(
                "DELETE FROM comment WHERE id = :commentid RETURNING trainerid, blogid, comment",
                {commentid: {value: arguments.commentid, cfsqltype: "integer"}},
                {returnType: "array"}
            );
            banned = deleted.len() && deleted[1].trainerid != arguments.deletedBy;
            if(banned) {
                setCommentBanned(deleted[1].trainerid);
            }
        }
        if(!deleted.len()) return;

        cache.clear(getCommentsCacheKey(deleted[1].blogid));
        trainerService.clearCache(deleted[1].trainerid);

        // Recorded against the admin who deleted it, with the comment, so a mistaken delete can be put right
        var outcome = banned ? "banned from commenting" : "not banned";
        auditComment(
            event     = variables.DELETED_COMMENT_EVENT,
            trainerid = arguments.deletedBy,
            detail    = "Deleted comment #arguments.commentid# by trainer #deleted[1].trainerid# (#outcome#): #deleted[1].comment#"
        );
        return deleted[1].blogid;
    }

    /**
     * Record a comment the banned word check blocked, and ban the trainer from commenting once
     * comments.profanityStrikes different blocked comments land within comments.strikeWindowDays
     *
     * Only the words around each banned word are recorded (profanity.getProfanityContext)
     *
     * @trainerid pk of the trainer who wrote it
     * @comment   the blocked comment, normalized
     *
     * @return {strikes, banned: whether this attempt banned them}
     */
    public struct function recordBlockedComment(required numeric trainerid, required string comment) {
        // The words around the banned words are the detail, so distinct details are distinct attempts
        // The whole comment when no banned word is found in it
        // Written before the count below, so this attempt is one of the strikes
        var context = profanityService.getProfanityContext(text = arguments.comment);
        auditComment(
            event     = variables.BLOCKED_COMMENT_EVENT,
            trainerid = arguments.trainerid,
            detail    = context.len() ? context : arguments.comment,
            wait      = true
        );

        var strikes = queryExecute(
            "
            SELECT COUNT(DISTINCT detail) AS strikes
            FROM audit
            WHERE trainerid = :trainerid
                AND event = :event
                AND created >= NOW() - MAKE_INTERVAL(days => :days)
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                event    : {value: variables.BLOCKED_COMMENT_EVENT, cfsqltype: "varchar"},
                days     : {value: commentSettings.strikeWindowDays, cfsqltype: "integer"}
            },
            {returnType: "array"}
        )[1].strikes;

        var trainer = trainerService.getFromId(arguments.trainerid);
        var banned  = strikes >= commentSettings.profanityStrikes
        && !trainer.commentbanned
        && trainer.securitylevel < permissions.admin;

        if(banned) {
            setCommentBanned(arguments.trainerid);
            trainerService.clearCache(arguments.trainerid);
            auditComment(
                event     = variables.COMMENT_BAN_EVENT,
                trainerid = arguments.trainerid,
                detail    = "Banned from commenting after #strikes# comments blocked for banned words in #commentSettings.strikeWindowDays# days"
            );
        }

        return {strikes: strikes, banned: banned};
    }

    /**
     * Flag the trainer as banned from commenting
     *
     * @trainerid pk of trainer
     */
    private void function setCommentBanned(required numeric trainerid) {
        queryExecute(
            "UPDATE trainer SET commentbanned = true WHERE id = :trainerid",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}}
        );
        return;
    }

    /**
     * Audit a comment moderation event for the current request
     *
     * @event     one of the comment audit events
     * @trainerid trainer the event is recorded against
     * @detail    what happened
     * @wait      insert before returning
     */
    private void function auditComment(
        required string event,
        required numeric trainerid,
        required string detail,
        boolean wait = false
    ) {
        var auditInfo    = auditService.getAuditObj(trainerid = arguments.trainerid, event = arguments.event);
        auditInfo.detail = arguments.detail;
        auditInfo.wait   = arguments.wait;
        auditService.audit(argumentCollection = auditInfo);
        return;
    }

    /**
     * Gets a struct of latest blog posts on the pokemon go website
     * The full scraped list is cached once and pages are sliced from it, so infinite scroll never re-scrapes
     *
     * @pageSize number of posts to return
     * @offset   number of posts to skip
     */
    public array function getNews(
        numeric pageSize = application.cbController.getSetting("fetchCount"),
        numeric offset   = 0
    ) {
        return pagination.slicePage(
            getNewsList(),
            arguments.offset,
            arguments.pageSize
        );
    }

    /**
     * Scrape and cache every news card on the pokemongo.com news page
     */
    private array function getNewsList() {
        return cache.getOrSet(
            variables.NEWS_LIST_KEY,
            () => {
                var news    = [];
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

                return news;
            },
            10,
            10
        );
    }

    /**
     * Build array of upcoming events from leekduck
     * The event list is scraped once and cached
     *
     * @pageSize number of events to add
     * @offset   number of upcoming events to skip
     */
    public array function getEvents(
        numeric pageSize = application.cbController.getSetting("fetchCount"),
        numeric offset   = 0
    ) {
        // Copy so the cached list entries are never mutated
        var events = pagination
            .slicePage(
                getEventList(),
                arguments.offset,
                arguments.pageSize
            )
            .map((event) => duplicate(event));

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
        return cache.getOrSet(
            variables.EVENT_LIST_KEY,
            () => {
                var events    = [];
                var baseUrl   = "https://leekduck.com";
                var eventsUrl = "https://leekduck.com/events/";

                var eventsDoc  = scraperService.getData(eventsUrl);
                var eventPosts = eventsDoc
                    .body()
                    .select("div.upcoming-events")
                    .select("span.event-header-item-wrapper");
                eventPosts.each((post) => {
                    var postTimestamp = parseDateTime(date = post.attr("data-event-date-sort"), timezone = "UTC");
                    if(dateDiff("h", postTimestamp, now()) >= 4) return;

                    events.append({
                        type: post
                            .select("a")
                            .select("div.event-item-wrapper")
                            .select("p")
                            ?.first()
                            ?.text() ?: "",
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

                return events;
            },
            10,
            10
        );
    }

    /**
     * Whether a leekduck event page is tagged location specific
     * An event's tags don't change, so this is cached per link for 12 hours
     *
     * @link full leekduck event url
     */
    private boolean function isLocationSpecific(required string link) {
        var eventLink = arguments.link;
        return cache.getOrSet("#variables.EVENT_LOCATION_KEY#|link=#eventLink#", () => !scraperService
            .getData(eventLink)
            .body()
            .select("div.page-tags")
            .select("div.tag.location-specific")
            .isEmpty(),
        720,
        720);
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

    /**
     * Pixel size of an uploaded image, read from its header once and cached
     * Lets views put width/height on the img so the page doesn't jump when it loads
     *
     * @path full path to the image
     *
     * @return {width, height}, empty when the file is missing or unreadable
     */
    public struct function getImageSize(required string path) {
        var imagePath = arguments.path;
        // Upload names are unique, so a file's size never changes
        return cache.getOrSet(
            "blog.getImageSize|#imagePath#",
            () => {
                try {
                    return imageService.getDimensions(imagePath);
                }
                catch(any e) {
                    return {};
                }
            },
            0,
            0
        );
    }

}
