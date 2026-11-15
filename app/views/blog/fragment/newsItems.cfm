<cfoutput>
<cfloop index="i" item="currNews" array="#args.news#">
    <a href="#reFindNoCase("^https?://", currNews.link) ? encodeForHTMLAttribute(currNews.link) : "##"#" target="_blank" rel="noopener noreferrer" class="list-group-item list-group-item-action ps-0 pe-3 py-3 newsItem">
        <div class="border-start border-3 border-dark ps-3">
            <span class="fw-semibold">#encodeForHTML(currNews.header)#</span>
        </div>
    </a>
</cfloop>
</cfoutput>