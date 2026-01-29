<cfoutput>
<div class="col">
    <div class="text-center">
        <h5 class="">
            <i class="bi bi-newspaper me-1"></i>Latest News
        </h5>
    </div>
    <div class="list-group shadow-sm">
        <cfloop index="i" item="currNews" array="#args.news#">
            <a href="#currNews.link#" target="_blank" class="list-group-item list-group-item-action d-flex py-3">
                <div class="d-flex gap-2 w-100 justify-content-between newsLink">
                    #currNews.header#
                </div>
            </a>
        </cfloop>
    </div>
</div>
</cfoutput>