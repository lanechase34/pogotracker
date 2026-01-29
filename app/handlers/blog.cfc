component extends="base" {

    this.allowedMethods = {
        get       : 'GET',
        read      : 'GET',
        addComment: 'POST',
        writeForm : 'GET',
        write     : 'POST',
        addImage  : 'POST',
        editForm  : 'GET',
        edit      : 'POST',
        getNews   : 'GET',
        getEvents : 'GET'
    };

    property name="blogService"    inject="services.blog";
    property name="imageService"   inject="services.image";
    property name="trainerService" inject="services.trainer";

    this.prehandler_only = 'read,writeForm,editForm';

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = 'Blog - #getSetting('title')#';
        prc.metaDescription = 'POGO Tracker blog. Read latest news about POGO Tracker.';
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
    function get(event, rc, prc) {
        rc.exclude = parseNumber(rc?.exclude ?: -1);
        if(hasValidationErrors(target = rc, constraints = 'blog.get')) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.blogs = blogService.get(count = rc.count, offset = rc.offset);
        event.setView(
            view     = '/views/blog/list',
            nolayout = true,
            args     = {
                blogs    : prc.blogs,
                showimage: booleanFormat(rc.showimage),
                offset   : rc.offset,
                exclude  : rc.exclude,
                sidebar  : booleanFormat(rc.sidebar)
            }
        );
    }

    /**
     * Read a blog post
     *
     * @rc.blogheader the blog's header (spaces replaced with - for URLs)
     */
    function read(event, rc, prc) {
        rc.blogheader = trim((rc?.blogheader ?: '')).replace('-', ' ', 'all');
        if(hasValidationErrors(target = rc, constraints = 'blog.read')) {
            htmlValidationFailure(event = event, redirectEvent = 'home');
            return;
        }

        /**
         * Attempt to load blog based on its header
         */
        prc.blog = blogService.getFromHeader(rc.blogheader);

        // Does not exist
        if(isNull(prc.blog)) {
            htmlNotFound(event);
            return;
        }

        prc.header          = '';
        prc.metaDescription = !isNull(prc.blog.getMeta()) ? prc.blog.getMeta() : '';
    }

    /**
     * Add a comment to a blog post
     *
     * @rc.comment trainer's comment
     * @rc.blogid  blog pk
     */
    function addComment(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'blog.addComment')) {
            jsonValidationFailure(event = event, message = 'Invalid Comment');
            return;
        }

        try {
            blogService.addComment(
                trainerid = session.trainerid,
                blogid    = parseNumber(rc.blogid),
                comment   = rc.comment
            );

            prc.responseObj.success    = true;
            prc.responseObj.statusCode = 200;
        }
        catch(EntityNotFound e) {
            jsonNotFound(event = event, message = e.message);
            return;
        }

        renderJson(event = event, response = prc.responseObj);
    }

    /**
     * Write a new blog form
     */
    function writeForm(event, rc, prc) {
        prc.header = 'New Blog';
        event.setView(view = '/views/blog/writeform', args = {editing: false, submit: '/blog/write'});
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
    function write(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'blog.write')) {
            jsonValidationFailure(event = event);
            return;
        }

        /**
         * Validate image upload and resize it
         */
        try {
            prc.image = imageService.validateUpload(formField = 'blogimage');
            imageService.resizeBlogImage(filename = prc.image);
        }
        catch(UploadValidationException e) {
            jsonValidationFailure(event = event, e.message);
            return;
        }

        prc.blogbody = safeDeserializeJSON(rc.blogbody);
        blogService.create(
            trainer  = trainerService.getFromId(trainerid = session.trainerid),
            header   = rc.blogheader,
            meta     = rc.blogmeta,
            image    = prc.image,
            alt      = rc.blogimagealt,
            bodyjson = rc.blogbodyjson,
            body     = prc.blogbody
        );
        jsonOk(event = event);
    }

    /**
     * Add an image inline to a blog post
     *
     * @rc.image image field
     */
    function addImage(event, rc, prc) {
        prc.responseObj.file = {};

        /**
         * Validate image
         */
        try {
            prc.image = imageService.validateUpload(
                formField = 'image',
                uploadDir = '#getSetting('uploadPath')#/extra/'
            );
        }
        catch(UploadValidationException e) {
            jsonValidationFailure(event = event, e.message);
            return;
        }

        prc.responseObj.file = {
            url: '/includes/uploads/extra/#prc.image#'
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
    function editForm(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'blog.editForm')) {
            htmlValidationFailure(event = event, redirectEvent = 'blog.writeForm');
            return;
        }

        prc.blog     = blogService.getFromId(parseNumber(rc.blogid));
        prc.bodyjson = prc.blog?.getBodyJson() ?: '{}';
        prc.header   = 'Editing Blog';

        event.setView(
            view = '/views/blog/writeform',
            args = {
                editing : true,
                blog    : prc.blog,
                submit  : '/blog/edit',
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
    function edit(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'blog.edit')) {
            jsonValidationFailure(event = event);
            return;
        }

        /**
         * Optional, attempt image upload if it changed
         */
        prc.image = '';
        if(rc.blogimage.len()) {
            try {
                prc.image = imageService.validateUpload(formField = 'blogimage');
                imageService.resizeBlogImage(filename = prc.image);
            }
            catch(UploadValidationException e) {
                jsonValidationFailure(event = event, e.message);
                return;
            }
        }

        prc.blogbody = safeDeserializeJSON(rc.blogbody);
        blogService.edit(
            trainer  = trainerService.getFromId(trainerid = session.trainerid),
            blogid   = parseNumber(rc.blogid),
            header   = rc.blogheader,
            meta     = rc.blogmeta,
            image    = prc.image,
            alt      = rc.blogimagealt,
            bodyjson = rc.blogbodyjson,
            body     = prc.blogbody
        );
        jsonOk(event = event);
    }

    /**
     * Get latest news from Pokemon Go's website
     */
    function getNews(event, rc, prc) {
        prc.news = blogService.getNews();
        event.setView(
            view     = '/views/blog/news',
            nolayout = true,
            args     = {news: prc.news}
        );
    }

    /**
     * Get upcoming events from LeekDuck
     */
    function getEvents(event, rc, prc) {
        prc.events = blogService.getEvents();
        event.setView(
            view     = '/views/blog/events',
            nolayout = true,
            args     = {events: prc.events}
        );
    }

}
