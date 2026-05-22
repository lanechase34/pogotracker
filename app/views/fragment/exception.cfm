<cfoutput>
<div class="d-flex justify-content-center align-items-center text-center flex-grow-1">
    <div class="col-12 col-md-9 col-lg-7">

        <div class="mb-4">
            <i class="bi bi-bug-fill text-danger fs-1"></i>
        </div>

        <h1 class="fw-bold display-6 mb-3">
            Something Went Wrong
        </h1>

        <p class="text-muted mb-4">
            An unexpected error occurred while processing your request.
            Please try again or return to the homepage.
        </p>

        <div class="d-flex justify-content-center gap-2 flex-wrap">
            <a href="/" class="btn btn-dark">
                <i class="bi bi-house-fill me-1"></i>Home
            </a>

            <button class="btn btn-outline-dark" onclick="history.back();">
                <i class="bi bi-arrow-left me-1"></i>Go Back
            </button>

            <cfif prc.debuggingMode>
                <a href="#event.buildLink(prc.erroredEvent)#?fwreinit">
                    <button class="btn btn-outline-dark">
                        <i class="bi bi-arrow-left me-1"></i>Re-run event
                    </button>
                </a>
            </cfif>
        </div>

        <cfif prc.debuggingMode>
            <div class="alert alert-dark mt-4 text-start small">
                <strong>Debug:</strong><br>
                Event: #encodeForHTML(prc?.currEvent ?: 'unknown')#<br>
                URL: #encodeForHTML(cgi.script_name)#
            </div>
            <cfif prc.keyExists('details')>
                <cfdump var="#prc.details#"/>
            </cfif>
        </cfif>

    </div>
</div>
</cfoutput>