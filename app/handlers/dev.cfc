component extends="base" secured="developer" {

    this.allowedMethods = {
        index                 : "GET",
        createRandomBlogs     : "GET",
        forceError            : "GET",
        sendTestEmail         : "GET",
        viewEmail             : "GET",
        testEventTask         : "GET",
        createUnownJson       : "GET",
        createCPMultiplierJSON: "GET",
        testJsoup             : "GET",
        downloadImage         : "POST",
        debugInfo             : "GET"
    };

    property name="adminService"   inject="services.admin";
    property name="emailService"   inject="services.email";
    property name="scraperService" inject="services.scraper";

    function preHandler(event, rc, prc, action, eventArguments) {
        // These functions only available in develop
        if(getSetting("environment") == "production") {
            relocate(uri = "/");
        }
    }

    function index(event, rc, prc) {
    }

    function createRandomBlogs(event, rc, prc) {
        prc.create    = rc?.create ?: 3;
        prc.trainerid = prc.oCurrentUser.getId();
        for(var i = 1; i <= prc.create; i++) {
            var theText = "Placeholder text. ";
            var body    = theText;
            var repeats = randRange(10, 50);
            for(var j = 1; j <= repeats; j++) {
                body &= theText;
            }

            queryExecute(
                "INSERT INTO blog (header, body, trainerid) VALUES (:header, :body, :trainerid)",
                {
                    header   : {value: createUUID().replace("-", "_", "all"), cfsqltype: "varchar"},
                    body     : {value: body, cfsqltype: "varchar"},
                    trainerid: {value: prc.trainerid, cfsqltype: "integer"}
                }
            );
        }

        renderJson(event = event, response = {"response": "success #now()#"});
    }


    function forceError(event, rc, prc) {
        // this will not work
        var chase = 1 / 0;
    }

    function sendTestEmail(event, rc, prc) {
        emailService.sendTestEmail();
        renderJson(event = event, response = {"response": "success #now()#"});
    }

    function viewEmail(event, rc, prc) {
        param name="rc.filename" default="";

        prc.testEmails = directoryList(
            path    : "#getSetting("testEmailPath")#",
            recurse : false,
            listInfo: "query",
            sort    : "DateLastModified desc"
        );

        prc.mailContent = "";
        if(rc.filename.len()) {
            var safeFilename = reReplace(rc.filename, "[^a-zA-Z0-9._-]", "", "all");
            var fullPath     = "#getSetting("testEmailPath")#/#safeFilename#.html";
            if(fileExists(fullPath)) {
                prc.mailContent = fileRead(fullPath, "UTF-8");
            }
        }


        prc.header = "View Test Emails";
    }

    function testEventTask(event, rc, prc) {
        adminService.createEvents();
        renderJson(event = event, response = {"response": "success #now()#"});
    }

    function createUnownJson(event, rc, prc) {
        var unowns = [];
        for(var i = 0; i < 26; i++) {
            unowns.append(chr(65 + i)); // makes array of alphabet letters
        }

        // Special Cases
        unowns.append("!");
        unowns.append("?");

        var result = {};
        var base   = {
            "live"       : true,
            "Flee"       : 10,
            "Catch"      : 30,
            "shadowshiny": false,
            "giga"       : false,
            "number"     : 201,
            "evolutions" : [],
            "form"       : false,
            "mega"       : false,
            "Attack"     : 136,
            "HP"         : 134,
            "shadow"     : false,
            "shiny"      : true,
            "gender"     : "",
            "Name"       : "",
            "tradable"   : true,
            "Type"       : ["Psychic"],
            "sprite"     : "",
            "generation" : 2.5,
            "moves"      : ["HIDDEN_POWER", "STRUGGLE"],
            "Defense"    : 91,
            "formtype"   : ""
        };

        unowns.each((letter) => {
            var curr      = duplicate(base);
            curr.name     = "Unown #letter#";
            curr.sprite   = letter == "!" ? "201-exclamation" : letter == "?" ? "201-question" : "201-#lCase(letter)#";
            curr.formtype = letter == "!" ? "exclamation" : letter == "?" ? "question" : "#lCase(letter)#";
            result.insert(curr.name, curr);
        });

        renderJson(event = event, response = {"response": serializeJSON(result)});
    }

    function createCPMultiplierJSON(event, rc, prc) {
        var cpDoc       = scraperService.getData(targetURL = "https://pokemongo.fandom.com/wiki/Combat_Power");
        var cpTableData = cpDoc
            .body()
            .select("##Level_Scalar")
            .select("tbody")
            .select("tr");
        var multiplierJson = {};

        cpTableData.each((tr, trindex) => {
            if(trindex == 1) return; // first row is 'header'

            var currLevel = -1;
            var rowData   = tr.select("td");

            rowData.each((td, tdindex) => {
                // odd index is the level
                // even index is the multiplier
                if(tdindex % 2 == 1) {
                    currLevel = parseNumber(reReplace(td.text(), "[^0-9.]", ""));
                }
                else {
                    multiplierJson.insert(currLevel, parseNumber(td.text()));
                }
            });
        });

        renderJson(event = event, response = {"response": serializeJSON(multiplierJson)});
    }

    function testJsoup(event, rc, prc) {
        prc.userAgent = scraperService
            .getData(targetURL = "https://httpbin.io/user-agent")
            .body()
            .text();
        renderJson(event = event, response = {"response": prc.userAgent});
    }

    function downloadImage(event, rc, prc) {
        param name="rc.imageUrl" default="";

        if(!rc.imageUrl.len() || !rc.imageUrl.startsWith("http")) {
            flash.put(
                name  = "alert",
                value = {
                    "type"       : "danger",
                    "dismissible": true,
                    "icon"       : "bi bi-exclamation-triangle",
                    "message"    : "Please provide a valid image URL."
                }
            );
            relocate(event = "dev");
            return;
        }

        var destination = "/includes/#createUUID()##getSetting("imageExtension")#";
        scraperService.downloadImage(targetURL = rc.imageUrl, destination = destination);

        flash.put(
            name  = "alert",
            value = {
                "type"       : "success",
                "dismissible": true,
                "icon"       : "bi bi-image-fill",
                "message"    : "Image saved to #destination#"
            }
        );
        relocate(event = "dev");
    }

    function debugInfo(event, rc, prc) {
    }

}
