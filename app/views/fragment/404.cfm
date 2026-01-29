<cfoutput>
<div class="d-flex justify-content-center align-items-center text-center errorDiv">
    <div class="col-12 col-md-8 col-lg-6">

        <div class="mb-4">
            <i class="bi bi-exclamation-triangle-fill text-warning fs-1"></i>
        </div>

        <h1 class="fw-bold display-6 mb-3">
            404 - Page Not Found
        </h1>

        <p class="text-muted mb-4">
            Sorry, the page you're looking for doesn't exist or may have been moved.
        </p>

        <div class="d-flex justify-content-center gap-2 flex-wrap">
            <a href="/" class="btn btn-dark">
                <i class="bi bi-house-fill me-1"></i>Home
            </a>

            <button class="btn btn-outline-dark" onclick="history.back();">
                <i class="bi bi-arrow-left me-1"></i>Go Back
            </button>
        </div>

        <cfif getSetting("environment") NEQ "production">
            <div class="alert alert-dark mt-4 text-start small">
                <strong>Debug:</strong><br>
                Event: #prc?.currEvent ?: "unknown"#<br>
                URL: #cgi.script_name#
            </div>
        </cfif>

    </div>
</div>
</cfoutput>