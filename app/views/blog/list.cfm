<cfoutput>
<cfif args.sidebar>
    <div class="row row-cols-1">
<cfelse>
    <div class="row row-cols-1 row-cols-lg-2">
</cfif>
<cfloop index="i" item="currBlog" array="#args.blogs#">
    <cfif args.exclude EQ currBlog.id><cfcontinue></cfif>
    <div class="d-flex justify-content-center col mb-3">
        <a href="#encodeForHTMLAttribute(currBlog.readpath)#" class="h-100 w-100 link-underline link-underline-opacity-0">
        <div class="card h-100 w-100 blogCard">
            <cfif args.showImage>
                <img
                    src="/includes/uploads/cards/#encodeForHTMLAttribute(currBlog.image)#"
                    alt="#encodeForHTMLAttribute(currBlog.alttext)#"
                    <cfif args.offset EQ 0 AND i EQ 1 AND !args.sidebar>fetchpriority="high"</cfif>
                    <cfif args.offset NEQ 0 OR i GT 3>loading="lazy"</cfif>
                    class="blogImage rounded-top"
                >
            </cfif>
            <article class="d-flex flex-column card-body blog-card-body">
                <p class="blog-card-date">
                    <i class="bi bi-calendar3 me-1"></i>#dateFormat(currBlog.created, "mmm d, yyyy")#
                </p>
                <h4 class="blog-card-title">
                    #encodeForHTML(currBlog.header)#
                </h4>
                <p class="blog-card-excerpt">
                    #encodeForHTML(currBlog.excerpt)#&hellip;
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