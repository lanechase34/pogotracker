<cfoutput>
<div class="row mx-3 mt-3" id="statRow">
    <form id="statsOverviewForm" name="statsOverviewForm" action="/overview" method="GET" novalidate>
        <input type="hidden" id="startDate" name="startDate" value="#dateFormat(prc.startDate, "mm/dd/yyyy")#">
        <input type="hidden" id="endDate" name="endDate" value="#dateFormat(prc.endDate, "mm/dd/yyyy")#">
        <cfif session.trainerid NEQ prc.trainerid>
            <input type="hidden" id="trainerid" name="trainerid" value="#encodeForHTML(prc.trainerid)#">
        </cfif>
    </form>

    <div class="col-12">
        <div id="statButtonGroup" class="btn-group flex-wrap" role="group">
            <button type="button" data-stat="xp" class="changeStat btn btn-dark active" disabled>XP</button>
            <button type="button" data-stat="caught" class="changeStat btn btn-dark">Caught</button>
            <button type="button" data-stat="spun" class="changeStat btn btn-dark">Spun</button>
            <button type="button" data-stat="walked" class="changeStat btn btn-dark">Walked</button>
            <input class="btn btn-light" id="dateRangePicker" readonly/>
        </div>
    </div>
</div>
<div class="row statCards">
    <!--- Main line chart --->
    <div class="col-12 col-xl-8 mt-3 statCard" id="chartDiv">
        <canvas id="statLineChart"></canvas>
    </div>

    <!--- Summary Table --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="summaryDiv">
        <div class="d-flex justify-content-center">
            <h5><i class="bi bi-clipboard-data me-1"></i>Summary</h5>
        </div>
        <table class="table table-bordered table-hover shadow-sm">
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

     <!--- Medal progress --->
     <div class="col-12 col-xl-8 mt-3 statCard" id="medalProgressDiv"></div>
     
    <!--- Delta table --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="deltaDiv">
        <!--- delta xp --->
        #view(
            view="/views/stats/deltatable",
            nolayout=true,
            args={stat: "xp", stats: prc.stats, display: ""}
        )#

        <!--- delta caught --->
        #view(
            view="/views/stats/deltatable",
            nolayout=true,
            args={stat: "caught", stats: prc.stats, display: "d-none"}
        )#

        <!--- delta spun --->
        #view(
            view="/views/stats/deltatable",
            nolayout=true,
            args={stat: "spun", stats: prc.stats, display: "d-none"}
        )#

        <!--- delta walked --->
        #view(
            view="/views/stats/deltatable",
            nolayout=true,
            args={stat: "walked", stats: prc.stats, display: "d-none"}
        )#
    </div>

    <!--- Leaderboard --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="leaderboardDiv" data-epoch="#now().getTime()#"></div>
</div>
<script>
    const statDataset = #serializeJSON(prc.stats)#;
</script>
</cfoutput>