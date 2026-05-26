<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-trophy fs-5"></i>#encodeForHTML(args.title)#
            <span class="ms-auto fw-normal fst-italic text-muted" style="font-size: 0.7rem">Refreshes every 30 minutes</span>
        </div>
    
        <div class="tableDiv pt-3">
            <table class="table table-hover table-sm mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="small fw-bold text-muted text-uppercase">Rank</th>
                        <th class="small fw-bold text-muted text-uppercase">#encodeForHTML(ucFirst(args.stat))# / Day</th>
                        <th class="small fw-bold text-muted text-uppercase">Trainer</th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop array="#args.leaderboard#" index="i" item="currTrainer">
                        <tr>
                            <td>
                                <span class="home-rank-badge<cfif i LTE 3> home-rank-#i#</cfif>">#i#</span>
                            </td>
                            <td>#isNumeric(currTrainer.delta) ? reReplace(numberFormat(currTrainer.delta, ",.0"), "\.0$", "") : "--"#</td>
                            <td>#currTrainer.username#</td>
                        </tr>
                    </cfloop>

                    <cfif NOT args.leaderboard.len()>
                        <tr>
                            <td colspan="3">
                                Start tracking your stats!
                            </td>
                        </tr>
                    </cfif>
                </tbody>
            </table>
        </div>
    </div>
</div>
</cfoutput>