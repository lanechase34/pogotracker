<cfoutput>
<div class="row mt-3" id="statRow">
    <form id="statsOverviewForm" name="statsOverviewForm" action="/overview" method="GET" novalidate>
        <input type="hidden" id="startDate" name="startDate" value="#dateFormat(prc.startDate, "mm/dd/yyyy")#">
        <input type="hidden" id="endDate" name="endDate" value="#dateFormat(prc.endDate, "mm/dd/yyyy")#">
        <cfif session.trainerid NEQ prc.trainerid>
            <input type="hidden" id="trainerid" name="trainerid" value="#encodeForHTML(prc.trainerid)#">
        </cfif>
    </form>

    <div class="col-12">
        <div id="statButtonGroup" class="btn-group flex-wrap" role="group">
            <button type="button" data-stat="xp"     class="changeStat btn btn-dark active" disabled>XP</button>
            <button type="button" data-stat="caught"  class="changeStat btn btn-dark">Caught</button>
            <button type="button" data-stat="spun"    class="changeStat btn btn-dark">Spun</button>
            <button type="button" data-stat="walked"  class="changeStat btn btn-dark">Walked</button>
            <input class="btn btn-light border" id="dateRangePicker" readonly/>
        </div>
    </div>
</div>

<div class="row statCards">
    <!--- Main line chart --->
    <div class="col-12 col-xl-8 mt-3 statCard" id="chartDiv">
        <div class="card shadow-sm h-100">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-graph-up fs-5"></i><span id="chartLabel"></span>
                </div>
                <canvas id="statLineChart"></canvas>
            </div>
        </div>
    </div>

    <!--- Summary Table --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="summaryDiv">
        <div class="card shadow-sm h-100">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-clipboard-data fs-5"></i>Summary
                </div>
                <table class="table table-hover table-sm mb-0">
                    <thead class="table-light">
                        <tr>
                            <th></th>
                            <th scope="col">Total</th>
                            <th scope="col">Avg / Day</th>
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
    </div>

    <!--- Medal progress --->
    <div class="col-12 col-xl-8 mt-3 statCard" id="medalProgressDiv"></div>

    <!--- Delta table (body populated by renderDeltaTable() in stats.js) --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="deltaDiv">
        #view(view="/views/stats/deltatable", nolayout=true)#
    </div>

    <!--- Leaderboard --->
    <div class="col-12 col-xl-4 mt-3 statCard" id="leaderboardDiv" data-epoch="#now().getTime()#"></div>
</div>
<script>
    const statDataset = #serializeJSON(prc.stats)#;
</script>
</cfoutput>
