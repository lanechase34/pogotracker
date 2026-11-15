component extends="base" {

    this.allowedMethods = {
        getBlogs     : "GET",
        read         : "GET",
        getComments  : "GET",
        addComment   : "POST",
        deleteComment: "POST",
        writeForm    : "GET",
        write        : "POST",
        addImage     : "POST",
        editForm     : "GET",
        edit         : "POST",
        getNews      : "GET",
        getEvents    : "GET"
    };

    property name="blogService"    inject="services.blog";
    property name="imageService"   inject="Helpers@ImageMagick";
    property name="seoService"     inject="services.seo";
    property name="trainerService" inject="services.trainer";

    this.prehandler_only = "read,writeForm,editForm";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = "Blog | #getSetting("title")#";
        prc.metaDescription = "POGO Tracker blog. Read latest news about POGO Tracker.";
        prc.metaRobots      = "noindex, nofollow";
    }

    /**
     * Lists out paginated (scroll) blogs
     *
     * @rc.count     numeric count
     * @rc.offset    numeric offset
     * @rc.showimage t/f show blog image
     * @rc.exclude   (optional) numeric exclude blog by pk, defaults to no excluded blogs
     * @rc.sidebar   t/f whether this is a sidebar view
     */
    function getBlogs(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "blog.getBlogs")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.offset = parseNumber(rc.offset);
        prc.blogs  = blogService.getBlogs(pageSize = parseNumber(rc.count), offset = prc.offset);
        event.setView(
            view     = "/views/blog/list",
            nolayout = true,
            args     = {
                blogs    : prc.blogs,
                showimage: booleanFormat(rc.showimage),
                offset   : prc.offset,
                exclude  : parseNumber(rc.exclude),
                sidebar  : booleanFormat(rc.sidebar)
            }
        );
    }

    /**
     * Read a blog post
     *
     * @rc.blogheader the blog's slug - its header with spaces replaced with
     */
    function read(event, rc, prc) {
        rc.blogheader = trim((rc?.blogheader ?: ""));
        if(hasValidationErrors(target = rc, constraints = "blog.read")) {
            htmlValidationFailure(event = event, redirectEvent = "home");
            return;
        }

        /**
         * Attempt to load blog based on its slug
         */
        prc.blog = blogService.getFromSlug(slug = rc.blogheader);

        // Does not exist
        if(isNull(prc.blog)) {
            event.setLayout("basic");
            htmlNotFound(event = event);
            return;
        }

        // One url per post - any other casing permanently redirects to the slug built from the stored header
        if(compare(rc.blogheader, blogService.getSlug(header = prc.blog.header)) != 0) {
            relocate(uri = prc.blog.readpath, statusCode = 301);
            return;
        }
        prc.canonicalURL = "#getSetting("domain")##prc.blog.readpath#";
        prc.imageSize    = blogService.getImageSize(path = "#getSetting("uploadPath")#/full/#prc.blog.image#");

        prc.header          = "";
        prc.title           = "#prc.blog.header# | #getSetting("siteName")#";
        prc.metaDescription = !isNull(prc.blog.meta) && prc.blog.meta.len() ? prc.blog.meta : prc.title;
        prc.metaRobots      = "index, follow";
        prc.ogImage         = prc.blog.ogimage;
        prc.suppressH1      = true; // article provides its own h1 inside the card
        prc.structuredData  = seoService.getBlogPosting(blog = prc.blog, pageURL = prc.canonicalURL);

        // The newest page of comments
        prc.commentPage = blogService.getCommentPage(blogid = prc.blog.id);

        // Who can write and delete comments
        prc.canComment    = prc?.oCurrentUser?.hasPermission("user") ?: false;
        prc.commentBanned = prc.canComment && trainerService.getFromId(trainerid = prc.oCurrentUser.getId()).commentbanned;
        prc.canModerate   = prc?.oCurrentUser?.hasPermission("admin") ?: false;
    }

    /**
     * The page of a blog's comments before one already shown, rendered for the page to put above the others
     *
     * @rc.blogid   blog pk
     * @rc.beforeid the oldest comment already shown
     */
    function getComments(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "blog.getComments")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.commentPage = blogService.getCommentPage(
            blogid   = parseNumber(rc.blogid),
            beforeid = parseNumber(rc.beforeid)
        );

        jsonOk(
            event = event,
            data  = {
                html: view(
                    view = "/views/blog/fragment/comments",
                    args = {
                        comments : prc.commentPage.comments,
                        canDelete: prc?.oCurrentUser?.hasPermission("admin") ?: false
                    }
                ),
                remaining: prc.commentPage.remaining,
                oldestid : prc.commentPage.oldestid
            }
        );
    }

    /**
     * Add a comment to a blog post
     * Returns the rendered comment for the page to append
     *
     * @rc.comment trainer's comment
     * @rc.blogid  blog pk
     */
    function addComment(event, rc, prc) secured="user" {
        param name="rc.comment" default="";
        rc.comment= blogService.normalizeComment(comment = rc.comment);

        // Checked first - a banned trainer's attempts aren't validated or counted
        if(trainerService.getFromId(trainerid = prc.oCurrentUser.getId()).commentbanned) {
            commentBannedFailure(event = event);
            return;
        }

        prc.validation = validate(target = rc, constraints = "blog.addComment");
        if(prc.validation.hasErrors()) {
            // A bad blogid is a bad request - otherwise the comment's own messages say what to fix
            if(prc.validation.getFieldErrors("blogid").len()) {
                jsonValidationFailure(event = event, message = "Invalid Comment");
                return;
            }

            var commentErrors = prc.validation.getFieldErrors("comment");
            var message       = commentErrors[1].getMessage();

            // Banned words count toward a ban from commenting
            if(commentErrors.some((error) => error.getValidationType() == "profanityCheck")) {
                var blocked = blogService.recordBlockedComment(
                    trainerid = prc.oCurrentUser.getId(),
                    comment   = rc.comment
                );
                if(blocked.banned) {
                    commentBannedFailure(event = event);
                    return;
                }
                message = "Please remove the inappropriate language and try again. Repeated attempts will stop you from commenting.";
            }

            jsonValidationFailure(event = event, message = message);
            return;
        }

        prc.comment = blogService.addComment(
            trainerid = prc.oCurrentUser.getId(),
            blogid    = parseNumber(rc.blogid),
            comment   = rc.comment
        );

        jsonOk(
            event = event,
            data  = {
                html: view(
                    view = "/views/blog/fragment/comments",
                    args = {comments: [prc.comment], canDelete: prc.oCurrentUser.hasPermission("admin")}
                )
            }
        );
    }

    /**
     * Delete a comment and ban its author from commenting
     *
     * @rc.commentid comment pk
     */
    function deleteComment(event, rc, prc) secured="admin" {
        if(hasValidationErrors(target = rc, constraints = "blog.deleteComment")) {
            jsonValidationFailure(event = event, message = "Invalid Comment");
            return;
        }

        var blogid = blogService.deleteComment(
            commentid = parseNumber(rc.commentid),
            deletedBy = prc.oCurrentUser.getId()
        );
        if(isNull(blogid)) {
            jsonNotFound(event = event, message = "That comment was already deleted.");
            return;
        }

        jsonOk(event = event);
    }

    /**
     * 403 for a trainer banned from commenting - banned tells the page to swap the comment box for the notice
     */
    private void function commentBannedFailure(required any event) {
        renderJson(
            event    = arguments.event,
            response = {
                success   : false,
                banned    : true,
                message   : "You can no longer comment.",
                statusCode: 403
            }
        );
        return;
    }

    /**
     * Write a new blog form
     */
    function writeForm(event, rc, prc) secured="admin" {
        prc.header = "New Blog";
        event.setView(view = "/views/blog/writeForm", args = {editing: false, submit: "/blog/write"});
    }

    /**
     * Saves a new blog
     *
     * @rc.blogheader   header
     * @rc.blogmeta     meta
     * @rc.blogimage    image
     * @rc.blogimagealt image alt text
     * @rc.blogbodyjson body json
     * @rc.blogbody     body html
     */
    function write(event, rc, prc) secured="admin" {
        if(hasValidationErrors(target = rc, constraints = "blog.write")) {
            jsonValidationFailure(event = event);
            return;
        }

        /**
         * Validate image upload and resize it
         */
        try {
            prc.image = blogService.imageUpload();
        }
        catch(ImageMagick.UploadValidationException e) {
            jsonValidationFailure(event = event, message = e.message);
            return;
        }

        prc.blogbody = safeDeserializeJSON(json = rc.blogbody);
        try {
            blogService.create(
                trainerid = prc.oCurrentUser.getId(),
                header    = rc.blogheader,
                meta      = rc.blogmeta,
                image     = prc.image,
                alt       = rc.blogimagealt,
                bodyjson  = rc.blogbodyjson,
                body      = prc.blogbody
            );
        }
        catch(UniqueViolation e) {
            jsonValidationFailure(event = event, message = e.message);
            return;
        }
        jsonOk(event = event);
    }

    /**
     * Add an image inline to a blog post
     *
     * @rc.image image field
     */
    function addImage(event, rc, prc) secured="admin" {
        prc.responseObj.file = {};

        /**
         * Validate image
         */
        try {
            // Convert to webp
            prc.image = imageService.validateUpload(
                formField  = "image",
                outputs    = [{uploadDir: "#getSetting("uploadPath")#/extra/", type: "webp"}],
                autoOrient = true
            );

            // Add .webp extension to the filename
            prc.image &= ".webp";
        }
        catch(ImageMagick.UploadValidationException e) {
            jsonValidationFailure(event = event, message = e.message);
            return;
        }

        prc.responseObj.file = {
            url: "/includes/uploads/extra/#prc.image#"
            // additional properties here
        };

        prc.responseObj.success    = true;
        prc.responseObj.statusCode = 200;
        renderJson(event = event, response = prc.responseObj);
    }

    /**
     * Edit form for an existing blog
     *
     * @rc.blogid blog pk
     */
    function editForm(event, rc, prc) secured="admin" {
        if(hasValidationErrors(target = rc, constraints = "blog.editForm")) {
            htmlValidationFailure(event = event, redirectEvent = "blog.writeForm");
            return;
        }

        prc.blog     = blogService.getFromId(blogid = parseNumber(rc.blogid));
        prc.bodyjson = prc.blog?.bodyjson ?: "{}";
        prc.header   = "Editing Blog";

        event.setView(
            view = "/views/blog/writeForm",
            args = {
                editing : true,
                blog    : prc.blog,
                submit  : "/blog/edit",
                bodyJson: prc.bodyjson
            }
        );
    }

    /**
     * Edit an existing blog
     *
     * @rc.blogid       blog pk
     * @rc.blogheader   header
     * @rc.blogmeta     meta
     * @rc.blogimage    (optional) image
     * @rc.blogimagealt image alt text
     * @rc.blogbodyjson body json
     * @rc.blogbody     body html
     */
    function edit(event, rc, prc) secured="admin" {
        if(hasValidationErrors(target = rc, constraints = "blog.edit")) {
            jsonValidationFailure(event = event);
            return;
        }

        /**
         * Optional, attempt image upload if it changed
         */
        prc.image = "";
        if(rc.blogimage.len()) {
            try {
                prc.image = blogService.imageUpload();
            }
            catch(ImageMagick.UploadValidationException e) {
                jsonValidationFailure(event = event, message = e.message);
                return;
            }
        }

        prc.blogbody = safeDeserializeJSON(json = rc.blogbody);
        try {
            blogService.edit(
                trainerid = prc.oCurrentUser.getId(),
                blogid    = parseNumber(rc.blogid),
                header    = rc.blogheader,
                meta      = rc.blogmeta,
                image     = prc.image,
                alt       = rc.blogimagealt,
                bodyjson  = rc.blogbodyjson,
                body      = prc.blogbody
            );
        }
        catch(UniqueViolation e) {
            jsonValidationFailure(event = event, message = e.message);
            return;
        }
        jsonOk(event = event);
    }

    /**
     * Get latest news from Pokemon Go's website
     */
    function getNews(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "blog.getNews")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.offset = parseNumber(rc.offset);
        prc.count  = getSetting("fetchCount");
        prc.news   = blogService.getNews(pageSize = prc.count, offset = prc.offset);

        // Load more requests only need the news items to append to the existing card
        event.setView(
            view     = prc.offset ? "/views/blog/fragment/newsItems" : "/views/blog/news",
            nolayout = true,
            args     = {news: prc.news, count: prc.count}
        );
    }

    /**
     * Get upcoming events from LeekDuck
     */
    function getEvents(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "blog.getEvents")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.offset = parseNumber(rc.offset);
        prc.count  = getSetting("fetchCount");
        prc.events = blogService.getEvents(pageSize = prc.count, offset = prc.offset);

        // Load more requests only need the event items to append to the existing card
        event.setView(
            view     = prc.offset ? "/views/blog/fragment/eventItems" : "/views/blog/events",
            nolayout = true,
            args     = {events: prc.events, count: prc.count}
        );
    }

}
