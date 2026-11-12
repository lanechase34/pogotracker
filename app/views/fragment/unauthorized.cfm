<cfoutput>
<div class="d-flex justify-content-center align-items-center text-center flex-grow-1">
    <div class="col-12 col-md-9 col-lg-7">

        <div class="mb-4">
            <i class="bi bi-shield-lock-fill text-danger fs-1"></i>
        </div>

        <h1 class="fw-bold display-6 mb-3">
            Access Denied
        </h1>

        <p class="text-muted mb-4">
            You don't have permission to access this page.
        </p>

        <div class="d-flex justify-content-center gap-2 flex-wrap">

            <cfif prc.keyExists("oCurrentUser")>
                <a href="/" class="btn btn-dark">
                    <i class="bi bi-house-fill me-1"></i>Home
                </a>
            <cfelse>
                <a href="/login" class="btn btn-dark">
                    <i class="bi bi-person-fill me-1"></i>Log In
                </a>
            </cfif>

            <button class="btn btn-outline-dark" data-history-back>
                <i class="bi bi-arrow-left me-1"></i>Go Back
            </button>
        </div>

        <cfif getSetting("environment") NEQ "production">
            <div class="alert alert-dark mt-4 text-start small">
                <strong>Debug:</strong><br>
                Event: #prc?.currEvent ?: "unknown"#<br>
                User Authenticated: #prc.keyExists("oCurrentUser")#<br>
                Security Level: #prc.keyExists("oCurrentUser") ? prc.oCurrentUser.getSecurityLevel() : "N/A"#<br>
                Blocked By: #encodeForHTML(prc?.cbSecurity_validatorResults?.type ?: "-")#
            </div>
        </cfif>
    </div>
</div>
</cfoutput>