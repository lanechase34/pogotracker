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
        requestLog        : "GET",
        getRequests       : "GET",
        updateSiteMap     : "POST",
        buildCostumeData  : "POST",
        getCacheData      : "GET"
    };

    property name="accountService"    inject="services.account";
    property name="auditService"      inject="services.audit";
    property name="adminService"      inject="services.admin";
    property name="bugService"        inject="services.bug";
    property name="medalService"      inject="services.medal";
    property name="moveService"       inject="services.move";
    property name="pokemonService"    inject="services.pokemon";
    property name="generationService" inject="services.generation";
    property name="trainerService"    inject="services.trainer";

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
            rc.length,
            rc.start,
            rc["search[value]"],
            rc["order[0][column]"],
            rc["order[0][dir]"],
            rc["order[1][column]"],
            rc["order[1][dir]"],
            rc.costume == "true"
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

        prc.responseObj.data = trainerService.get(
            rc.length,
            rc.start,
            rc["search[value]"],
            rc["order[0][column]"],
            rc["order[0][dir]"]
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function editTrainer(event, rc, prc) {
        param name="rc.trainerid" default="";

        prc.validation = validate(target = rc, constraints = "editTrainer");
        if(prc.validation.hasErrors()) {
            relocate(uri = "/");
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.trainer   = trainerService.getFromId(prc.trainerid);

        // Accounts that outrank you can't be edited (trainer.updateProfile enforces it too)
        if(
            prc.trainer.getId() != prc.oCurrentUser.getId()
            && val(prc.trainer.getSecurityLevel()) > val(prc.oCurrentUser.getSecurityLevel())
        ) {
            relocate(uri = "/unauthorized");
        }

        prc.baseIcons      = trainerService.getIconMap();
        prc.unlockedIcons  = prc.trainer.getUnlockedIcons();
        prc.securityLevels = accountService.getAssignableLevels();

        // Use the edited trainer's settings, falling back to defaults for any missing keys
        prc.settings = duplicate(getSetting("defaultSettings"));
        structAppend(prc.settings, prc.trainer.getSettings(), true);

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

    function auditLog(event, rc, prc) {
    }

    /**
     * @rc.draw   updates with each ajax request
     * @rc.length entries per page
     * @rc.start  for pagination
     * @rc        ['search[value]'] search box value
     * @rc        ['order[0][column]'] order column
     * @rc        ['order[0][dir]'] order direction
     */
    function getAudits(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = "admin.getAudits")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.get(
            rc.length,
            rc.start,
            rc["search[value]"],
            rc["order[0][column]"],
            rc["order[0][dir]"]
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function requestLog(event, rc, prc) {
    }

    function getRequests(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = "admin.getRequests")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.getRequests(
            rc.length,
            rc.start,
            rc["search[value]"],
            rc["order[0][column]"],
            rc["order[0][dir]"]
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function bugLog(event, rc, prc) {
    }

    function getBugs(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = "admin.getBugs")) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = bugService.get(
            rc.length,
            rc.start,
            rc["search[value]"],
            rc["order[0][column]"],
            rc["order[0][dir]"]
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
            adminService.addPokemon(deserializeJSON(rc.pokemonJson));
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

        if(hasValidationErrors(target = rc, constraints = "admin.runTask")) {
            jsonValidationFailure(event = event);
            return;
        }

        cfsetting(requestTimeout = 600);

        try {
            prc.responseObj.data = adminService.runTask(rc.scheduler, rc.name);
        }
        catch(TaskNotFound e) {
            jsonNotFound(event = event, message = e.message);
            return;
        }

        prc.responseObj.success    = true;
        prc.responseObj.statusCode = 200;
        renderJson(event = event, response = prc.responseObj);
    }

    function logViewer(event, rc, prc) {
        param name="rc.filename" default="";
        param name="rc.start"    default="1";
        param name="rc.end"      default="1000";

        prc.logs       = adminService.getLogs();
        prc.logContent = "";
        if(rc.filename.len()) {
            // Validate this is a known log file
            if(!prc.logs.recordCount || !listFindNoCase(valueList(prc.logs.name), rc.filename)) {
                htmlValidationFailure(event = event);
                return;
            }
            prc.logContent = adminService.readLog(rc.filename, rc.start, rc.end);
        }

        prc.header = "Log Viewer";
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

        event.setView(view = "/views/admin/readoverrides");
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

        event.setView(view = "/views/admin/readoverrides");
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
