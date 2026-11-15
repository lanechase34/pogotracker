<cfoutput>
<div class="row mt-3">
    <table id="taskInfo" class="table table-striped table-bordered text-center">
        <thead>
            <tr>
                <th class="text-center">Run</th>
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
                <th class="text-center">Scheduled</th>
            </tr>
        </thead>
        <tbody>
            <cfloop index="i" item="currTask" array="#prc.taskInfo#">
                <tr>
                    <td class="text-center align-middle">
                        <button 
                            type="button" 
                            class="runTask btn btn-sm btn-success" 
                            data-scheduler="#encodeForHTMLAttribute(currTask.scheduler)#" 
                            data-name="#encodeForHTMLAttribute(currTask.name)#" 
                            title="Force run now"
                        >
                            <i class="bi bi-play-fill"></i>
                        </button>
                    </td>
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
                    <td><cfif currTask.scheduled><i class="bi bi-check"></i></cfif></td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</div>

<div class="modal fade" id="runTaskModal" tabindex="-1" aria-labelledby="runTaskModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="runTaskModalTitle">Task Results</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="runTaskModalBody"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" id="runTaskModalReload">Reload Page</button>
                <button type="button" class="btn btn-primary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<cfif rc?.debug ?: false>
<cfdump var="#prc.taskInfo#"/>
</cfif>
</cfoutput>