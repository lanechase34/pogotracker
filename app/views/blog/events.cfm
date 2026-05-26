<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-calendar-event fs-5"></i>Upcoming Events
        </div>
        <div class="list-group list-group-flush">
            <cfloop index="i" item="currEvent" array="#args.events#">
                <a href="#currEvent.link#" target="_blank" class="list-group-item list-group-item-action ps-0 pe-3 py-3">
                    <div class="border-start border-3 border-dark ps-3">
                        <span class="d-block fw-semibold lh-sm mb-1">#currEvent.title#</span>
                        <small class="text-muted">#currEvent.timestamp#</small>
                    </div>
                </a>
            </cfloop>
        </div>
    </div>
</div>
</cfoutput>