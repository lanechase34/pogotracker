<cfoutput>
<cfif args.sidebar>
    <div class="row row-cols-1">
        <cfif args.offset EQ 0>
            <div class="home-section-label">
                <i class="bi bi-book-half fs-5"></i>Recent Blogs
            </div>
        </cfif>
<cfelse>
    <div class="row row-cols-1 row-cols-lg-2">
</cfif>
<cfloop index="i" item="currBlog" array="#args.blogs#">
    <cfif args.exclude EQ currBlog.getId()><cfcontinue></cfif>
    <div class="d-flex justify-content-center col mb-3">
        <a href="/readblog/#replace(currBlog.getHeader(), " ", "-", "all")#" class="h-100 w-100 link-underline link-underline-opacity-0">
        <div class="card h-100 w-100 blogCard" data-linkto="/readblog/#currBlog.getId()#">
            <cfif args.showImage>
                <img
                    src="/includes/uploads/cards/#currBlog.getImage()#"
                    alt="#currBlog.getAltText()#"
                    <cfif args.offset EQ 0 AND i EQ 0>fetchpriority="high"</cfif>
                    <cfif args.offset NEQ 0 OR i GT 3>loading="lazy"</cfif>
                    class="blogImage rounded-top"
                >
            </cfif>
            <article class="d-flex flex-column card-body blog-card-body">
                <p class="blog-card-date">
                    <i class="bi bi-calendar3 me-1"></i>#dateFormat(currBlog.getCreated(), "mmm d, yyyy")#
                </p>
                <h4 class="blog-card-title">
                    #currBlog.getHeader()#
                </h4>
                <p class="blog-card-excerpt">
                    #currBlog.getExcerpt(200)#&hellip;
                </p>
                <div class="mt-auto pt-2 blogLink">
                    <span class="blog-read-more">
                        Continue reading <i class="bi bi-arrow-right ms-1"></i>
                    </span>
                </div>
            </article>
        </div>
        </a>
    </div>
</cfloop>
</div>
</cfoutput>