component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();
        mockTrainer = getInstance("tests.resources.mockTrainer");
        blogService = getInstance("services.blog");
        cache       = getInstance("cachebox:appCache");

        // A plain trainer whose comment gets deleted
        commenter = mockTrainer.make(autoLogin = false);
        // A plain trainer who keeps trying banned words
        striker   = mockTrainer.make(autoLogin = false);

        admin = mockTrainer.makeSignedIn(securityLevel = 50); // the edit form is admin only

        header = "Blog Test #left(createUUID().replace("-", "", "all"), 12)#";
    }

    function afterAll() {
        // The commenter first - their comments sit on the admin's blog
        mockTrainer.deleteTrainer(commenter.id);
        mockTrainer.deleteTrainer(striker.id);
        // The admin's blog and comment go with them
        mockTrainer.deleteTrainer(admin.id);
        blogService.clearCache();
        restoreBackgroundLogs();
        super.afterAll();
    }

    /**
     * Create the test blog through the service
     */
    private void function createBlog(required string blogHeader) {
        blogService.create(
            trainerid = admin.id,
            header    = arguments.blogHeader,
            meta      = "Blog test meta",
            image     = "blog-test.webp",
            alt       = "Blog test image",
            bodyjson  = "{}",
            body      = "<p>Hello <b>blog</b> &amp; readers</p>"
        );
    }

    function run() {
        describe("Blog", () => {
            beforeEach(() => {
                setup();
            });

            it("Creates a blog the services read back as a struct with its author", () => {
                createBlog(header);
                blogid = testData.findRow("blog", {header: header}).id;

                var blog = blogService.getFromId(blogid, false);
                expect(blog).toBeStruct();
                expect(blog.header).toBe(header);
                expect(blog.meta).toBe("Blog test meta");
                expect(blog.alttext).toBe("Blog test image");
                expect(blog.excerpt).toBe("Hello blog & readers");
                expect(blog.ogimage).toBe("#getController().getSetting("domain")#/includes/uploads/full/blog-test.webp");
                expect(blog.author.username).toBe(admin.username);
                expect(blog.author.iconpath).toInclude("/includes/images/icons/#admin.icon#");
                expect(blogService.getCommentPage(blogid = blogid, useCache = false).total).toBe(0);
                expect(dateDiff("s", blog.created, now())).toBeLT(30);
            });

            it("Finds a blog by its slug ignoring case, and returns null for an unknown slug", () => {
                expect(blogService.getFromSlug(uCase(blogService.getSlug(header))).id).toBe(blogid);
                expect(isNull(blogService.getFromSlug("No-Such-Blog-#createUUID()#"))).toBeTrue();
                expect(isNull(blogService.getFromId(-1, false))).toBeTrue();
            });

            it("Lists the newest blogs first", () => {
                var blogs = blogService.getBlogs(pageSize = 50, offset = 0);
                expect(blogs[1].id).toBe(blogid);
                expect(blogs[1]).toHaveKey("excerpt");
                expect(blogs[1].author.username).toBe(admin.username);
                // The list caches the excerpt, not every blog's full body
                expect(blogs[1]).notToHaveKey("body");
                expect(blogs[1]).notToHaveKey("bodyjson");
            });

            it("Rejects a second blog with the same header", () => {
                expect(() => createBlog(lCase(header))).toThrow("UniqueViolation");
            });

            it("Edits a blog and keeps its image when no new one is uploaded", () => {
                header &= " Edited";
                blogService.edit(
                    trainerid = admin.id,
                    blogid    = blogid,
                    header    = header,
                    meta      = "Edited meta",
                    image     = "",
                    alt       = "Edited alt",
                    bodyjson  = "{}",
                    body      = "<p>Edited</p>"
                );

                var row = testData.getRowById("blog", blogid);
                expect(row.header).toBe(header);
                expect(row.meta).toBe("Edited meta");
                expect(row.alttext).toBe("Edited alt");
                expect(row.body).toBe("<p>Edited</p>");
                expect(row.image).toBe("blog-test.webp");
                expect(row.updated).toBeGTE(row.created);
            });

            it("Adds a comment as plain text that the blog reads back with its author", () => {
                var added = blogService.addComment(
                    trainerid = admin.id,
                    blogid    = blogid,
                    comment   = "Great <script>alert(1)</script>post#chr(10)#Line two"
                );
                expect(added.comment).toBe("Great <script>alert(1)</script>post#chr(10)#Line two");
                expect(added.author.username).toBe(admin.username);

                var page = blogService.getCommentPage(blogid = blogid);
                expect(page.total).toBe(1);
                expect(page.remaining).toBe(0);
                expect(page.comments[1].id).toBe(added.id);
                expect(page.comments[1].comment).toBe(added.comment);
            });

            it("Renders the read page with the blog, its author and its comment escaped", () => {
                var html = get(route = "/readblog/#blogService.getSlug(header)#", renderResults = true).getRenderedContent();
                expect(html).toInclude(header);
                expect(html).toInclude("<p>Edited</p>");
                expect(html).toInclude(encodeForHTML(admin.username));
                expect(html).toInclude("id=""commentCount"">1<");
                expect(html).toInclude(encodeForHTML("Great <script>alert(1)</script>post"));
                expect(html).notToInclude("<script>alert(1)</script>");
                // Admins get the delete button
                expect(html).toInclude("deleteComment");
            });

            it("Renders the blog list", () => {
                var html = get(
                    route  = "/blog/getBlogs",
                    params = {
                        count    : 6,
                        offset   : 0,
                        showimage: true,
                        exclude  : -1,
                        sidebar  : false
                    },
                    renderResults = true
                ).getRenderedContent();
                expect(html).toInclude(header);
                expect(html).toInclude("/readblog/#blogService.getSlug(header)#");
            });

            it("Rejects a blog list page the site never requests", () => {
                // Each count/offset pair is its own cache entry, so arbitrary pairs can't fill the cache
                [
                    {count: 5, offset: 0},
                    {count: 8, offset: 8},
                    {count: 2, offset: 0},
                    {count: 6, offset: 7},
                    {count: 6, offset: 3}
                ].each((page) => {
                    var event = get(
                        route  = "/blog/getBlogs",
                        params = {
                            count    : page.count,
                            offset   : page.offset,
                            showimage: true,
                            exclude  : -1,
                            sidebar  : false
                        }
                    );
                    expect(event.getStatusCode()).toBe(400, serializeJSON(page));
                });
            });

            it("Allows the blog list pages the site requests", () => {
                [
                    {count: 6, offset: 0},
                    {count: 8, offset: 0},
                    {count: 2, offset: 6},
                    {count: 6, offset: 6},
                    {count: 6, offset: 8},
                    {count: 6, offset: 12},
                    {count: 6, offset: 14}
                ].each((page) => {
                    var event = get(
                        route  = "/blog/getBlogs",
                        params = {
                            count    : page.count,
                            offset   : page.offset,
                            showimage: true,
                            exclude  : -1,
                            sidebar  : false
                        }
                    );
                    expect(event.getStatusCode()).toBe(200, serializeJSON(page));
                });
            });

            it("Doesn't cache a blog list page past the last blog", () => {
                var pastEnd = blogService.getBlogCount() + 6;
                expect(blogService.getBlogs(pageSize = 6, offset = pastEnd)).toBeEmpty();
                expect(cache.lookup("blog.getBlogs|pageSize=6|offset=#pastEnd#")).toBeFalse();
            });

            it("Renders the edit form filled with the blog", () => {
                var html = get(route = "/editblog/#blogid#", renderResults = true).getRenderedContent();
                expect(html).toInclude("value=""#header#""");
                expect(html).toInclude("value=""Edited meta""");
                expect(html).toInclude("value=""#blogid#""");
            });

            it("Normalizes a comment's line endings and trims it", () => {
                expect(blogService.normalizeComment("  one#chr(13)##chr(10)#two#chr(13)#three  ")).toBe(
                    "one#chr(10)#two#chr(10)#three"
                );
            });

            it("Saves a full length comment full of quotes", () => {
                var added = blogService.addComment(
                    trainerid = admin.id,
                    blogid    = blogid,
                    comment   = repeatString("""", 1000)
                );
                expect(len(added.comment)).toBe(1000);
                blogService.deleteComment(commentid = added.id, deletedBy = admin.id);
            });

            it("Keeps the cached blog when a comment is added", () => {
                blogService.getFromId(blogid);
                var before = blogService.getCommentPage(blogid = blogid).total;

                var added = blogService.addComment(
                    trainerid = admin.id,
                    blogid    = blogid,
                    comment   = "Cache check"
                );
                expect(cache.get("blog.getFromId|blogid=#blogid#")).notToBeNull();
                expect(blogService.getCommentPage(blogid = blogid).total).toBe(before + 1);

                blogService.deleteComment(commentid = added.id, deletedBy = admin.id);
                expect(blogService.getCommentPage(blogid = blogid).total).toBe(before);
            });

            it("Caches only the slug's blogid, so the blog itself is cached once", () => {
                blogService.getFromSlug(blogService.getSlug(header));
                expect(cache.get("blog.getFromSlug|slug=#lCase(blogService.getSlug(header))#")).toBe(blogid);
            });

            it("Pages comments newest first, each page oldest to newest, with older pages on demand", () => {
                var pageSize = getController().getSetting("comments").pageSize;
                var before   = blogService.getCommentPage(blogid = blogid, useCache = false).total;
                var added    = [];
                for(var i = 1; i <= pageSize + 2; i++) {
                    added.append(
                        blogService.addComment(
                            trainerid = admin.id,
                            blogid    = blogid,
                            comment   = "Page comment #i#"
                        ).id
                    );
                }

                var first = blogService.getCommentPage(blogid = blogid);
                expect(first.total).toBe(before + pageSize + 2);
                expect(first.comments).toHaveLength(pageSize);
                expect(first.remaining).toBe(first.total - pageSize);
                // Newest last, so a new comment goes at the bottom by the comment box
                expect(first.comments.last().id).toBe(added.last());
                expect(first.comments[1].id).toBe(first.oldestid);

                var older = blogService.getCommentPage(blogid = blogid, beforeid = first.oldestid);
                expect(older.comments.len()).toBe(min(pageSize, first.remaining));
                expect(older.comments.last().id).toBeLT(first.oldestid);
                expect(older.remaining).toBe(first.remaining - older.comments.len());

                for(var commentid in added) {
                    blogService.deleteComment(commentid = commentid, deletedBy = admin.id);
                }
                expect(blogService.getCommentPage(blogid = blogid).total).toBe(before);
            });

            it("Lists comments for the admin review, filtered to one blog", () => {
                var added = blogService.addComment(
                    trainerid = admin.id,
                    blogid    = blogid,
                    comment   = "Review me"
                );
                var table = blogService.getCommentTable(
                    records = 10,
                    offset  = 0,
                    search  = "Review me",
                    blogid  = blogid
                );
                expect(table.recordsFiltered).toBe(1);
                expect(table.data[1].commentid).toBe(added.id);
                expect(table.data[1].blogheader).toBe(header);
                expect(table.data[1].username).toBe(admin.username);

                // 0 - every blog's comments
                expect(blogService.getCommentTable(records = 10, offset = 0, blogid = 0).recordsTotal).toBeGTE(1);
                blogService.deleteComment(commentid = added.id, deletedBy = admin.id);
            });

            it("Renders the admin comment review page", () => {
                var html = get(
                    route         = "/admin/comments",
                    params        = {blogid: blogid},
                    renderResults = true
                ).getRenderedContent();
                expect(html).toInclude("id=""commentsTable""");
                expect(html).toInclude("value=""#blogid#"" selected");
            });

            it("Bans a trainer after enough different blocked comments, ignoring resubmits", () => {
                var strikes = getController().getSetting("comments").profanityStrikes;

                // The same text twice is one strike
                blogService.recordBlockedComment(trainerid = striker.id, comment = "blocked 1");
                expect(blogService.recordBlockedComment(trainerid = striker.id, comment = "blocked 1").strikes).toBe(1);

                for(var i = 2; i < strikes; i++) {
                    expect(blogService.recordBlockedComment(trainerid = striker.id, comment = "blocked #i#").banned).toBeFalse();
                }
                var last = blogService.recordBlockedComment(trainerid = striker.id, comment = "blocked #strikes#");
                expect(last.strikes).toBe(strikes);
                expect(last.banned).toBeTrue();
                expect(mockTrainer.getSaved(striker.id).commentbanned).toBeTrue();
                expect(testData.findRows("audit", {trainerid: striker.id, event: "blog.commentBanned"})).toHaveLength(1);
            });

            it("Never bans an admin for blocked comments", () => {
                var strikes = getController().getSetting("comments").profanityStrikes;
                for(var i = 1; i <= strikes; i++) {
                    expect(blogService.recordBlockedComment(trainerid = admin.id, comment = "admin blocked #i#").banned).toBeFalse();
                }
                expect(mockTrainer.getSaved(admin.id).commentbanned).toBeFalse();
            });

            it("Bans a trainer whose comment an admin deletes, but not an admin deleting their own", () => {
                var added = blogService.addComment(
                    trainerid = commenter.id,
                    blogid    = blogid,
                    comment   = "Bad comment"
                );
                expect(blogService.deleteComment(commentid = added.id, deletedBy = admin.id)).toBe(blogid);
                expect(isNull(blogService.getComment(added.id))).toBeTrue();
                expect(mockTrainer.getSaved(commenter.id).commentbanned).toBeTrue();

                var own = blogService.addComment(
                    trainerid = admin.id,
                    blogid    = blogid,
                    comment   = "My own comment"
                );
                blogService.deleteComment(commentid = own.id, deletedBy = admin.id);
                expect(mockTrainer.getSaved(admin.id).commentbanned).toBeFalse();

                // Already gone
                expect(isNull(blogService.deleteComment(commentid = added.id, deletedBy = admin.id))).toBeTrue();
            });

            it("Shows a banned trainer that they can no longer comment", () => {
                mockTrainer.actAs(commenter);
                mockTrainer.refresh(commenter.id);
                var html = get(route = "/readblog/#blogService.getSlug(header)#", renderResults = true).getRenderedContent();
                expect(html).toInclude("You can no longer comment.");
                expect(html).notToInclude("id=""blogComment""");
                expect(html).notToInclude("deleteComment");
                mockTrainer.actAs(admin);
            });
        });
    }

}
