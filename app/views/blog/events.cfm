<cfoutput>
<div class="col">
    <div class="text-center">
        <h5 class="">
            <i class="bi bi-calendar-event me-1"></i>Upcoming Events
        </h5>
    </div>
    <div class="list-group shadow-sm">
        <cfloop index="i" item="currEvent" array="#args.events#">
            <a href="#currEvent.link#" target="_blank" class="list-group-item list-group-item-action d-flex py-3">
                <div class="gap-2 w-100 justify-content-between newsLink">
                    #currEvent.title#

                    <p class="m-0 text-secondary">
                        #currEvent.timestamp#
                    </p>
                </div>
            </a>
        </cfloop>
    </div>
</div>
</cfoutput>