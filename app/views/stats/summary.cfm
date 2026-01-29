<cfoutput>
<div class="card shadow-sm">
    <div class="card-body mx-1">
        <div class="d-flex align-items-center justify-content-center mb-3">
            <h5 class="m-0">
                <i class="bi bi-clipboard-data me-1"></i>
                #dateFormat(prc.startdate, "mmm")# Summary Stats
            </h5>
        </div>
        <div class="tableDiv">
        <table class="table table-bordered table-hover">
            <thead>
                <tr>
                    <th></th>
                    <th scope="col">Total</th>
                    <th scope="col">Average / Day</th>
                </tr>
            </thead>
            <tbody>
                <cfloop array="#["XP", "Caught", "Spun", "Walked"]#" index="i" item="currStat">
                    <tr>
                        <th scope="row">#currStat#</th>
                        <td>#isNumeric(prc.stats.summary["total#currStat#"]) ? reReplace(numberFormat(prc.stats.summary["total#currStat#"], ",.0"), "\.0$", "") : prc.stats.summary["total#currStat#"]#</td>
                        <td>#isNumeric(prc.stats.summary["avg#currStat#"]) ? reReplace(numberFormat(prc.stats.summary["avg#currStat#"], ",.0"), "\.0$", "") : prc.stats.summary["avg#currStat#"]#</td>
                    </tr>
                </cfloop>
            </tbody>
        </table>
        </div>
    </div>
</div>
</cfoutput>