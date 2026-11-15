<cfoutput>
<cfloop index="i" item="currEvent" array="#args.events#">
    <a href="#reFindNoCase("^https?://", currEvent.link) ? encodeForHTMLAttribute(currEvent.link) : "##"#" target="_blank" rel="noopener noreferrer" class="list-group-item list-group-item-action ps-0 pe-3 py-3 eventItem">
        <div class="border-start border-3 border-dark ps-3">
            <span class="d-block fw-semibold lh-sm mb-1">#encodeForHTML(currEvent.title)#</span>
            <small class="text-muted">#encodeForHTML(currEvent.timestamp)#</small>
        </div>
    </a>
</cfloop>
</cfoutput>
