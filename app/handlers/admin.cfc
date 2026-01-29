component {

    this.allowedMethods = {
        index                 : 'GET',
        buildPokemonData      : 'GET',
        listPokemon           : 'GET',
        getPokemon            : 'GET',
        listTrainers          : 'GET',
        getTrainers           : 'GET',
        editTrainer           : 'GET',
        createRegistrationLink: 'GET',
        buildLevels           : 'GET',
        auditLog              : 'GET',
        getAudits             : 'GET',
        bugLog                : 'GET',
        getBugs               : 'GET',
        serverInfo            : 'GET',
        buildMedalData        : 'GET',
        showMedalData         : 'GET',
        buildMoveData         : 'GET',
        showMoveData          : 'GET',
        saveState             : 'POST',
        taskManager           : 'GET'
    };

    property name="auditService"      inject="services.audit";
    property name="adminService"      inject="services.admin";
    property name="blogService"       inject="services.blog";
    property name="bugService"        inject="services.bug";
    property name="cacheService"      inject="services.cache";
    property name="friendService"     inject="services.friend";
    property name="medalService"      inject="services.medal";
    property name="moveService"       inject="services.move";
    property name="pokemonService"    inject="services.pokemon";
    property name="pokedexService"    inject="services.pokedex";
    property name="generationService" inject="services.generation";
    property name="securityService"   inject="services.security";
    property name="sessionService"    inject="services.session";
    property name="trainerService"    inject="services.trainer";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title = 'Admin - #getSetting('title')#';
    }

    function index(event, rc, prc) {
    }

    function buildPokemonData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildPokemonData();
        relocate(event = 'admin.listPokemon');
    }

    function listPokemon(event, rc, prc) {
    }

    function getPokemon(event, rc, prc) {
        param name="rc.draw"                default="1";
        param name="rc.length"              default="50";
        param name="rc.start"               default="0";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc['order[1][column]']" default="";
        param name="rc['order[1][dir]']"    default="";

        prc.responseObj.data = pokemonService.getTable(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]'],
            rc['order[1][column]'],
            rc['order[1][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        event.renderData(
            type       = 'json',
            data       = prc.responseObj.data,
            statusCode = prc.responseObj.statusCode
        );
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

        prc.responseObj.data = trainerService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        event.renderData(
            type       = 'json',
            data       = prc.responseObj.data,
            statusCode = prc.responseObj.statusCode
        );
    }

    function editTrainer(event, rc, prc) {
        param name="rc.trainerid" default="";

        prc.validation = validate(target = rc, constraints = 'editTrainer');
        if(prc.validation.hasErrors()) {
            relocate(uri = '/');
        }

        prc.trainerid      = parseNumber(rc.trainerid);
        prc.trainer        = trainerService.getFromId(prc.trainerid);
        prc.baseIcons      = trainerService.getIconMap();
        prc.unlockedIcons  = prc.trainer.getUnlockedIcons();
        prc.securityLevels = securityService.getSecurityLevels();

        event.setView(
            view     = '/views/trainer/modal/editProfile',
            nolayout = true,
            args     = {
                trainer       : prc.trainer,
                iconMap       : arrayMerge(prc.baseIcons, prc.unlockedIcons),
                admin         : true,
                securityLevels: prc.securityLevels,
                viewMap       : getSetting('viewMap'),
                generations   : generationService.getAll(),
                pageMap       : getSetting('pageMap')
            }
        );
    }

    function createRegistrationLink(event, rc, prc) {
        var code = securityService.createRegistrationLink();
        sessionService.setAlert(
            'success',
            true,
            'bi bi-copy',
            'Success! Registration Link : #cgi.http_host#/register/#code#'
        );

        prc.responseObj.message    = 'Success!';
        prc.responseObj.statusCode = 200;
        event.renderData(
            type       = 'json',
            data       = prc.responseObj,
            statusCode = prc.responseObj.statusCode
        );
    }

    function buildLevels(event, rc, prc) {
        adminService.buildLevels();
        sessionService.setAlert(
            'success',
            true,
            'bi-check-square-fill',
            'Success!'
        );
        relocate('admin.index');
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

        prc.responseObj.data = auditService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        event.renderData(
            type       = 'json',
            data       = prc.responseObj.data,
            statusCode = prc.responseObj.statusCode
        );
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

        prc.responseObj.data = auditService.getRequests(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        event.renderData(
            type       = 'json',
            data       = prc.responseObj.data,
            statusCode = prc.responseObj.statusCode
        );
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

        prc.responseObj.data = bugService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        event.renderData(
            type       = 'json',
            data       = prc.responseObj.data,
            statusCode = prc.responseObj.statusCode
        );
    }

    function serverInfo(event, rc, prc) {
        prc.timezone    = getTimezone();
        prc.timestamp   = now();
        prc.cacheData   = cacheService.getData();
        prc.cacheStats  = cacheService.getStats();
        prc.securityMap = securityService.getSecurityMap();
    }

    function buildMedalData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildMedalData();
        relocate(event = 'admin.showMedalData');
    }

    function showMedalData(event, rc, prc) {
        prc.data = medalService.getAll();
    }

    function buildMoveData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildMoveData();
        relocate(event = 'admin.showMoveData');
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

        setSetting('signups', (rc?.signupsSwitch ?: 'off') == 'on');
        setSetting('fetchCount', parseNumber(rc.fetchCount));
        setSetting('eventDaysBefore', parseNumber(rc.eventDaysBefore));
        setSetting('logRequests', (rc?.logRequestsSwitch ?: 'off') == 'on');

        if(rc.eventLink.len()) {
            adminService.createEvent(eventLink = rc.eventLink);
        }

        if(rc.pokemonLink.len()) {
            adminService.createPokemon(pokemonLink = rc.pokemonLink);
        }

        if(rc.pokemonJson.len() && isJSON(rc.pokemonJson) && isStruct(deserializeJSON(rc.pokemonJson))) {
            adminService.addPokemon(deserializeJSON(rc.pokemonJson));
        }

        sessionService.setAlert(
            'success',
            true,
            'bi bi-file-earmark-check',
            'Successfully Saved.'
        );
        relocate(event = 'admin');
    }

    function taskManager(event, rc, prc) {
        prc.taskInfo = adminService.getTaskInfo();
    }

    function logViewer(event, rc, prc) {
        param name="rc.filename" default="";
        param name="rc.start"    default="1";
        param name="rc.end"      default="1000";

        prc.logs       = adminService.getLogs();
        prc.logContent = '';
        if(rc.filename.len()) {
            prc.logContent = adminService.readLog(rc.filename, rc.start, rc.end);
        }

        prc.header = 'Log Viewer';
    }

}
