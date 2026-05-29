<cfoutput>
<div class="row d-flex">
    <div class="col-12 col-lg-8 mt-3">
        <article class="card shadow-sm mb-3" id="blogData" data-blogid="#prc.blog.getId()#">
            <div class="px-4 pt-4">
                <img
                    src="/includes/uploads/full/#prc.blog.getImage()#"
                    alt="#prc.blog.getAltText()#"
                    class="blogImageMain rounded"
                >
            </div>
            <div class="card-body p-4">
                <h1 class="mb-3">#prc.blog.getHeader()#</h1>
                <div class="pb-3 mb-3 border-bottom">
                    #view(view="/views/blog/fragment/trainerinfo", args={trainer: prc.blog.getTrainer(), date: prc.blog.getBlogFormat()})#
                </div>
                <div class="blog-body">
                    #prc.blog.getBody()#
                </div>
            </div>
        </article>

        <div class="card shadow-sm mb-3">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-chat-left-text fs-5"></i>Comments (#prc.blog.getComment().len()#)
                </div>
                <cfif !prc.blog.getComment().len()>
                    <p class="text-muted small mb-0">No comments yet — be the first!</p>
                <cfelse>
                    <div class="d-flex flex-column gap-3 pt-1">
                        <cfloop item="currComment" index="i" array="#prc.blog.getComment()#">
                            <div>
                                #view(view="/views/blog/fragment/trainerinfo", args={trainer: currComment.getTrainer(), date: currComment.getBlogFormat()})#
                                <div class="bg-light rounded p-3 mt-2">
                                    <p class="mb-0 small">#encodeForHTML(deserializeJSON(currComment.getComment()))#</p>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </cfif>
            </div>
        </div>

        <div class="card shadow-sm mb-3">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-pencil-square fs-5"></i>Write A Comment
                </div>
                <div id="commentAlert"></div>
                <cfif !(session?.verified ?: false)>
                    <p class="text-muted small mb-0">Please <a href="/login" class="link-offset-2">login here</a> to comment.</p>
                <cfelse>
                    <textarea
                        name="blogComment"
                        class="form-control mb-3"
                        id="blogComment"
                        rows="6"
                        maxlength="1000"
                        placeholder="Share your thoughts..."
                    ></textarea>
                    <div class="d-flex">
                        <button type="button" id="submitBlogComment" class="ms-auto btn btn-dark btn-sm">
                            <i class="bi bi-chat-left-text me-1"></i>Add Comment
                        </button>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <aside class="col col-lg-4 mt-3">
        <div class="home-section-label">
            <i class="bi bi-book-half fs-5"></i>Recent Blogs
        </div>
        <div id="blogList" data-blogid="#prc.blog.getId()#"></div>
    </aside>
</div>
</cfoutput>
