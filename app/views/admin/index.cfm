<cfoutput>
<div class="row mb-3 g-3 mt-0">
    <div class="col-12 col-md-4">
        <div class="card h-100">
            <div class="card-header fw-semibold text-uppercase text-body-secondary adminNavHeader">Data</div>
            <div class="list-group list-group-flush">
                <a href="/admin/auditLog" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-shield-check text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Audit Log</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/comments" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-chat-left-text text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Blog Comments</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/bugLog" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-bug text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Bug Log</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/showMedalData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-award text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">List Medals</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/showMoveData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-lightning text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">List Moves</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/listPokemon" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-grid-3x3-gap text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">List Pokemon</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/listTrainers" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-people text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">List Trainers</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/requestLog" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-activity text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Request Log</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-4">
        <div class="card h-100">
            <div class="card-header fw-semibold text-uppercase text-body-secondary adminNavHeader">Tools</div>
            <form method="post" class="list-group list-group-flush">
                <input type="hidden" name="csrf" value="#csrfToken()#">
                <a href="/admin/readEventOverrides" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-calendar-event text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Env Event Overrides</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/readNameOverrides" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-tag text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Env Name Overrides</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/readOverrides" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-sliders text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Env Pokemon Overrides</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/serverInfo" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hdd-stack text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Server Info</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/logViewer" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-journal-text text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Server Logs</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <a href="/admin/taskManager" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-clock-history text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Task Manager</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
                <button type="submit" formaction="/admin/updateSiteMap" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-diagram-3 text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Update Sitemap</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
                <a href="/blog/writeForm" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-pencil-square text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Write Blog</span><i class="bi bi-chevron-right small text-body-secondary"></i>
                </a>
            </form>
        </div>
    </div>
    <div class="col-12 col-md-4">
        <div class="card h-100">
            <div class="card-header fw-semibold text-uppercase text-body-secondary adminNavHeader">Build &amp; State</div>
            <form method="post" class="list-group list-group-flush">
                <input type="hidden" name="csrf" value="#csrfToken()#">
                <button type="button" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3 adminNavState" data-bs-toggle="modal" data-bs-target="##applicationStateModal">
                    <i class="bi bi-gear text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1 fw-semibold">Application State</span><i class="bi bi-window small text-body-secondary" title="Opens settings"></i>
                </button>
                <button type="submit" formaction="/admin/buildCostumeData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hammer text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Build Costume Pokemon</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
                <button type="submit" formaction="/admin/buildLevels" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hammer text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Build Levels</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
                <button type="submit" formaction="/admin/buildMedalData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hammer text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Build Medals</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
                <button type="submit" formaction="/admin/buildMoveData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hammer text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Build Moves</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
                <button type="submit" formaction="/admin/buildPokemonData" class="list-group-item list-group-item-action d-flex align-items-center gap-3 py-3">
                    <i class="bi bi-hammer text-center text-body-secondary adminNavIcon"></i><span class="flex-grow-1">Build Pokemon</span><i class="bi bi-play-fill small text-body-secondary" title="Runs immediately"></i>
                </button>
            </form>
            <div class="card-footer d-flex flex-wrap gap-2 mt-auto">
                <span class="badge rounded-pill #getSetting('signups') ? 'text-bg-success' : 'text-bg-secondary'#">Signups #getSetting('signups') ? 'On' : 'Off'#</span>
                <span class="badge rounded-pill #getSetting('logRequests') ? 'text-bg-success' : 'text-bg-secondary'#">Log Requests #getSetting('logRequests') ? 'On' : 'Off'#</span>
                <span class="badge rounded-pill text-bg-light border">Fetch Count #getSetting('fetchCount')#</span>
                <span class="badge rounded-pill text-bg-light border">Event Days #getSetting('eventDaysBefore')#</span>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="applicationStateModal" tabindex="-1" aria-labelledby="applicationStateModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="applicationStateModalTitle">Application State</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form action="/admin/saveState" name="applicationStateForm" method="post" id="applicationStateForm" class="needs-validation w-100 p-0 m-0" novalidate autocomplete="off">
                    <input type="hidden" name="csrf" value="#csrfToken()#">
                    <div class="row">
                        <div class="col-12 mb-1">
                            <label for="fetchCount" class="form-label">Fetch Count</label>
                            <input type="number" class="form-control" id="fetchCount" name="fetchCount" value="#getSetting('fetchCount')#" required>
                            <div class="invalid-feedback">Please provide a valid count.</div>
                        </div>
                        <div class="col-12 mb-1">
                            <label for="eventDaysBefore" class="form-label">Event Days Before</label>
                            <input type="number" class="form-control" id="eventDaysBefore" name="eventDaysBefore" value="#getSetting('eventDaysBefore')#" required>
                            <div class="invalid-feedback">Please provide a valid count.</div>
                        </div>
                        <div class="col-12 mb-1">
                            <label for="eventLink" class="form-label">Event Link</label>
                            <input type="text" class="form-control" id="eventLink" name="eventLink" value="">
                        </div>
                        <div class="col-12 mb-1">
                            <label for="pokemonLink" class="form-label">Pokemon Link (Pokemon GO DB)</label>
                            <input type="text" class="form-control" id="pokemonLink" name="pokemonLink" value="">
                        </div>
                        <div class="col-12 mb-1">
                            <label for="pokemonJson" class="form-label">Pokemon JSON</label>
                            <textarea
                                name="pokemonJson"
                                class="form-control"
                                id="pokemonJson"
                                rows="3"
                                maxlength="2000"
                            ></textarea>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="signupsSwitch" name="signupsSwitch" <cfif getSetting('signups')>checked</cfif>>
                                <label class="form-check-label" for="signupsSwitch">Allow Signups</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="logRequestsSwitch" name="logRequestsSwitch" <cfif getSetting('logRequests')>checked</cfif>>
                                <label class="form-check-label" for="logRequestsSwitch">Log Requests</label>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                <button type="submit" form="applicationStateForm" class="btn btn-dark">Save State</button>
            </div>
        </div>
    </div>
</div>
</cfoutput>
