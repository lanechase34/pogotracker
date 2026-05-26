<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-newspaper fs-5"></i>Latest News
        </div>
        <div class="list-group list-group-flush">
            <cfloop index="i" item="currNews" array="#args.news#">
                <a href="#currNews.link#" target="_blank" class="list-group-item list-group-item-action ps-0 pe-3 py-3">
                    <div class="border-start border-3 border-dark ps-3">
                        <span class="fw-semibold">#currNews.header#</span>
                    </div>
                </a>
            </cfloop>
        </div>
    </div>
</div>
</cfoutput>