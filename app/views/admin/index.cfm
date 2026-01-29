<cfoutput> 
<div class="row">
    <div class="col-12 col-md-3 d-flex align-items-start mt-3">
        <div class="list-group w-100">
            <a href="/admin/auditLog" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Audit Log</div>
            </a>
            <a href="/admin/bugLog" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Bug Log</div>
            </a>
            <a href="/admin/showMedalData" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">List Medals</div>
            </a>
            <a href="/admin/showMoveData" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">List Moves</div>
            </a>
            <a href="/admin/listPokemon" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">List Pokemon</div>
            </a>
            <a href="/admin/listTrainers" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">List Trainers</div>
            </a>
            <a href="/admin/requestLog" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Request Log</div>
            </a>
            <a href="/admin/serverInfo" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Server Info</div>
            </a>
            <a href="/admin/logViewer" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Server Logs</div>
            </a>
            <a href="/admin/taskManager" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Task Manager</div>
            </a>
            <a href="/blog/writeForm" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Write Blog</div>
            </a>
        </div>
    </div>
    <div class="col-12 col-md-3 d-flex align-items-start mt-3">
        <div class="list-group w-100">
            <a href="/admin/buildLevels" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Build Levels</div>
            </a>
            <a href="/admin/buildMedalData" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Build Medals</div>
            </a>
            <a href="/admin/buildMoveData" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Build Moves</div>
            </a>
            <a href="/admin/buildPokemonData" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                <div class="d-flex gap-2 w-100 justify-content-between">Build Pokemon</div>
            </a>
        </div>
    </div>
    <div class="col-12 col-md-6 d-flex mt-3">
        <div class="d-flex h-100 w-100 card">
            <div class="card-header">
                Application State
            </div>
            <div class="card-body mx-1">
                <form action="/admin/saveState" name="applicationStateForm" method="post" id="applicationStateForm" class="needs-validation h-100 w-100 p-0 m-0" novalidate autocomplete="off">
                    <div class="row d-flex h-100 w-100">
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
                            <label for="pokemonLink" class="form-label">Pokemon Link</label>
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
                        <div class="col-12">
                            <button type="submit" class="col-12 col-lg-4 btn btn-primary">
                                Save State
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
</cfoutput>