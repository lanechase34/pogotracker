<cfoutput>
<div class="row mt-3">
    <table id="taskInfo" class="table table-striped table-bordered text-center">
        <thead>
            <tr>
                <th class="text-center">Task</th>
                <th class="text-center">Created</th>
                <th class="text-center">Module</th>
                <th class="text-center">Executor</th>
                <th class="text-center">Last Run</th>
                <th class="text-center">Next Run</th>
                <th class="text-center">Total Failures</th>
                <th class="text-center">Total Success</th>
                <th class="text-center">Total Runs</th>
                <th class="text-center">Last Execution Time</th>
                <th class="text-center">Error</th>
                <th class="text-center">Message</th>
                <th class="text-center">Host</th>
                <th class="text-center">IP</th>
                <th class="text-center">Cache Name</th>
                <th class="text-center">Constrained</th>
                <th class="text-center">Debug</th>
                <th class="text-center">Server Fixation</th>
                <th class="text-center">Scheduled</th>
            </tr>
        </thead>
        <tbody>
            <cfloop index="i" item="currTask" array="#prc.taskInfo#">
                <tr>
                    <td>#currTask.name#</td>
                    <td>#dateTimeFormat(currTask.stats.created, "short")#</td>
                    <td>#currTask.executor#</td>
                    <td>#currTask.module#</td>
                    <td>#dateTimeFormat(currTask.stats.lastRun, "short")#</td>
                    <td>#dateTimeFormat(currTask.stats.nextRun, "short")#</td>
                    <td>#currTask.stats.totalFailures#</td>
                    <td>#currTask.stats.totalSuccess#</td>
                    <td>#currTask.stats.totalRuns#</td>
                    <td>#currTask.stats.lastExecutionTime#</td>
                    <td><cfif currTask.error><i class="bi bi-check"></i></cfif></td>
                    <td>#currTask.errorMessage#</td>
                    <td>#currTask.stats.inetHost#</td>
                    <td>#currTask.stats.localIp#</td>
                    <td>#currTask.cacheName#</td>
                    <td><cfif currTask.constrained><i class="bi bi-check"></i></cfif></td>
                    <td><cfif currTask.debug><i class="bi bi-check"></i></cfif></td>
                    <td><cfif currTask.serverFixation><i class="bi bi-check"></i></cfif></td>
                    <td><cfif currTask.scheduled><i class="bi bi-check"></i></cfif></td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</div>

<cfif rc?.debug ?: false>
<cfdump var="#prc.taskInfo#"/>
</cfif>
</cfoutput>