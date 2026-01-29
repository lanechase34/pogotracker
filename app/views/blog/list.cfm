<cfoutput>
<cfif args.sidebar>
    <div class="row row-cols-1">
        <cfif args.offset EQ 0>
            <div class="text-center">
                <h5><i class="bi bi-book-half me-1"></i>Recent Blogs</h5>
            </div>
        </cfif>
<cfelse>
    <div class="row row-cols-1 row-cols-lg-2">
</cfif>
<cfloop index="i" item="currBlog" array="#args.blogs#">
    <cfif args.exclude EQ currBlog.getId()><cfcontinue></cfif>
    <div class="d-flex justify-content-center col mb-3">
        <a href="/readblog/#replace(currBlog.getHeader(), " ", "-", "all")#" class="h-100 w-100 link-underline link-underline-opacity-0">
        <div class="card h-100 w-100 blogCard shadow-sm" data-linkto="/readblog/#currBlog.getId()#">
            <cfif args.showImage>
                <img src="/includes/uploads/cards/#currBlog.getImage()#" alt="#currBlog.getAltText()#" <cfif args.offset NEQ 0 OR i GT 3>loading="lazy"</cfif> class="blogImage rounded">
            </cfif>
            <article class="d-flex flex-column card-body">
                <p class="card-text text-secondary mb-1">
                    #dateFormat(currBlog.getCreated(), "mmm d, yyyy")#
                </p>
                <h4 class="card-title mb-3">
                    #currBlog.getHeader()#
                </h4>
                <p class="card-text">
                    #left(reReplaceNoCase(replace(replace(replace(currBlog.getBody(), "<p></p>", ". ", "all"), "<ul><li>", " ", "all"), "</li><li>", ". ", "all"), "<[^>]*>", " ", "all"), 100)#...
                </p>
                <div class="mt-auto blogLink">
                    Continue reading <i class="bi bi-chevron-right ms-2"></i>
                </div>
            </article>
        </div>
        </a>
    </div>
</cfloop>
</div>
</cfoutput>