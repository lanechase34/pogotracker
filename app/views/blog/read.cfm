<cfoutput>
<div class="row d-flex">
    <div class="col-12 col-lg-8 mt-3">
        <article class="card mb-3 shadow-sm" id="blogData" data-blogid="#prc.blog.getId()#">
            <div class="d-flex justify-content-center mb-1">
                <div>
                    <img src="/includes/uploads/full/#prc.blog.getImage()#" alt="#prc.blog.getAltText()#" class="blogImageMain rounded">
                </div>
            </div>
            <div class="card-body">
                <h2 class="card-title mb-3">
                    #prc.blog.getHeader()#
                </h2>
                #view(
                    view="/views/blog/fragment/trainerinfo", 
                    args={trainer: prc.blog.getTrainer(), date: prc.blog.getBlogFormat()}
                )#
                <hr>
                <p class="card-text">
                    #prc.blog.getBody()#
                </p>
            </div>
        </article>
        <article class="card mb-3 shadow-sm">
            <div class="card-body">
                <h5 class="card-title mb-3">
                    Comments (#prc.blog.getComment().len()#)
                </h5>
                <hr>
                <p class="card-text">
                    <cfif !prc.blog.getComment().len()>
                        No comments - starting writing one!
                    <cfelse>
                        <cfloop item="currComment" index="i" array="#prc.blog.getComment()#">
                            <div class="mb-3">
                                #view(
                                    view="/views/blog/fragment/trainerinfo", 
                                    args={trainer: currComment.getTrainer(), date: currComment.getBlogFormat()}
                                )#
                                <div class="card bg-light">
                                    <p class="p-3 card-text">
                                        #deserializeJSON(currComment.getComment())#
                                    </p>
                                </div>
                            </div>
                        </cfloop>
                    </cfif>
                </p>
            </div>
        </article>
        <div class="card mb-3 shadow-sm">
            <div class="card-body">
                <h5 class="card-title mb-3">
                    Write A Comment
                </h5>
                <div id="commentAlert"></div>
                <div class="card-text">
                    <cfif !(session?.verified ?: false)>
                        Please <a href="/login" class="link-opacity-75-hover link-offset-2">login here</a> to comment.
                    <cfelse>
                        <textarea 
                            name="blogComment"
                            class="form-control mb-3" 
                            id="blogComment"
                            rows="8"
                            maxlength="1000"
                        ></textarea>

                        <div class="card-text d-flex">
                            <button type="button" id="submitBlogComment" class="ms-auto btn btn-dark">
                                <i class="bi bi-chat-left-text me-1"></i>
                                Add Comment
                            </button>
                        </div>
                    </cfif>
                </div> 
            </div>
        </div>
    </div>
    <aside class="col col-lg-4 mt-3">
        <div id="blogList" data-blogid="#prc.blog.getId()#">
        </div>
    </aside>
</div>
</cfoutput>