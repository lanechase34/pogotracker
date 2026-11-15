component extends="base" secured="admin" {

    this.allowedMethods = {
        index             : "GET",
        buildPokemonData  : "POST",
        listPokemon       : "GET",
        getPokemon        : "GET",
        listTrainers      : "GET",
        getTrainers       : "GET",
        editTrainer       : "GET",
        buildLevels       : "POST",
        auditLog          : "GET",
        getAudits         : "GET",
        comments          : "GET",
        getComments       : "GET",
        bugLog            : "GET",
        getBugs           : "GET",
        serverInfo        : "GET",
        buildMedalData    : "POST",
        showMedalData     : "GET",
        buildMoveData     : "POST",
        showMoveData      : "GET",
        saveState         : "POST",
        taskManager       : "GET",
        runTask           : "POST",
        readOverrides     : "GET",
        saveOverrides     : "POST",
        readEventOverrides: "GET",
        saveEventOverrides: "POST",
        readNameOverrides : "GET",
        saveNameOverrides : "POST",
        logViewer         : "GET",
        getLogChunk       : "GET",
        searchLog         : "GET",
        listLogs          : "GET",
        downloadLog       : "GET",
        downloadLogs      : "GET",
        requestLog        : "GET",
        getRequests       : "GET",
        updateSiteMap     : "POST",
        buildCostumeData  : "POST",
        getCacheData      : "GET"
    };

    // Time range each log table opens with
    variables.defaultRanges = {audit: "30d", request: "7d", bug: "1y"};

    property name="adminService"      inject="services.admin";
    property name="bugService"        inject="services.bug";
    property name="medalService"      inject="services.medal";
    property name="moveService"       inject="services.move";
    property name="pagination"        inject="services.pagination";
    property name="pokemonService"    inject="services.pokemon";
    property name="generationService" inject="services.generation";
    property name="trainerService"    inject="services.trainer";
    property name="blogService"       inject="services.blog";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title      = "Admin | #getSetting("title")#";
        prc.metaRobots = "noindex, nofollow";
    }

    function index(event, rc, prc) {
    }

    function buildPokemonData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildPokemonData();
        relocate(event = "admin.listPokemon");
    }

    function listPokemon(event, rc, prc) {
    }

    function getPokemon(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc.costume"             default="false";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc['order[1][column]']" default="";
        param name="rc['order[1][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = "admin.getPokemon")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = pokemonService.getTable(
            records   = rc.length,
            offset    = rc.start,
            search    = rc["search[value]"],
            orderCol1 = rc["order[0][column]"],
            orderDir1 = rc["order[0][dir]"],
            orderCol2 = rc["order[1][column]"],
            orderDir2 = rc["order[1][dir]"],
            costume   = rc.costume == "true"
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function listTrainers(event, rc, prc) {
    }

    function getTrainers(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = "admin.getTrainers")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = trainerService.getTable(
            records  = rc.length,
            offset   = rc.start,
            search   = rc["search[value]"],
            orderCol = rc["order[0][column]"],
            orderDir = rc["order[0][dir]"]
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function editTrainer(event, rc, prc) {
        param name="rc.trainerid" default="";

        // Fetched into a modal - fail with a status, a relocate would hand the modal a whole page
        prc.validation = validate(target = rc, constraints = "editTrainer");
        if(prc.validation.hasErrors()) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        try {
            prc.trainer = trainerService.getFromId(trainerid = prc.trainerid);
        }
        catch(TrainerNotFound e) {
            htmlValidationFailure(event = event, statusCode = 404);
            return;
        }

        // Accounts that outrank you can't be edited
        if(
            prc.trainer.id != prc.oCurrentUser.getId()
            && val(prc.trainer.securitylevel) > val(prc.oCurrentUser.getSecurityLevel())
        ) {
            htmlValidationFailure(event = event, statusCode = 403);
            return;
        }

        prc.baseIcons      = trainerService.getIconMap();
        prc.unlockedIcons  = trainerService.getUnlockedIcons(trainerid = prc.trainer.id);
        prc.securityLevels = trainerService.getAssignableLevels();

        // Use the edited trainer's settings, falling back to defaults for any missing keys
        prc.settings = duplicate(getSetting("defaultSettings"));
        structAppend(prc.settings, prc.trainer.settings, true);

        event.setView(
            view     = "/views/trainer/modal/editProfile",
            nolayout = true,
            args     = {
                trainer       : prc.trainer,
                iconMap       : arrayMerge(prc.baseIcons, prc.unlockedIcons),
                admin         : true,
                securityLevels: prc.securityLevels,
                settings      : prc.settings,
                viewMap       : getSetting("viewMap"),
                generations   : generationService.getAll(),
                pageMap       : getSetting("pageMap")
            }
        );
    }

    function buildLevels(event, rc, prc) {
        adminService.buildLevels();
        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi-check-square-fill",
                "message"    : "Success!"
            }
        );
        relocate("admin.index");
    }

    /**
     * Review blog comments - every post's, or one post's
     *
     * @rc.blogid (optional) open filtered to this blog
     */
    function comments(event, rc, prc) {
        prc.blogs  = blogService.getHeaders();
        prc.blogid = isValid("integer", rc?.blogid ?: "") ? parseNumber(rc.blogid) : 0;
    }

    /**
     * @rc.draw   updates with each ajax request
     * @rc.length entries per page
     * @rc.start  for pagination
     * @rc        ['search[value]'] search box value
     * @rc        ['order[0][column]'] order column
     * @rc        ['order[0][dir]'] order direction
     * @rc.blogid only this blog's comments - 0 for every blog
     */
    function getComments(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="25";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc.blogid"              default="0";

        if(hasValidationErrors(target = rc, constraints = "admin.getComments")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = blogService.getCommentTable(
            records  = rc.length,
            offset   = rc.start,
            search   = rc["search[value]"],
            orderCol = rc["order[0][column]"],
            orderDir = rc["order[0][dir]"],
            blogid   = parseNumber(rc.blogid)
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function auditLog(event, rc, prc) {
        prc.ranges = pagination.getRanges();
        prc.range  = defaultRanges.audit;
    }

    /**
     * @rc.draw   updates with each ajax request
     * @rc.length entries per page
     * @rc.start  for pagination
     * @rc        ['search[value]'] search box value
     * @rc        ['order[0][column]'] order column
     * @rc        ['order[0][dir]'] order direction
     * @rc.range  time range, a key of pagination.getRanges
     */
    function getAudits(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc.range"               default="#defaultRanges.audit#";

        if(hasValidationErrors(target = rc, constraints = "admin.getAudits")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.getTable(
            records  = rc.length,
            offset   = rc.start,
            search   = rc["search[value]"],
            orderCol = rc["order[0][column]"],
            orderDir = rc["order[0][dir]"],
            range    = rc.range
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function requestLog(event, rc, prc) {
        prc.ranges = pagination.getRanges();
        prc.range  = defaultRanges.request;
    }

    function getRequests(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc.range"               default="#defaultRanges.request#";

        if(hasValidationErrors(target = rc, constraints = "admin.getRequests")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.getRequests(
            records  = rc.length,
            offset   = rc.start,
            search   = rc["search[value]"],
            orderCol = rc["order[0][column]"],
            orderDir = rc["order[0][dir]"],
            range    = rc.range
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function bugLog(event, rc, prc) {
        prc.ranges = pagination.getRanges();
        prc.range  = defaultRanges.bug;
    }

    function getBugs(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc.range"               default="#defaultRanges.bug#";

        if(hasValidationErrors(target = rc, constraints = "admin.getBugs")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = bugService.getTable(
            records  = rc.length,
            offset   = rc.start,
            search   = rc["search[value]"],
            orderCol = rc["order[0][column]"],
            orderDir = rc["order[0][dir]"],
            range    = rc.range
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function serverInfo(event, rc, prc) {
        prc.timezone  = getTimezone();
        prc.timestamp = now();
        prc.baseURL   = getSetting("environment") != "production" ? "localhost" : "";
    }

    function getCacheData(event, rc, prc) {
        renderJson(event = event, response = adminService.getCacheData());
    }

    function buildMedalData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildMedalData();
        relocate(event = "admin.showMedalData");
    }

    function showMedalData(event, rc, prc) {
        prc.data = medalService.getAll();
    }

    function buildMoveData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildMoveData();
        relocate(event = "admin.showMoveData");
    }

    function showMoveData(event, rc, prc) {
        prc.fastmoves   = moveService.getAllFastMoves();
        prc.chargeMoves = moveService.getAllChargeMoves();
    }

    function saveState(event, rc, prc) {
        param name="rc.fetchCount"      default="1";
        param name="rc.eventDaysBefore" default="1";
        param name="rc.eventLink"       default="";
        param name="rc.pokemonLink"     default="";
        param name="rc.pokemonJson"     default="";

        setSetting("signups", (rc?.signupsSwitch ?: "off") == "on");
        setSetting("fetchCount", parseNumber(rc.fetchCount));
        setSetting("eventDaysBefore", parseNumber(rc.eventDaysBefore));
        setSetting("logRequests", (rc?.logRequestsSwitch ?: "off") == "on");

        if(rc.eventLink.len()) {
            adminService.createEvent(eventLink = rc.eventLink);
        }

        if(rc.pokemonLink.len()) {
            adminService.createPokemon(pokemonLink = rc.pokemonLink);
        }

        if(rc.pokemonJson.len() && isJSON(rc.pokemonJson) && isStruct(deserializeJSON(rc.pokemonJson))) {
            adminService.addPokemon(pokemon = deserializeJSON(rc.pokemonJson));
        }

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi bi-file-earmark-check",
                "message"    : "Successfully Saved."
            }
        );
        relocate(event = "admin");
    }

    function taskManager(event, rc, prc) {
        prc.taskInfo = adminService.getTaskInfo();
    }

    function runTask(event, rc, prc) {
        param name="rc.scheduler" default="";
        param name="rc.name"      default="";

        // Also checks the scheduler has that task
        if(hasValidationErrors(target = rc, constraints = "admin.runTask")) {
            jsonValidationFailure(event = event);
            return;
        }

        cfsetting(requestTimeout = 600);
        prc.responseObj.data = adminService.runTask(scheduler = rc.scheduler, name = rc.name);

        prc.responseObj.success    = true;
        prc.responseObj.statusCode = 200;
        renderJson(event = event, response = prc.responseObj);
    }

    /**
     * Log list and viewer shell - lines are fetched by the page from getLogChunk as it scrolls
     *
     * @rc.filename optional log to open on load
     */
    function logViewer(event, rc, prc) {
        param name="rc.filename" default="";

        prc.logs = adminService.getLogs();

        // Unknown names just open the viewer with nothing selected
        prc.selected = {};
        for(var row in prc.logs) {
            if(row.name == rc.filename) {
                prc.selected = row;
                break;
            }
        }

        prc.header = "Log Viewer";
    }

    /**
     * One chunk of log lines, read by byte offset
     *
     * @rc.filename  log file name from the log list
     * @rc.offset    forward: byte to start at; backward: byte to end at (-1 = end of file)
     * @rc.direction forward or backward
     */
    function getLogChunk(event, rc, prc) {
        param name="rc.filename"  default="";
        param name="rc.offset"    default="0";
        param name="rc.direction" default="forward";

        // Also checks the log is in the log list
        if(hasValidationErrors(target = rc, constraints = "admin.getLogChunk")) {
            jsonValidationFailure(event = event);
            return;
        }

        jsonOk(
            event = event,
            data  = adminService.readLogChunk(
                path      = adminService.resolveLogPath(filename = rc.filename),
                offset    = rc.offset,
                direction = rc.direction
            )
        );
    }

    /**
     * Next or previous match in a log
     *
     * @rc.filename  log file name from the log list
     * @rc.query     text to find, case-insensitive
     * @rc.offset    forward: first byte a match may start at; backward: matches start before this byte (-1 = end of file)
     * @rc.direction forward or backward
     */
    function searchLog(event, rc, prc) {
        param name="rc.filename"  default="";
        param name="rc.query"     default="";
        param name="rc.offset"    default="0";
        param name="rc.direction" default="forward";

        // Also checks the log is in the log list
        if(hasValidationErrors(target = rc, constraints = "admin.searchLog")) {
            jsonValidationFailure(event = event);
            return;
        }

        cfsetting(requestTimeout = 120);
        jsonOk(
            event = event,
            data  = adminService.searchLog(
                path       = adminService.resolveLogPath(filename = rc.filename),
                searchText = rc.query,
                offset     = rc.offset,
                direction  = rc.direction
            )
        );
    }

    /**
     * Current log list for the viewer sidebar - sizes and new files change while the page is open
     */
    function listLogs(event, rc, prc) {
        jsonOk(event = event, data = adminService.getLogList());
    }

    /**
     * Download one log file
     *
     * @rc.filename log file name from the log list
     */
    function downloadLog(event, rc, prc) {
        param name="rc.filename" default="";

        var path = adminService.resolveLogPath(filename = rc.filename);
        if(!path.len()) {
            htmlNotFound(event = event);
            return;
        }

        event.sendFile(
            file       = adminService.snapshotLog(path = path),
            name       = rc.filename,
            mimeType   = "text/plain",
            deleteFile = true
        );
        event.noRender();
    }

    /**
     * Download every log as one zip
     */
    function downloadLogs(event, rc, prc) {
        cfsetting(requestTimeout = 300);

        event.sendFile(
            file       = adminService.zipLogs(),
            name       = "logs-#dateTimeFormat(now(), "yyyy-mm-dd-HHnn")#.zip",
            mimeType   = "application/zip",
            deleteFile = true
        );
        event.noRender();
    }

    function readOverrides(event, rc, prc) {
        prc.description   = "Pokemon Env Overrides";
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = "envpokedexoverrides"));
        prc.submitAction  = "admin.saveOverrides";
    }

    function saveOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: "");

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = "envpokedexoverrides", override = raw);

            flash.put(
                name  = "alert",
                value = {
                    "type"       : "success",
                    "dismissible": true,
                    "icon"       : "bi bi-copy",
                    "message"    : "Successfully saved!"
                }
            );
        }
        catch(any e) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Error saving. Please try again. #e.message#"
                }
            );
        }
        relocate(event = "admin.readOverrides");
    }

    function readEventOverrides(event, rc, prc) {
        prc.description   = "Event Env Overrides";
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = "enveventoverrides"));
        prc.submitAction  = "admin.saveEventOverrides";

        event.setView(view = "/views/admin/readOverrides");
    }

    function saveEventOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: "");

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = "enveventoverrides", override = raw);

            flash.put(
                name  = "alert",
                value = {
                    "type"       : "success",
                    "dismissible": true,
                    "icon"       : "bi bi-copy",
                    "message"    : "Successfully saved!"
                }
            );
        }
        catch(any e) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Error saving. Please try again. #e.message#"
                }
            );
        }

        relocate(event = "admin.readEventOverrides");
    }

    function readNameOverrides(event, rc, prc) {
        prc.description   = "Name Env Overrides";
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = "leekducknamemap"));
        prc.submitAction  = "admin.saveNameOverrides";

        event.setView(view = "/views/admin/readOverrides");
    }

    function saveNameOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: "");

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = "leekducknamemap", override = raw);

            flash.put(
                name  = "alert",
                value = {
                    "type"       : "success",
                    "dismissible": true,
                    "icon"       : "bi bi-copy",
                    "message"    : "Successfully saved!"
                }
            );
        }
        catch(any e) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi-exclamation-diamond-fill",
                    "message"    : "Error saving. Please try again. #e.message#"
                }
            );
        }
        relocate(event = "admin.readNameOverrides");
    }

    function updateSiteMap(event, rc, prc) {
        adminService.updateSiteMap();

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi bi-file-earmark-check",
                "message"    : "Successfully Updated."
            }
        );
        relocate(event = "admin");
    }

    function buildCostumeData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildCostumeData();
        relocate(event = "admin.listPokemon");
    }

}
