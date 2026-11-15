<cfoutput>
<div class="row d-flex">
    <div class="col-12 col-lg-8 mt-3">
        <article class="card shadow-sm mb-3" id="blogData" data-blogid="#prc.blog.id#">
            <div class="px-4 pt-4">
                <img
                    src="/includes/uploads/full/#prc.blog.image#"
                    alt="#prc.blog.alttext#"
                    <!--- Attributes give the aspect ratio, the width caps it at the 350px max-height so the box is reserved before it loads --->
                    <cfif prc.imageSize.keyExists("width") AND prc.imageSize.height GT 0>
                        width="#prc.imageSize.width#"
                        height="#prc.imageSize.height#"
                        style="width: min(100%, #round(min(350, prc.imageSize.height) * prc.imageSize.width / prc.imageSize.height)#px)"
                    </cfif>
                    fetchpriority="high"
                    class="blogImageMain rounded"
                >
            </div>
            <div class="card-body p-4">
                <h1 class="mb-3">#prc.blog.header#</h1>
                <div class="pb-3 mb-3 border-bottom">
                    #view(view="/views/blog/fragment/trainerInfo", args={author: prc.blog.author, date: dateFormat(prc.blog.created, "mmm d, yyyy")})#
                </div>
                <div class="blog-body">
                    #prc.blog.body#
                </div>
            </div>
        </article>

        <div class="card shadow-sm mb-3">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-chat-left-text fs-5"></i>Comments (<span id="commentCount">#prc.commentPage.total#</span>)
                    <cfif prc.canModerate>
                        <a href="/admin/comments?blogid=#prc.blog.id#" class="ms-auto small link-offset-2">Review all</a>
                    </cfif>
                </div>
                <p id="noComments" class="text-muted small mb-0<cfif prc.commentPage.total> d-none</cfif>">No comments yet — be the first!</p>
                <!--- Older comments load above the newest page, oldest first --->
                <button
                    type="button"
                    id="olderComments"
                    class="btn btn-outline-dark btn-sm w-100 mb-2<cfif !prc.commentPage.remaining> d-none</cfif>"
                    data-beforeid="#prc.commentPage.oldestid#"
                >
                    Show older comments (<span id="olderCommentCount">#prc.commentPage.remaining#</span>)
                </button>
                <div id="commentList" class="d-flex flex-column gap-3 pt-1">
                    #view(view="/views/blog/fragment/comments", args={comments: prc.commentPage.comments, canDelete: prc.canModerate})#
                </div>
            </div>
        </div>

        <div class="card shadow-sm mb-3">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-pencil-square fs-5"></i>Write A Comment
                </div>
                <div id="commentAlert"></div>
                <cfif !prc.canComment>
                    <p class="text-muted small mb-0">Please <a href="/login" class="link-offset-2">login here</a> to comment.</p>
                <cfelseif prc.commentBanned>
                    <p class="text-muted small mb-0">You can no longer comment.</p>
                <cfelse>
                    <div id="commentCompose">
                        <textarea
                            name="blogComment"
                            class="form-control"
                            id="blogComment"
                            rows="6"
                            maxlength="1000"
                            placeholder="Share your thoughts..."
                            aria-describedby="blogCommentCount"
                        ></textarea>
                        <div class="d-flex align-items-center mt-2">
                            <small id="blogCommentCount" class="text-muted">0 / 1000</small>
                            <button type="button" id="submitBlogComment" class="ms-auto btn btn-dark btn-sm" disabled>
                                <i class="bi bi-chat-left-text me-1"></i>Add Comment
                            </button>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <aside class="col col-lg-4 mt-3">
        <div class="home-section-label">
            <i class="bi bi-book-half fs-5"></i>Recent Blogs
        </div>
        <div id="blogList" data-blogid="#prc.blog.id#"></div>
    </aside>
</div>
</cfoutput>
