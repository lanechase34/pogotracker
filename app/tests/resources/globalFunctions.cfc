component extends="coldbox.system.testing.BaseTestCase" {

    property name="pokemonService" inject="services.pokemon";
    property name="testData"       inject="tests.resources.testData";

    public numeric function countTestEmails() {
        return listTestEmails().len();
    }

    /**
     * File names of every test email sent - diff two listings to find the emails a request sent
     */
    public array function listTestEmails() {
        return directoryList(
            path     = application.cbController.getSetting("testEmailPath"),
            recurse  = false,
            listInfo = "name",
            type     = "file"
        );
    }

    public numeric function countBugLog() {
        return testData.countRows("bug");
    }

    public any function readEmail(string email = "") {
        if(arguments.email.len()) {
            var fileContent = fileRead("#application.cbController.getSetting("testEmailPath")#/#arguments.email#");
        }
        // Default to read the most recent email sent
        else {
            var emails = directoryList(
                path    : "#application.cbController.getSetting("testEmailPath")#",
                recurse : false,
                listInfo: "query",
                sort    : "DateLastModified desc"
            );

            var fileContent = fileRead("#application.cbController.getSetting("testEmailPath")#/#emails.name[1]#");
        }

        // Email starts at DOCTYPE HTML. Select only this portion
        var mailBody = right(fileContent, fileContent.len() - fileContent.find("<!DOCTYPE html>") + 1);

        var jsoup = getInstance("javaloader:org.jsoup.Jsoup");
        return jsoup.parse(mailBody);
    }

    /**
     * Store a reCAPTCHA result in the session, as /verifyrecaptcha would, for the next gated form post
     *
     * @action     form action the result is for, eg doLogin
     * @valid      whether google passed the check
     * @secondsAgo how old the result is (results over 30 seconds old are rejected)
     */
    public void function storeRecaptcha(
        required string action,
        boolean valid      = true,
        numeric secondsAgo = 0
    ) {
        session.recaptcha = {
            token    : "token",
            valid    : arguments.valid,
            timestamp: dateAdd("s", -arguments.secondsAgo, now()),
            action   : arguments.action
        };
    }

    /**
     * The id of a pokemon with no gender - its costume of this type when costumetype is given
     *
     * @number      pokedex number
     * @name        pokemon name
     * @costumetype costume type, eg Party Hat - blank for the normal pokemon
     */
    public numeric function pokemonId(
        required numeric number,
        required string name,
        string costumetype = ""
    ) {
        var filter = {
            number : arguments.number,
            name   : arguments.name,
            gender : "",
            costume: arguments.costumetype.len() > 0
        };
        if(arguments.costumetype.len()) {
            filter.costumetype = arguments.costumetype;
        }
        return pokemonService.findPokemon(filter)[1].id;
    }

    /**
     * Register the pokemon as caught for the logged in trainer, through the pokedex endpoint
     *
     * @pokemonid pokemon pk
     * @shiny     also register the shiny
     */
    public void function registerCaught(required numeric pokemonid, required boolean shiny) {
        setup();
        var event = post(
            route  = "/pokedex/register",
            params = {
                pokemonid  : arguments.pokemonid,
                caught     : true,
                shiny      : arguments.shiny,
                hundo      : false,
                shadow     : false,
                shadowshiny: false
            }
        );
        expect(event.getStatusCode()).toBe(200);
    }

    /**
     * The markup of one pokemon's entry in a rendered pokedex grid
     *
     * @html      rendered grid
     * @pokemonid pokemon pk
     */
    public string function entryBlock(required string html, required numeric pokemonid) {
        return mid(
            arguments.html,
            find("data-id=""#arguments.pokemonid#""", arguments.html),
            300
        );
    }

    /**
     * The @type of every node in a parsed JSON-LD @graph, in order
     */
    public array function getGraphTypes(required struct jsonLd) {
        return arguments.jsonLd["@graph"].map((node) => node["@type"]);
    }

    /**
     * The one node of this @type in a parsed JSON-LD @graph, failing when there isn't exactly one
     */
    public struct function getGraphNode(required struct jsonLd, required string type) {
        var nodes = arguments.jsonLd["@graph"].filter((node) => node["@type"] == type);
        expect(nodes).toHaveLength(1, "Expected exactly one #arguments.type# node");
        return nodes[1];
    }

}
