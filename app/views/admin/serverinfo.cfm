<cfoutput>
<div class="row">
    <div class="col-12 mt-3">
        <table id="cacheData" class="table table-striped table-bordered">
            <thead>
                <tr>
                    <th class="text-center">Key</th>
                    <th class="text-center">Created</th>
                    <th class="text-center">Hits</th>
                    <th class="text-center">Expired </th>
                    <th class="text-center">Last Accessed</th>
                    <th class="text-center">Last Access Timeout</th>
                    <th class="text-center">Timeout</th>
                </tr>
            </thead>
            <tbody>
                <cfloop item="currData" index="currKey" collection="#prc.cacheData#">
                    <tr>
                        <td>#encodeForHTML(currKey)#</td>
                        <td>#encodeForHTML(dateTimeFormat(currData.created, "long"))#</td>
                        <td>#encodeForHTML(currData.hits)#</td>
                        <td>#encodeForHTML(currData.isExpired)#</td>
                        <td>#encodeForHTML(dateTimeFormat(currData.lastAccessed, "long"))#</td>
                        <td>#encodeForHTML(currData.lastAccessTimeout)#</td>
                        <td>#encodeForHTML(currData.timeout)#</td>
                    </tr>
                </cfloop>
            </tbody>
        </table>
    </div>
</div>

<div class="row">
    <div class="col-12 col-xl-6 mt-3">
        <div class="card shadow-sm">
            <div class="card-header h5">
                JVM Memory Usage
            </div>
            <div class="card-body w-100 d-flex justify-content-center align-items-center" style="height: 450px;">
                <div class="metricsLoading">
                    <div class="spinner-border ms-auto" aria-hidden="true"></div>
                </div>
                <canvas id="jvmChart" class="d-none"></canvas>
            </div>
        </div>
    </div>

    <div class="col-12 col-xl-6 mt-3">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Request Metrics
            </div>
            <div class="card-body w-100 d-flex justify-content-center align-items-center" style="height: 450px;">
                <div class="metricsLoading">
                    <div class="spinner-border ms-auto" aria-hidden="true"></div>
                </div>
                <canvas id="requestChart" class="d-none"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-12 col-xl-6 mt-3">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Slow Running Requests
            </div>
            <div class="card-body w-100" style="min-height: 100px;">
                <table id="slowRequestsTable" class="table table-bordered table-striped">
                    <thead>
                        <tr>
                            <th class="text-center">Timestamp</th>
                            <th class="text-center">URL</th>
                            <th class="text-center">Method</th>
                            <th class="text-center">ms</th>
                            <th class="text-center">Trainer</th>
                        </tr>
                    </thead>
                    <tbody id="slowRequestsBody">
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="col-12 col-xl-6 mt-3">
        <div class="card shadow-sm">
            <div class="card-header h5">
                System Information
            </div>
            <div class="card-body w-100 p-3 d-flex flex-column gap-2 flex-fill">
                <div className="d-flex flex-column gap-1">
                    <div class="text-muted small">
                        Cores
                    </div>
                    <div class="fw-normal" id="coresMetric">
                        --
                    </div>

                    <hr>

                    <div class="text-muted small">
                        CPU Process Percentage
                    </div>
                    <div class="fw-normal" id="processMetric">
                        --
                    </div>

                    <hr>

                    <div class="text-muted small">
                        CPU System Percentage
                    </div>
                    <div class="fw-normal" id="systemMetric">
                        --
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="serverInfoModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5">Server Info</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="row mt-3">
                    <p>Current Timezone - #prc.timezone#</p>
                    <p>Current Time - #prc.timestamp#</p>
                </div>
                <div class="row mt-3">
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th>Stat</th>
                                <th>Count</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Last Reap</td>
                                <td>#dateTimeFormat(prc.cacheStats.getLastReapDateTime(), "short")#</td>
                            </tr>
                            <tr>
                                <td>Hits</td>
                                <td>#prc.cacheStats.getHits()#</td>
                            </tr>
                            <tr>
                                <td>Misses</td>
                                <td>#prc.cacheStats.getMisses()#</td>
                            </tr>
                            <tr>
                                <td>Evictions</td>
                                <td>#prc.cacheStats.getEvictionCount()#</td>
                            </tr>
                            <tr>
                                <td>Garbage Collections</td>
                                <td>#prc.cacheStats.getGarbageCollections()#</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="row mt-3">
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th scope="col">Handler.Action</th>
                                <th scope="col" class="text-center">Unauthenticated</th>
                                <th scope="col" class="text-center">User</th>
                                <th scope="col" class="text-center">Admin</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfloop item="actions" index="currHandler" collection="#prc.securityMap#">
                                <cfloop item="securityLevel" index="currAction" collection="#actions#">
                                    <tr>
                                        <td>#currHandler#.#currAction#</td>
                                        <td class="text-center"><cfif 0 GTE securityLevel><i class="bi bi-check-lg"></i></cfif></td>
                                        <td class="text-center"><cfif 10 GTE securityLevel><i class="bi bi-check-lg"></i></cfif></td>
                                        <td class="text-center"><cfif 50 GTE securityLevel><i class="bi bi-check-lg"></i></cfif></td>
                                    </tr>
                                </cfloop>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>