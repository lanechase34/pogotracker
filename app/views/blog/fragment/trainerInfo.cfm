<cfoutput>
<div class="d-flex align-items-center gap-2 mb-2">
    <cfif !args.author.isEmpty()>
        <img
            class="profileIcon flex-shrink-0"
            src="#encodeForHTMLAttribute(args.author.iconpath)#"
            alt="#encodeForHTMLAttribute(args.author.iconalttext)#"
            loading="lazy"
        >
    </cfif>
    <div>
        <cfif !args.author.isEmpty()>
            <div class="text-muted"><i class="bi bi-person-circle me-1 text-muted"></i>#encodeForHTML(args.author.username)#</div>
        </cfif>
        <div class="text-muted"><i class="bi bi-calendar3 me-1"></i>#args.date#</div>
    </div>
</div>
</cfoutput>
