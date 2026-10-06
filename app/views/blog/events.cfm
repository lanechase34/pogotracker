<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-calendar-event fs-5"></i>Upcoming Events
        </div>
        <div class="list-group list-group-flush" id="eventsList" data-count="#args.count#">
            #view(view = '/views/blog/fragment/eventitems', args = {events: args.events})#
        </div>
    </div>
</div>
</cfoutput>