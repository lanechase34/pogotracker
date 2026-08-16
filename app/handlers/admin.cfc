component extends="base" {

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
        taskManager           : 'GET',
        readOverrides         : 'GET',
        saveOverrides         : 'POST',
        readEventOverrides    : 'GET',
        saveEventOverrides    : 'POST',
        readNameOverrides     : 'GET',
        saveNameOverrides     : 'POST',
        logViewer             : 'GET',
        requestLog            : 'GET',
        getRequests           : 'GET',
        updateSiteMap         : 'GET',
        buildCostumeData      : 'GET',
        getCacheData          : 'GET',
        seedCommDays          : 'GET'
    };

    property name="auditService"      inject="services.audit";
    property name="adminService"      inject="services.admin";
    property name="blogService"       inject="services.blog";
    property name="bugService"        inject="services.bug";
    property name="cache"             inject="cachebox:appCache";
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
        prc.title      = 'Admin | #getSetting('title')#';
        prc.metaRobots = 'noindex, nofollow';
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
        param name="rc.costume"             default="false";
        param name="rc['search[value]']"    default="";
        param name="rc['order[0][column]']" default="";
        param name="rc['order[0][dir]']"    default="";
        param name="rc['order[1][column]']" default="";
        param name="rc['order[1][dir]']"    default="";

        if(hasValidationErrors(target = rc, constraints = 'admin.getPokemon')) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = pokemonService.getTable(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]'],
            rc['order[1][column]'],
            rc['order[1][dir]'],
            rc.costume == 'true'
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

        if(hasValidationErrors(target = rc, constraints = 'admin.getTrainers')) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = trainerService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
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

        if(hasValidationErrors(target = rc, constraints = 'admin.getAudits')) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
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

        if(hasValidationErrors(target = rc, constraints = 'admin.getRequests')) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = auditService.getRequests(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
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

        if(hasValidationErrors(target = rc, constraints = 'admin.getBugs')) {
            jsonValidationFailure(event = event);
            return;
        }

        prc.responseObj.data = bugService.get(
            rc.length,
            rc.start,
            rc['search[value]'],
            rc['order[0][column]'],
            rc['order[0][dir]']
        );
        prc.responseObj.data.draw  = rc.draw;
        prc.responseObj.statusCode = 200;

        renderJson(event = event, response = prc.responseObj.data);
    }

    function serverInfo(event, rc, prc) {
        prc.timezone    = getTimezone();
        prc.timestamp   = now();
        prc.securityMap = securityService.getSecurityMap();
        prc.baseURL     = getSetting('environment') != 'production' ? 'localhost' : '';
    }

    function getCacheData(event, rc, prc) {
        renderJson(event = event, response = adminService.getCacheData());
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
            // Validate this is a known log file
            if(!prc.logs.recordCount || !listFindNoCase(valueList(prc.logs.name), rc.filename)) {
                htmlValidationFailure(event = event);
                return;
            }
            prc.logContent = adminService.readLog(rc.filename, rc.start, rc.end);
        }

        prc.header = 'Log Viewer';
    }

    function readOverrides(event, rc, prc) {
        prc.description   = 'Pokemon Env Overrides';
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = 'envpokedexoverrides'));
        prc.submitAction  = 'admin.saveOverrides';
    }

    function saveOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: '');

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = 'envpokedexoverrides', override = raw);

            sessionService.setAlert(
                'success',
                true,
                'bi bi-copy',
                'Successfully saved!'
            );
        }
        catch(any e) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Error saving. Please try again. #e.message#'
            );
        }
        relocate(event = 'admin.readOverrides');
    }

    function readEventOverrides(event, rc, prc) {
        prc.description   = 'Event Env Overrides';
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = 'enveventoverrides'));
        prc.submitAction  = 'admin.saveEventOverrides';

        event.setView(view = '/views/admin/readoverrides');
    }

    function saveEventOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: '');

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = 'enveventoverrides', override = raw);

            sessionService.setAlert(
                'success',
                true,
                'bi bi-copy',
                'Successfully saved!'
            );
        }
        catch(any e) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Error saving. Please try again. #e.message#'
            );
        }

        relocate(event = 'admin.readEventOverrides');
    }

    function readNameOverrides(event, rc, prc) {
        prc.description   = 'Name Env Overrides';
        prc.overridesJSON = serializeJSON(adminService.getOverride(name = 'leekducknamemap'));
        prc.submitAction  = 'admin.saveNameOverrides';

        event.setView(view = '/views/admin/readoverrides');
    }

    function saveNameOverrides(event, rc, prc) {
        try {
            var raw = toString(rc.json ?: '');

            // Validate it's actually JSON before saving
            raw = deserializeJSON(raw);

            adminService.saveOverride(name = 'leekducknamemap', override = raw);

            sessionService.setAlert(
                'success',
                true,
                'bi bi-copy',
                'Successfully saved!'
            );
        }
        catch(any e) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Error saving. Please try again. #e.message#'
            );
        }
        relocate(event = 'admin.readNameOverrides');
    }

    function updateSiteMap(event, rc, prc) {
        adminService.updateSiteMap();

        sessionService.setAlert(
            'success',
            true,
            'bi bi-file-earmark-check',
            'Successfully Updated.'
        );
        relocate(event = 'admin');
    }

    function buildCostumeData(event, rc, prc) {
        cfsetting(requestTimeout = 600);
        adminService.buildCostumeData();
        relocate(event = 'admin.listPokemon');
    }

    function seedCommDays(event, rc, prc) {
        var pastCommunityDays = [
            {'name': 'Sobble', 'date': 'July 4 2026'},
            {'name': 'Frigibax', 'date': 'June 20 2026'},
            {'name': 'Lechonk', 'date': 'May 9 2026'},
            {'name': 'Tinkatink', 'date': 'April 11 2026'},
            {'name': 'Scorbunny', 'date': 'March 14 2026'},
            {'name': 'Vulpix', 'date': 'February 1 2026'},
            {'name': 'Alolan Vulpix', 'date': 'February 1 2026'},
            {'name': 'Grookey', 'date': 'January 18 2026'},
            {'name': 'Pikipek', 'date': 'November 30 2025'},
            {'name': 'Solosis', 'date': 'October 12 2025'},
            {'name': 'Flabébé', 'date': 'September 14 2025'},
            {'name': 'Rookidee', 'date': 'August 30 2025'},
            {'name': 'Quaxly', 'date': 'July 20 2025'},
            {'name': 'Jangmo-o', 'date': 'June 21 2025'},
            {'name': 'Pawmi', 'date': 'May 11 2025'},
            {'name': 'Vanillite', 'date': 'April 27 2025'},
            {'name': 'Fuecoco', 'date': 'March 8 2025'},
            {'name': 'Karrablast', 'date': 'February 9 2025'},
            {'name': 'Shelmet', 'date': 'February 9 2025'},
            {'name': 'Sprigatito', 'date': 'January 5 2025'},
            {'name': 'Mankey', 'date': 'November 10 2024'},
            {'name': 'Sewaddle', 'date': 'October 5 2024'},
            {'name': 'Ponyta', 'date': 'September 14 2024'},
            {'name': 'Galarian Ponyta', 'date': 'September 14 2024'},
            {'name': 'Popplio', 'date': 'August 31 2024'},
            {'name': 'Beldum', 'date': 'August 19 2024'},
            {'name': 'Tynamo', 'date': 'July 21 2024'},
            {'name': 'Goomy', 'date': 'June 9 2024'},
            {'name': 'Bounsweet', 'date': 'May 19 2024'},
            {'name': 'Bellsprout', 'date': 'April 20 2024'},
            {'name': 'Litten', 'date': 'March 16 2024'},
            {'name': 'Chansey', 'date': 'February 4 2024'},
            {'name': 'Rowlet', 'date': 'January 6 2024'},
            {'name': 'Wooper', 'date': 'November 5 2023'},
            {'name': 'Paldean Wooper', 'date': 'November 5 2023'},
            {'name': 'Timburr', 'date': 'October 15 2023'},
            {'name': 'Grubbin', 'date': 'September 23 2023'},
            {'name': 'Froakie', 'date': 'August 13 2023'},
            {'name': 'Poliwag', 'date': 'July 30 2023'},
            {'name': 'Axew', 'date': 'June 10 2023'},
            {'name': 'Fennekin', 'date': 'May 21 2023'},
            {'name': 'Togetic', 'date': 'April 15 2023'},
            {'name': 'Slowpoke', 'date': 'March 18 2023'},
            {'name': 'Galarian Slowpoke', 'date': 'March 18 2023'},
            {'name': 'Noibat', 'date': 'February 5 2023'},
            {'name': 'Chespin', 'date': 'January 7 2023'},
            {'name': 'Teddiursa', 'date': 'November 12 2022'},
            {'name': 'Litwick', 'date': 'October 15 2022'},
            {'name': 'Roggenrola', 'date': 'September 18 2022'},
            {'name': 'Galarian Zigzagoon', 'date': 'August 13 2022'},
            {'name': 'Starly', 'date': 'July 17 2022'},
            {'name': 'Deino', 'date': 'June 25 2022'},
            {'name': 'Alolan Geodude', 'date': 'May 21 2022'},
            {'name': 'Stufful', 'date': 'April 23 2022'},
            {'name': 'Sandshrew', 'date': 'March 13 2022'},
            {'name': 'Alolan Sandshrew', 'date': 'March 13 2022'},
            {'name': 'Hoppip', 'date': 'February 12 2022'},
            {'name': 'Spheal', 'date': 'January 16 2022'},
            {'name': 'Shinx', 'date': 'November 21 2021'},
            {'name': 'Duskull', 'date': 'October 9 2021'},
            {'name': 'Oshawott', 'date': 'September 19 2021'},
            {'name': 'Eevee', 'date': 'August 14 2021'},
            {'name': 'Tepig', 'date': 'July 3 2021'},
            {'name': 'Gible', 'date': 'June 6 2021'},
            {'name': 'Swablu', 'date': 'May 15 2021'},
            {'name': 'Snivy', 'date': 'April 11 2021'},
            {'name': 'Fletchling', 'date': 'March 6 2021'},
            {'name': 'Roselia', 'date': 'February 7 2021'},
            {'name': 'Machop', 'date': 'January 16 2021'},
            {'name': 'Magmar', 'date': 'November 21 2020'},
            {'name': 'Electabuzz', 'date': 'November 15 2020'},
            {'name': 'Charmander', 'date': 'October 17 2020'},
            {'name': 'Porygon', 'date': 'September 20 2020'},
            {'name': 'Magikarp', 'date': 'August 8 2020'},
            {'name': 'Gastly', 'date': 'July 19 2020'},
            {'name': 'Weedle', 'date': 'June 20 2020'},
            {'name': 'Seedot', 'date': 'May 24 2020'},
            {'name': 'Abra', 'date': 'April 25 2020'},
            {'name': 'Rhyhorn', 'date': 'February 22 2020'},
            {'name': 'Piplup', 'date': 'January 19 2020'},
            {'name': 'Chimchar', 'date': 'November 16 2019'},
            {'name': 'Trapinch', 'date': 'October 12 2019'},
            {'name': 'Turtwig', 'date': 'September 15 2019'},
            {'name': 'Ralts', 'date': 'August 3 2019'},
            {'name': 'Mudkip', 'date': 'July 21 2019'},
            {'name': 'Slakoth', 'date': 'June 8 2019'},
            {'name': 'Torchic', 'date': 'May 19 2019'},
            {'name': 'Bagon', 'date': 'April 13 2019'},
            {'name': 'Treecko', 'date': 'March 23 2019'},
            {'name': 'Swinub', 'date': 'February 16 2019'},
            {'name': 'Totodile', 'date': 'January 12 2019'},
            {'name': 'Cyndaquil', 'date': 'November 10 2018'},
            {'name': 'Beldum', 'date': 'October 21 2018'},
            {'name': 'Chikorita', 'date': 'September 22 2018'},
            {'name': 'Eevee', 'date': 'August 11 2018'},
            {'name': 'Squirtle', 'date': 'July 8 2018'},
            {'name': 'Larvitar', 'date': 'June 16 2018'},
            {'name': 'Charmander', 'date': 'May 19 2018'},
            {'name': 'Mareep', 'date': 'April 15 2018'},
            {'name': 'Bulbasaur', 'date': 'March 25 2018'},
            {'name': 'Dratini', 'date': 'February 24 2018'},
            {'name': 'Pikachu', 'date': 'January 20 2018'},
            {
                'name'     : 'Bulbasaur',
                'date'     : 'Jan 22 2022',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Mudkip',
                'date'     : 'Apr 10 2022',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Dratini',
                'date'     : 'Nov 5 2022',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Larvitar',
                'date'     : 'Jan 21 2023',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Swinub',
                'date'     : 'Apr 29 2023',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Squirtle',
                'date'     : 'Jul 9 2023',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Charmander',
                'date'     : 'Sep 2 2023',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Mareep',
                'date'     : 'Nov 25 2023',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Porygon',
                'date'     : 'Jan 20 2024',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Bagon',
                'date'     : 'Apr 7 2024',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Cyndaquil',
                'date'     : 'Jun 22 2024',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Beldum',
                'date'     : 'Aug 18 2024',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Ralts',
                'date'     : 'Jan 25 2025',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Totodile',
                'date'     : 'Mar 22 2025',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Machop',
                'date'     : 'May 24 2025',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Eevee',
                'date'     : 'Jul 5 2025',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Piplup',
                'date'     : 'Jan 4 2026',
                'eventname': 'Community Day Classic'
            },
            {
                'name'     : 'Deino',
                'date'     : 'May 16 2026',
                'eventname': 'Community Day Classic'
            }
        ];

        pastCommunityDays.each((commDay) => {
            // 1. Get the comm day featured pokemon
            var pokemonid = getByNameAndGender(
                name   = commDay.name,
                gender = commDay.keyExists('gender') ? commDay.gender : ''
            );

            // 2. Get all the comm day's evolutions
            var evolutionIds = getEvolutionChainIds(pokemonid = pokemonid);

            // 3. Create the event
            var eventName = commDay.KeyExists('eventname') ? '#commDay.name# #commDay.eventname#' : '#commDay.name# Community Day';
            var customid  = createEventRecord(
                name   = eventName,
                begins = parseDateTime(commDay.date),
                ends   = parseDateTime(commDay.date)
            );

            // 4. Create the event spawns
            evolutionIds.append(pokemonid)
            insertEventSpawns(customid = customid, pokemon = evolutionIds);
        });

        writeDump(now());
        abort;
    }

    /**
     * Get a pokemon reco by name a gender
     *
     * @name   pokemon name
     * @gender pokemon gender
     */
    private numeric function getByNameAndGender(required string name, required string gender) {
        return queryExecute(
            '
            SELECT id
            FROM pokemon
            WHERE name = :name
                AND gender = :gender
                AND costume = :costume
                AND costumetype = :costumetype
            ',
            {
                name       : {value: name, cfsqltype: 'varchar'},
                gender     : {value: gender, cfsqltype: 'varchar'},
                costume    : {value: false, cfsqltype: 'boolean'},
                costumetype: {value: '', cfsqltype: 'varchar'}
            }
        ).id;
    }

    /**
     * Get the ids of all pokemon this pokemon evolves into, directly or transitively
     *
     * @pokemonid pokemon id
     */
    private array function getEvolutionChainIds(required numeric pokemonid) {
        var results = queryExecute(
            '
            WITH RECURSIVE evolution_chain AS (
                SELECT evolutionid, special
                FROM evolution
                WHERE pokemonid = :pokemonid

                UNION ALL

                SELECT e.evolutionid, e.special
                FROM evolution e
                INNER JOIN evolution_chain ec ON e.pokemonid = ec.evolutionid
            )
            SELECT DISTINCT evolutionid
            FROM evolution_chain
            WHERE special = false
            ',
            {pokemonid: {value: pokemonid, cfsqltype: 'integer'}}
        );

        return valueArray(results, 'evolutionid');
    }

    /**
     * Create a custom event record
     *
     * @trainerid trainer id creating the event
     * @name      event name
     * @begins    event start datetime
     * @ends      event end datetime
     */
    private numeric function createEventRecord(
        required string name,
        required date begins,
        required date ends
    ) {
        var result = queryExecute(
            '
        INSERT INTO custom (name, public, begins, ends, trainerid, created, updated, commday)
        VALUES (:name, true, :begins, :ends, :trainerid, now(), now(), true)
        RETURNING id
        ',
            {
                name     : {value: name, cfsqltype: 'varchar'},
                begins   : {value: begins, cfsqltype: 'timestamp'},
                ends     : {value: ends, cfsqltype: 'timestamp'},
                trainerid: {value: 1, cfsqltype: 'integer'}
            }
        );

        return result.id;
    }

    /**
     * Insert pokemon ids as event spawns for a custom event, skipping ones already present
     *
     * @customid custom event id
     * @pokemon  array of pokemon ids to spawn in this event
     */
    private void function insertEventSpawns(required numeric customid, required array pokemon) {
        pokemon.each((pokemonid) => {
            queryExecute(
                '
                INSERT INTO custompokedex (customid, pokemonid, created, updated)
                SELECT :customid, :pokemonid, now(), now()
                WHERE NOT EXISTS (
                    SELECT 1 FROM custompokedex
                    WHERE customid = :customid
                    AND pokemonid = :pokemonid
                )
                ',
                {customid: {value: customid, cfsqltype: 'integer'}, pokemonid: {value: pokemonid, cfsqltype: 'integer'}}
            );
        });

        return;
    }

}
