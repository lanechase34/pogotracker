component extends="base" secured="user" {

    this.allowedMethods = {
        register               : "POST",
        registerAll            : "POST",
        myPokedex              : "GET",
        getPokedex             : "GET",
        myCustomPokedex        : "GET",
        getCustomPokedex       : "GET",
        customPokedexList      : "GET",
        addCustomPokedexForm   : "GET",
        editCustomPokedexForm  : "GET",
        addCustomPokedex       : "POST",
        editCustomPokedex      : "POST",
        deleteCustomPokedex    : "POST",
        searchCustomPokedexList: "GET",
        myCostumePokedex       : "GET",
        myShadowPokedex        : "GET"
    };

    property name="customService"     inject="services.custom";
    property name="generationService" inject="services.generation";
    property name="pokedexService"    inject="services.pokedex";
    property name="pokemonService"    inject="services.pokemon";
    property name="trainerService"    inject="services.trainer";

    this.prehandler_only = "myPokedex,myCustomPokedex,customPokedexList,myShadowPokedex";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = "Pokedex | #getSetting("title")#";
        prc.metaDescription = "Track your Pokemon and Shiny Pokemon collection in the Pokedex.";
        prc.metaRobots      = "noindex, nofollow";
    }

    /**
     * Registers/updates a pokemon to the trainer's pokedex
     *
     * @rc.pokemonid   the pokemon pk
     * @rc.caught      t/f
     * @rc.shiny       t/f
     * @rc.hundo       t/f
     * @rc.shadow      t/f
     * @rc.shadowshiny t/f
     */
    function register(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.register")) {
            jsonValidationFailure(event = event, message = "Invalid Register");
            return;
        }

        // Passed input validation, go ahead and register this pokemon
        prc.pokemon = pokemonService.getFromId(parseNumber(rc.pokemonid));
        pokedexService.register(
            prc.oCurrentUser,
            prc.pokemon,
            rc.caught,
            rc.shiny,
            rc.hundo,
            rc.shadow,
            rc.shadowshiny
        );
        jsonOk(event = event);
    }

    /**
     * Register ALL pokemon in the supplied region for a trainer
     * Can register normal caught OR shiny
     *
     * @rc.region region name (ie kanto, johto, etc.)
     * @rc.shiny  t/f if registering all shiny
     */
    function registerAll(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.registerAll")) {
            jsonValidationFailure(event = event, message = "Invalid RegisterAll");
            return;
        }

        pokedexService.registerAll(
            trainer = prc.oCurrentUser,
            region  = rc.region,
            shiny   = rc.shiny
        );
        jsonOk(event = event);
    }

    /**
     * Main pokedex view. Lists out regions user can select to view that specific pokedex
     *
     * @rc.region active region, defaults to session defaultRegion
     * @rc.shiny  t/f, defaults to session defaultView type
     */
    function myPokedex(event, rc, prc) {
        rc.region = rc?.region ?: prc.oCurrentUser.getSettings().defaultRegion;
        rc.shiny  = rc?.shiny ?: prc.oCurrentUser.getSettings().defaultView == "shiny";

        if(hasValidationErrors(target = rc, constraints = "pokedex.myPokedex")) {
            htmlValidationFailure(event = event, redirectEvent = "home");
            return;
        }

        prc.generations      = generationService.getAll();
        prc.trainerid        = prc.oCurrentUser.getId();
        // First grid is rendered with the page, JS only fetches on region/shiny switches
        prc.pokedexTableArgs = buildPokedexTableArgs(
            trainer = trainerService.getFromId(trainerid = prc.trainerid),
            region  = rc.region,
            shiny   = rc.shiny
        );
    }

    /**
     * Get all pokemon registered for the trainer using the supplied criteria
     * Returns JSON
     *
     * @rc.region    (optional) region name (ie kanto, johto, etc.)
     * @rc.form      (optional) t/f
     * @rc.shiny     (optional) t/f defaults to trainer's view
     * @rc.hundo     (optional) t/f
     * @rc.shadow    (optional) t/f
     * @rc.trainerid (optional) defaults to current session
     */
    function getPokedex(event, rc, prc) {
        rc.region    = rc?.region ?: "";
        rc.form      = rc?.form ?: false;
        rc.shiny     = rc?.shiny ?: prc.oCurrentUser.getSettings().defaultView == "shiny";
        rc.hundo     = rc?.hundo ?: false;
        rc.shadow    = rc?.shadow ?: false;
        rc.costume   = rc?.costume ?: false;
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        if(hasValidationErrors(target = rc, constraints = "pokedex.getPokedex")) {
            event.setLayout("basic");
            htmlNotFound(event = event);
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.trainer   = trainerService.getFromId(trainerid = prc.trainerid);

        event.setView(
            view     = "/views/pokedex/pokedextable",
            nolayout = true,
            args     = buildPokedexTableArgs(
                trainer = prc.trainer,
                region  = rc.region,
                form    = rc.form,
                shiny   = rc.shiny,
                hundo   = rc.hundo,
                shadow  = rc.shadow,
                costume = rc.costume
            )
        );
    }

    /**
     * Build the args for /views/pokedex/pokedextable
     * Shared by getPokedex (region/view switches) and the pokedex pages, which render the first grid server side
     */
    private struct function buildPokedexTableArgs(
        required component trainer,
        string region   = "",
        boolean form    = false,
        boolean shiny   = false,
        boolean hundo   = false,
        boolean shadow  = false,
        boolean costume = false
    ) {
        var currRegion = arguments.region;
        var currShiny  = arguments.shiny;

        // Handle mega/giga classification
        var mega = false;
        var giga = false;
        if(currRegion == "Mega") {
            mega       = true;
            currRegion = "";
            currShiny  = false;
        }
        else if(currRegion == "Giga") {
            giga       = true;
            currRegion = "";
            currShiny  = false;
        }

        // Shadow and costume pokedex are not split up by region
        if(arguments.shadow || arguments.costume) {
            currRegion = "";
        }

        var pokedexView =
        arguments.costume && currShiny ? "costumeshiny"
         : arguments.costume ? "costume"
         : arguments.shadow && currShiny ? "shadowshiny"
         : arguments.shadow ? "shadow"
         : currShiny ? "shiny"
         : arguments.hundo ? "hundo"
         : "caught";

        return {
            pokedex: pokedexService.getRegistered(
                trainer = arguments.trainer,
                region  = currRegion,
                form    = arguments.form,
                mega    = mega,
                shadow  = arguments.shadow,
                giga    = giga,
                costume = arguments.costume
            ),
            pokedexView: pokedexView,
            shiny      : currShiny,
            hundo      : arguments.hundo,
            shadow     : arguments.shadow
        };
    }

    /**
     * Custom pokedex view
     *
     * @rc.trainerid (optional) defaults to current session
     * @rc.customid  custom pk
     * @rc.shiny     t/f, defaults to session defaultView type
     */
    function myCustomPokedex(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();
        rc.shiny     = rc?.shiny ?: prc.oCurrentUser.getSettings().defaultView == "shiny";

        if(hasValidationErrors(target = rc, constraints = "pokedex.myCustomPokedex")) {
            htmlValidationFailure(event = event, redirectEvent = "pokedex.customPokedexList");
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.customid  = parseNumber(rc.customid);
        prc.trainer   = trainerService.getFromId(trainerid = prc.trainerid);
        prc.custom    = customService.get(id = prc.customid, trainer = prc.trainer);

        // Check trainer access to custom pokedex
        if(!prc.custom.len()) {
            htmlValidationFailure(event = event, redirectEvent = "pokedex.customPokedexList");
            return;
        }

        prc.custom = prc.custom[1];
        prc.name   = prc.custom.getName();

        prc.header = "#encodeForHTML(prc.name)#";

        // First grid renders with the page
        prc.pokedexTableArgs = buildCustomPokedexTableArgs(
            trainer = prc.trainer,
            custom  = prc.custom,
            shiny   = rc.shiny,
            hundo   = false
        );
    }

    /**
     * Get all pokemon registered for the trainer IN the custom pokedex using the supplied criteria
     * Returns JSON
     *
     * @rc.customid  custom pk
     * @rc.shiny     t/f
     * @rc.hundo     t/f
     * @rc.trainerid (optional) defaults to current session
     */
    function getCustomPokedex(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();
        if(hasValidationErrors(target = rc, constraints = "pokedex.getCustomPokedex")) {
            htmlValidationFailure(event = event, redirectEvent = "pokedex.customPokedexList");
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.customid  = parseNumber(rc.customid);
        prc.trainer   = trainerService.getFromId(trainerid = prc.trainerid);
        prc.custom    = customService.get(id = prc.customid, trainer = prc.trainer);

        // Check trainer access to custom pokedex
        if(!prc.custom.len()) {
            htmlValidationFailure(event = event, redirectEvent = "pokedex.customPokedexList");
            return;
        }

        prc.custom = prc.custom[1];
        prc.name   = prc.custom.getName();

        event.setView(
            view     = "/views/pokedex/pokedextable",
            nolayout = true,
            args     = buildCustomPokedexTableArgs(
                trainer = prc.trainer,
                custom  = prc.custom,
                shiny   = rc.shiny,
                hundo   = rc.hundo
            )
        );
    }

    /**
     * Build the args for /views/pokedex/pokedextable from a custom pokedex
     * Shared by myCustomPokedex (first render) and getCustomPokedex (shiny toggle)
     */
    private struct function buildCustomPokedexTableArgs(
        required component trainer,
        required component custom,
        boolean shiny = false,
        boolean hundo = false
    ) {
        return {
            pokedex    : pokedexService.getCustomRegistered(trainer = arguments.trainer, custom = arguments.custom),
            pokedexView: arguments.shiny ? "shiny" : arguments.hundo ? "hundo" : "caught",
            shiny      : arguments.shiny,
            hundo      : arguments.hundo,
            shadow     : false
        };
    }

    /**
     * Lists out paginated (scroll) custom pokedexes available to the current session's trainer
     *
     * @rc.offset (optional) offset for query
     */
    function customPokedexList(event, rc, prc) {
        rc.offset = rc?.offset ?: 0;
        if(hasValidationErrors(target = rc, constraints = "pokedex.customPokedexList")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.count  = 10;
        prc.offset = parseNumber(rc.offset);

        prc.trainer         = prc.oCurrentUser;
        prc.customPokedexes = customService.getMine(
            trainer = prc.trainer,
            offset  = prc.offset,
            count   = prc.count
        );

        event.setView(
            view     = "/views/pokedex/custompokedexlist",
            nolayout = prc.offset > 0,
            args     = {
                trainer        : prc.trainer,
                customPokedexes: prc.customPokedexes,
                nextOffset     : prc.offset + prc.count,
                offset         : prc.offset
            }
        )
    }

    /**
     * Add a custom pokedex form view
     */
    function addCustomPokedexForm(event, rc, prc) {
        prc.pokemon = pokemonService.getAll();
        prc.header  = "Add Custom Pokedex";
        event.setView(
            view     = "/views/pokedex/modal/custompokedexform",
            nolayout = true,
            args     = {
                edit   : false,
                pokemon: prc.pokemon,
                header : prc.header
            }
        );
    }

    /**
     * Edit a custom pokedex form view
     * Custom pokedex must have been created by the current trainer
     *
     * @rc.customid custom pk
     */
    function editCustomPokedexForm(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.editCustomPokedexForm")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.custom        = customService.get(parseNumber(rc.customid), prc.oCurrentUser)[1];
        prc.pokemon       = pokemonService.getAll();
        prc.customPokedex = customService.getCustomPokedexIds(prc.custom.getId());
        prc.header        = "Editing #encodeForHTML(prc.custom.getName())#";
        event.setView(
            view     = "/views/pokedex/modal/custompokedexform",
            nolayout = true,
            args     = {
                edit         : true,
                pokemon      : prc.pokemon,
                header       : prc.header,
                custom       : prc.custom,
                custompokedex: prc.customPokedex
            }
        );
    }

    /**
     * Endpoint to add a new custom pokedex
     *
     * @rc.name    custom pokedex name
     * @rc.public  t/f if public access
     * @rc.pokemon [] of pokemon objects
     */
    function addCustomPokedex(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.addCustomPokedex")) {
            jsonValidationFailure(event = event, message = "Invalid Custom Pokedex");
            return;
        }

        // Passed input validation
        prc.name    = ucFirst(rc.name);
        prc.public  = booleanFormat(rc.public);
        prc.pokemon = rc.pokemon;

        // Create the custom entry
        var customid = customService.create(
            trainer = prc.oCurrentUser,
            name    = prc.name,
            public  = prc.public
        );
        var custom = customService.getFromId(id = customid);

        // Create the custom pokedex
        customService.createCustomPokedex(custom = custom, pokemon = prc.pokemon);

        jsonOk(event = event, data = {id: customid});
    }

    /**
     * Endpoint to edit an existing custom pokedex
     *
     * @rc.customid custom pk, must have been created by current trainer
     * @rc.name     custom pokedex name
     * @rc.public   t/f if public access
     * @rc.pokemon  [] of pokemon objects
     */
    function editCustomPokedex(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.editCustomPokedex")) {
            jsonValidationFailure(event = event, message = "Invalid Custom Pokedex");
            return;
        }

        // Passed input validation
        prc.name     = ucFirst(rc.name);
        prc.public   = booleanFormat(rc.public);
        prc.pokemon  = rc.pokemon;
        prc.customid = parseNumber(rc.customid);

        // Update the custom entry
        customService.update(
            customid = prc.customid,
            name     = prc.name,
            public   = prc.public
        );
        var custom = customService.getFromId(id = prc.customid);

        // Update the custom pokedex
        customService.createCustomPokedex(custom = custom, pokemon = prc.pokemon);

        jsonOk(event = event, data = {id: prc.customid});
    }

    /**
     * Shadow pokedex view
     *
     * @rc.shiny t/f, defaults to session defaultView type
     */
    function myShadowPokedex(event, rc, prc) {
        rc.shiny = rc?.shiny ?: prc.oCurrentUser.getSettings().defaultView == "shiny";

        if(hasValidationErrors(target = rc, constraints = "pokedex.myShadowPokedex")) {
            htmlValidationFailure(event = event, redirectEvent = "home");
            return;
        }

        prc.trainerid        = prc.oCurrentUser.getId();
        prc.pokedexTableArgs = buildPokedexTableArgs(
            trainer = trainerService.getFromId(trainerid = prc.trainerid),
            shiny   = rc.shiny,
            shadow  = true
        );
        prc.title           = "Shadow Pokedex | #getSetting("title")#";
        prc.metaDescription = "Track your Shadow Pokemon and Shiny Shadow Pokemon collection in the Pokedex.";
    }

    /**
     * Costume pokedex view
     *
     * @rc.shiny t/f, defaults to session defaultView type
     */
    function myCostumePokedex(event, rc, prc) {
        rc.shiny = rc?.shiny ?: prc.oCurrentUser.getSettings().defaultView == "shiny";

        if(hasValidationErrors(target = rc, constraints = "pokedex.myCostumePokedex")) {
            htmlValidationFailure(event = event, redirectEvent = "home");
            return;
        }

        prc.trainerid        = prc.oCurrentUser.getId();
        prc.pokedexTableArgs = buildPokedexTableArgs(
            trainer = trainerService.getFromId(trainerid = prc.trainerid),
            shiny   = rc.shiny,
            costume = true
        );
        prc.title           = "Costume Pokedex | #getSetting("title")#";
        prc.metaDescription = "Track your Costume Pokemon and Shiny Costume Pokemon collection in the Pokedex.";
    }

    /**
     * Endpoint to delete a custom pokedex
     *
     * @rc.customid custom pk, must have been created by current trainer
     */
    function deleteCustomPokedex(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.deleteCustomPokedex")) {
            jsonValidationFailure(event = event, message = "Invalid Delete");
            return;
        }

        // Passed input validation
        customService.delete(custom = customService.getFromId(id = parseNumber(rc.customid)));
        jsonOk(event = event);
    }

    /**
     * Paginated search custom pokedex
     *
     * @rc.search (optional) search term
     * @rc.page   numeric page number
     */
    function searchCustomPokedexList(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "pokedex.searchCustom")) {
            jsonValidationFailure(event = event, message = "Invalid Custom Search");
            return;
        }

        // Passed input validation
        prc.responseObj.data = customService.searchMyCustom(
            trainer = prc.oCurrentUser,
            search  = rc?.search ?: "",
            page    = rc.page
        );
        jsonOk(event = event, data = prc.responseObj.data);
    }

}
