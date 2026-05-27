<cfparam name="args.heading"  default="">
<cfparam name="args.subtitle" default="">
<cfoutput>
<header class="auth-hero text-white text-center p-4">
    <div class="d-flex align-items-center justify-content-center gap-2 mb-2">
        <img
            src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#"
            alt="POGO Tracker Logo"
            class="logo"
        >
        <span class="fs-3 fw-bold">POGO Tracker</span>
    </div>
    <cfif len(args.heading)>
        <h1 class="fs-5 fw-semibold mb-1">#encodeForHTML(args.heading)#</h1>
    </cfif>
    <cfif len(args.subtitle)>
        <p class="small mb-0">#encodeForHTML(args.subtitle)#</p>
    </cfif>
</header>
</cfoutput>