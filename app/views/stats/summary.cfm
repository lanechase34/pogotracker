<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-clipboard-data fs-5"></i>#dateFormat(prc.startdate, "mmm")# Summary Stats
        </div>
        <table class="table table-hover table-sm mb-0">
            <thead class="table-light">
                <tr>
                    <th></th>
                    <th scope="col">Total</th>
                    <th scope="col">Average / Day</th>
                </tr>
            </thead>
            <tbody>
                <cfloop array="#["XP", "Caught", "Spun", "Walked"]#" index="i" item="currStat">
                    <tr>
                        <th scope="row" class="fw-semibold">#currStat#</th>
                        <td>#isNumeric(prc.stats.summary["total#currStat#"]) ? reReplace(numberFormat(prc.stats.summary["total#currStat#"], ",.0"), "\.0$", "") : prc.stats.summary["total#currStat#"]#</td>
                        <td>#isNumeric(prc.stats.summary["avg#currStat#"]) ? reReplace(numberFormat(prc.stats.summary["avg#currStat#"], ",.0"), "\.0$", "") : prc.stats.summary["avg#currStat#"]#</td>
                    </tr>
                </cfloop>
            </tbody>
        </table>
    </div>
</div>
</cfoutput>
