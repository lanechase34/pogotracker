<cfoutput>
<div class="col">
    <div class="text-center">
        <h5 class="mb-0">
            <i class="bi bi-trophy me-1"></i>#encodeForHTML(args.title)#
        </h5>
        <span class="text-secondary" style="font-size: .8rem;"><i>Refreshes every 30 minutes</i></span>
    </div>
    <div class="tableDiv">
    <table id="leaderboardTable" class="table table-striped table-bordered shadow-sm">
        <thead>
            <tr>
                <th>Rank</th>
                <th>#encodeForHTML(ucFirst(args.stat))# / Day</th>
                <th>Trainer</th>
            </tr>
        </thead>
        <tbody>
            <cfloop array="#args.leaderboard#" index="i" item="currTrainer">
                <tr>
                    <td>#i#</td>
                    <td>#isNumeric(currTrainer.delta) ? reReplace(numberFormat(currTrainer.delta, ",.0"), "\.0$", "") : "--"#</td>
                    <td>#currTrainer.username#</td>
                </tr>
            </cfloop>
        </tbody>
    </table>
    </div>
</div>
</cfoutput>