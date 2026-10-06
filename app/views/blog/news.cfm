<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-newspaper fs-5"></i>Latest News
        </div>
        <div class="list-group list-group-flush" id="newsList" data-count="#args.count#">
            #view(view = '/views/blog/fragment/newsitems', args = {news: args.news})#
        </div>
    </div>
</div>
</cfoutput>