<cfoutput>
<div class="d-flex justify-content-center align-items-center text-center min-vh-100">
    <div class="col-12 col-md-9 col-lg-7">

        <div class="mb-4">
            <i class="bi bi-slash-circle-fill text-warning fs-1"></i>
        </div>

        <h1 class="fw-bold display-6 mb-3">
            Method Not Allowed
        </h1>

        <p class="text-muted mb-4">
            The request method used is not supported for this page.
        </p>

        <div class="d-flex justify-content-center gap-2 flex-wrap">
            <a href="/" class="btn btn-dark">
                <i class="bi bi-house-fill me-1"></i>Home
            </a>

            <button class="btn btn-outline-dark" onclick="history.back();">
                <i class="bi bi-arrow-left me-1"></i>Go Back
            </button>
        </div>

    </div>
</div>
</cfoutput>