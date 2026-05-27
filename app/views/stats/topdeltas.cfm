<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-trophy fs-5"></i>Top Days
        </div>

        <div class="d-flex align-items-center justify-content-center mb-3">
            <div class="btn-group btn-group-sm flex-wrap text-center" role="group">
                <button type="button" data-stat="xp"     class="topDeltaStat btn btn-dark active" disabled>XP</button>
                <button type="button" data-stat="caught" class="topDeltaStat btn btn-dark">Caught</button>
                <button type="button" data-stat="spun"   class="topDeltaStat btn btn-dark">Spun</button>
                <button type="button" data-stat="walked" class="topDeltaStat btn btn-dark">Walked</button>
            </div>
        </div>

        <div id="topDeltaData" data-deltas="#encodeForHTML(serializeJSON(args.topDeltas))#">
            <div class="d-flex justify-content-center">
                <div id="topDeltaList" class="d-flex flex-column gap-1"></div>
            </div>
        </div>
    </div>
</div>
</cfoutput>
