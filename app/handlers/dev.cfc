component {

    property name="adminService"      inject="services.admin";
    property name="blogService"       inject="services.blog";
    property name="cacheService"      inject="services.cache";
    property name="emailService"      inject="services.email";
    property name="friendService"     inject="services.friend";
    property name="moveService"       inject="services.move";
    property name="pokemonService"    inject="services.pokemon";
    property name="pokedexService"    inject="services.pokedex";
    property name="generationService" inject="services.generation";
    property name="scraperService"    inject="services.scraper";
    property name="securityService"   inject="services.security";
    property name="sessionService"    inject="services.session";
    property name="trainerService"    inject="services.trainer";

    function preHandler(event, rc, prc, action, eventArguments) {
        // These functions only available in develop
        if(getSetting('environment') == 'production') {
            relocate(uri = '/');
        }
    }

    function index(event, rc, prc) {
    }

    // Create test trainer user
    function createTestTrainer(event, rc, prc) {
        prc.name        = rc?.name ?: left(createUUID(), 30);
        var testTrainer = entityNew('trainer', {'username': prc.name});
        entitySave(testTrainer);
        ormFlush();
        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    // Admin endpoint to populate a trainer's pokedex
    function registerRandomPokemon(event, rc, prc) {
        prc.register = rc?.register ?: 10;
        prc.region   = rc?.region ?: 'Kanto';
        prc.trainer  = trainerService.getFromId(rc?.trainer ?: session.trainerid);

        // Get list of pokemon from the region
        prc.regionPokemon = pokemonService.get(
            {'generation': generationService.getFromRegion(prc.region), 'form': false},
            'number asc'
        );

        // Randomly register pokemon from this region list
        for(var i = 0; i < prc.register; i++) {
            var rand = randRange(1, prc.regionPokemon.len());

            pokedexService.register(
                prc.trainer,
                prc.regionPokemon[rand],
                true,
                randRange(1, 10) > 8,
                false
            );
        }

        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    function createRandomBlogs(event, rc, prc) {
        prc.create  = rc?.create ?: 3;
        prc.trainer = trainerService.getFromId(session.trainerid);
        for(var i = 1; i <= prc.create; i++) {
            var theText = 'Placeholder text. ';
            var body    = theText;
            var rand    = randRange(10, 50);
            for(var j = 1; j <= rand; j++) {
                body &= theText;
            }

            var newBlog = entityNew(
                'blog',
                {
                    'header' : createUUID().replace('-', '_', 'all'),
                    'body'   : body,
                    'trainer': prc.trainer
                }
            );
            entitySave(newBlog);
            ormFlush();
        }

        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }


    function createBlog(event, rc, prc) {
        prc.trainer = trainerService.getFromId(session.trainerid);

        var header = 'POGO Tracker Dev Update';
        var body   = '<p>From the latest github commit:</p><p>Working on layout.</p><p>Add freinds.</p><p>Can I make this blog one of those fancy text entry boxes? That would be cool</p>';

        blogService.create(header, body, prc.trainer);
        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    function ormReload(event, rc, prc) {
        ormReload();
        sessionService.setAlert(
            'success',
            true,
            'bi-check-square-fill',
            'Success!'
        );
        relocate('dev.index');
    }

    function forceError(event, rc, prc) {
        // this will not work
        var chase = 1 / 0;
    }

    // daniellebuleje@yahoo.com
    function sendTestEmail(event, rc, prc) {
        emailService.sendTestEmail();
        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    function createRandomTeam(event, rc, prc) {
        param name="rc.teamid" default="";

        if(rc.teamid.len()) {
            prc.teamid = parseNumber(rc.teamid);
            prc.team   = entityLoadByPK('team', prc.teamid);
        }
        else {
            var pokemon = pokemonService.getAll();
            var team    = [];
            // 3 pokemon on a team
            while(team.len() < 3) {
                var curr = {
                    pokemon: '',
                    fast   : '',
                    charge1: '',
                    charge2: ''
                };

                // select random pokemon
                curr.pokemon = pokemon[randRange(1, pokemon.len())];

                // select random fastmove
                var fastmoves = curr.pokemon.getMoves('fast', 'normal');

                if(!fastMoves.len()) continue;

                curr.fast = fastmoves[randRange(1, fastmoves.len())];

                // select 2 random charge moves
                var chargemoves = curr.pokemon.getMoves('charge', 'normal');

                if(chargemoves.len() < 2) continue;
                var charge1rand = randRange(1, chargemoves.len())
                curr.charge1    = chargemoves[charge1rand];

                if(chargemoves.len() > 1) {
                    var charge2rand = randRange(1, chargemoves.len());
                    while(charge2rand == charge1rand) {
                        charge2rand = randRange(1, chargemoves.len()); // make sure to select a different move
                    }
                    curr.charge2 = chargeMoves[charge2rand];
                }


                team.append(curr);
            }

            prc.team = entityNew(
                'team',
                {
                    p1       : team[1].pokemon,
                    p1fast   : team[1].fast,
                    p1charge1: team[1].charge1,
                    p1charge2: team[1].charge2,
                    p2       : team[2].pokemon,
                    p2fast   : team[2].fast,
                    p2charge1: team[2].charge1,
                    p2charge2: team[2].charge2,
                    p3       : team[3].pokemon,
                    p3fast   : team[3].fast,
                    p3charge1: team[3].charge1,
                    p3charge2: team[3].charge2,
                    trainer  : trainerService.getFromId(session.trainerid),
                    name     : left(createUUID(), 50)
                }
            );
            entitySave(prc.team);
            ormFlush();
        }

        prc.header = '#prc.team.getName()#';
    }

    function viewEmail(event, rc, prc) {
        param name="rc.filename" default="";

        prc.testEmails = directoryList(
            path    : '#getSetting('testEmailPath')#',
            recurse : false,
            listInfo: 'query',
            sort    : 'DateLastModified desc'
        );

        prc.mailContent = '';
        if(rc.filename.len()) {
            prc.mailContent = fileRead('#getSetting('testEmailPath')#/#rc.filename#.html');
        }

        prc.header = 'View Test Emails';
    }

    function deleteEmail(event, rc, prc) {
        directoryDelete('#getSetting('testEmailPath')#', true);
        directoryCreate('#getSetting('testEmailPath')#');
    }

    function testEventTask(event, rc, prc) {
        adminService.createEvents();
        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    function createUnownJson(event, rc, prc) {
        var unowns = [];
        for(var i = 0; i < 26; i++) {
            unowns.append(chr(65 + i)); // makes array of alphabet letters
        }

        // Special Cases
        unowns.append('!');
        unowns.append('?');

        var result = {};
        var base   = {
            'live'       : true,
            'Flee'       : 10,
            'Catch'      : 30,
            'shadowshiny': false,
            'giga'       : false,
            'number'     : 201,
            'evolutions' : [],
            'form'       : false,
            'mega'       : false,
            'Attack'     : 136,
            'HP'         : 134,
            'shadow'     : false,
            'shiny'      : true,
            'gender'     : '',
            'Name'       : '',
            'tradable'   : true,
            'Type'       : ['Psychic'],
            'sprite'     : '',
            'generation' : 2.5,
            'moves'      : ['HIDDEN_POWER', 'STRUGGLE'],
            'Defense'    : 91,
            'formtype'   : ''
        };

        unowns.each((letter) => {
            var curr      = duplicate(base);
            curr.name     = 'Unown #letter#';
            curr.sprite   = letter == '!' ? '201-exclamation' : letter == '?' ? '201-question' : '201-#lCase(letter)#';
            curr.formtype = letter == '!' ? 'exclamation' : letter == '?' ? 'question' : '#lCase(letter)#';
            result.insert(curr.name, curr);
        });

        event.renderData(
            type       = 'json',
            data       = {'response': serializeJSON(result)},
            statusCode = 200
        );
    }

    function cpCalculator(event, rc, prc) {
        param name="rc.pokemonid" default="";

        prc.allPokemon = pokemonService.getAll();

        if(rc.pokemonid.len()) {
            prc.pokemonDetail = pokemonService.getDetail(parseNumber(rc.pokemonid));
        }
    }

    function createCPMultiplierJson(event, rc, prc) {
        var cpDoc       = scraperService.getData('https://pokemongo.fandom.com/wiki/Combat_Power');
        var cpTableData = cpDoc
            .body()
            .select('##Level_Scalar')
            .select('tbody')
            .select('tr');
        var multiplierJson = {};

        cpTableData.each((tr, trindex) => {
            if(trindex == 1) continue; // first row is 'header'

            var currLevel = -1;
            var rowData   = tr.select('td');

            rowData.each((td, tdindex) => {
                // odd index is the level
                // even index is the multiplier
                if(tdindex % 2 == 1) {
                    currLevel = parseNumber(reReplace(td.text(), '[^0-9.]', ''));
                }
                else {
                    multiplierJson.insert(currLevel, parseNumber(td.text()));
                }
            });
        });

        event.renderData(
            type       = 'json',
            data       = {'response': serializeJSON(multiplierJson)},
            statusCode = 200
        );
    }

    function testJsoup(event, rc, prc) {
        prc.userAgent = scraperService
            .getData('https://httpbin.io/user-agent')
            .body()
            .text();
        event.renderData(
            type       = 'json',
            data       = {'response': prc.userAgent},
            statusCode = 200
        );
    }

    function createTypeSymbols(event, rc, prc) {
        var typeDoc   = scraperService.getData('https://pokemongo.fandom.com/wiki/Types');
        var typeTable = typeDoc
            .body()
            .select('##gallery-0')
            .select('img');

        typeTable.each((img, imgindex) => {
            var imgSrc = img.attr('src');
            if(!imgSrc.contains('')) continue;
            var type = lCase(listToArray(listToArray(imgSrc, '_')[2], '.')[1]);
            cfhttp(
                url    = imgSrc,
                result = "imgResult",
                method = "GET"
            );
            var img = imageNew(imgResult.filecontent);
            img.write('/includes/images/type/#type#');
        });

        event.renderData(
            type       = 'json',
            data       = {'response': 'success #now()#'},
            statusCode = 200
        );
    }

    function debugInfo(event, rc, prc) {
    }

    function updateSiteMap(event, rc, prc) {
        var filePath = '#getSetting('basePath')#sitemap.xml';
        var sitemap  = xmlParse(filePath);

        var nowFormatted = dateFormat(now(), 'yyyy-mm-dd');

        // Map location to its last mod date
        var locModMap = {'https://pogotracker.app/': nowFormatted, 'https://pogotracker.app/home': nowFormatted};

        // Add blogs updated
        var blogs = queryExecute(
            '
            select created, header
            from blog
            '
        );

        blogs.each((row) => {
            var loc        = '#getSetting('domain')#/readblog/#row.header.replace(' ', '-', 'all')#';
            locModMap[loc] = dateFormat(row.created, 'yyyy-mm-dd');
        });

        // Force welcome blog to be updated now
        locModMap['https://pogotracker.app/readblog/Welcome-to-POGO-Tracker!'] = nowFormatted;

        // Get last custom pokedex added
        var lastCustom = dateFormat(
            queryExecute(
                '
            select max(updated) as lastmod
            from custom
            '
            ).lastmod,
            'yyyy-mm-dd'
        );
        locModMap['https://pogotracker.app/custompokedexlist'] = lastCustom;

        // Update sitemap for each pokemon's page
        var pokemonDetails = queryExecute('
            select ses
            from pokemon
            order by generation asc, number asc, form asc, name asc
        ');

        pokemonDetails.each((row) => {
            var loc        = '#getSetting('domain')#/pokemon/#row.ses#';
            locModMap[loc] = nowFormatted;
        });

        // Update the sitemap
        // Loop through url nodes <url>
        sitemap.urlset.xmlChildren.each((urlNode) => {
            var loc = urlNode.loc.xmlText;

            // If exists in our locmodmap, update its lastmod date
            if(locModMap.keyExists(loc)) {
                urlNode.lastmod.xmlText = locModMap[loc];

                locModMap.delete(loc); // remove from map
            }
        });

        // Add new nodes for remaining keys
        locModMap.each((key, value) => {
            var newElem = xmlElemNew(sitemap, 'url');

            var locNode     = xmlElemNew(sitemap, 'loc');
            locNode.xmlText = key;

            var lastmodNode     = xmlElemNew(sitemap, 'lastmod');
            lastmodNode.xmlText = value;

            newElem.xmlChildren.append(locNode);
            newElem.xmlChildren.append(lastmodNode);

            sitemap.urlset.xmlChildren.append(newElem);
        });

        // Write back
        fileWrite(filePath, sitemap);

        event.renderData(
            type       = 'json',
            data       = {response: 'success #now()#'},
            statusCode = 200
        );
    }

}
