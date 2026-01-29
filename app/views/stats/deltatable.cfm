<cfoutput>
<div id="delta#args.stat#div" class="#args.display# p-0">
    <div class="d-flex justify-content-center">
        <h5><i class="bi bi-triangle me-1"></i>Delta #ucFirst(args.stat)#</h5>
    </div>
    <table 
        id="delta#args.stat#table"
        class="table table-bordered table-striped shadow-sm"
    >
        <thead>
            <tr>
                <th>Day</th>
                <th>#ucFirst(args.stat)#</th>
                <th>Delta</th>
            </tr>
        </thead>
        <tbody>
            <cfloop array="#args.stats.labels#" index="i" item="currDate">
                <tr>
                    <td>#currDate#</td>
                    <td>#isNumeric(args.stats.data[currDate][args.stat]) ? reReplace(numberFormat(args.stats.data[currDate][args.stat], ",.0"), "\.0$", "") : args.stats.data[currDate][args.stat]#</td>
                    <td>#isNumeric(args.stats.data[currDate]["delta#args.stat#"]) ? reReplace(numberFormat(args.stats.data[currDate]["delta#args.stat#"], ",.0"), "\.0$", "") : args.stats.data[currDate]["delta#args.stat#"]#</td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</div>
</cfoutput>