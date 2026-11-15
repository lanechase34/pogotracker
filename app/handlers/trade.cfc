component extends="base" secured="user" {

    this.allowedMethods = {tradePlanForm: "GET", tradePlan: "POST"}

    property name="async"             inject="asyncManager@coldbox";
    property name="customService"     inject="services.custom";
    property name="generationService" inject="services.generation";
    property name="tradeService"      inject="services.trade";

    this.prehandler_only = "tradePlanForm";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = "Trade | #getSetting("title")#";
        prc.metaDescription = "Compare your Pokedex with a friend's and find Pokemon to trade.";
        prc.metaRobots      = "noindex, nofollow";
    }

    /**
     * Main view for the trade plan
     */
    function tradePlanForm(event, rc, prc) {
        prc.generations = generationService.getAll();
    }

    /**
     * Get the trade plan. Pokemon that your friend has registered that you don't and vice versa
     * Returns JSON
     *
     * Region or customid must be defined
     *
     * @rc.friend   friend trainer pk
     * @rc.region   (optional) region name (ie kanto, johto, etc.)
     * @rc.customid (optional) custom pk
     * @rc.shiny    (optional) on/off
     */
    function tradePlan(event, rc, prc) {
        rc.region   = rc?.region ?: "";
        rc.customid = len(rc?.customid ?: "") ? rc.customid : -1;
        rc.shiny    = rc?.shiny ?: "off";

        prc.responseObj.type = "danger";
        prc.responseObj.data = "";

        // Validation - friends with target, exactly one of region or customid, and a custom pokedex you can see
        prc.validation = validate(target = rc, constraints = "trade.tradePlan");
        if(prc.validation.hasErrors()) {
            prc.responseObj.message    = "Invalid Trade Plan.";
            prc.responseObj.statusCode = 400;
        }

        if(!prc.responseObj.message.len()) {
            prc.shiny     = rc.shiny == "on" ? true : false;
            prc.trainerid = prc.oCurrentUser.getId();
            prc.friendid  = parseNumber(rc.friend);

            prc.trainerOnlyArgs = {
                leftTrainerid : prc.trainerid,
                rightTrainerid: prc.friendid,
                shiny         : prc.shiny
            };

            prc.friendOnlyArgs = {
                leftTrainerid : prc.friendid,
                rightTrainerid: prc.trainerid,
                shiny         : prc.shiny
            };

            if(rc.region.len()) {
                prc.generation                 = generationService.getFromRegion(region = rc.region);
                prc.trainerOnlyArgs.generation = prc.generation;
                prc.friendOnlyArgs.generation  = prc.generation;
            }
            else {
                prc.custom                 = customService.getFromId(id = parseNumber(rc.customid));
                prc.trainerOnlyArgs.custom = prc.custom;
                prc.friendOnlyArgs.custom  = prc.custom;
            }
        }

        // If still valid, generate the trade plan
        if(!prc.responseObj.message.len()) {
            var results = async
                .all(
                    () => tradeService.findExclusive(argumentCollection = prc.trainerOnlyArgs),
                    () => tradeService.findExclusive(argumentCollection = prc.friendOnlyArgs)
                )
                .get();

            prc.tradePlan = {trainerOnly: results[1], friendOnly: results[2]};

            // Check if trade plan has pokemon
            if(!prc.tradePlan.trainerOnly.len() && !prc.tradePlan.friendOnly.len()) {
                // A valid request with nothing to trade - not an error
                prc.responseObj.message    = "No Pokemon Eligible For Trade Plan.";
                prc.responseObj.type       = "warning";
                prc.responseObj.statusCode = 200;
            }
            else {
                prc.header           = "#prc.shiny ? "Shiny - " : ""##rc.region.len() ? rc.region : encodeForHTML(prc.custom.name)# Trade Plan";
                prc.loop             = prc.tradePlan.trainerOnly.len() > prc.tradePlan.friendOnly.len() ? prc.tradePlan.trainerOnly.len() : prc.tradePlan.friendOnly.len();
                prc.responseObj.data = view(
                    view = "/views/trade/tradePlan",
                    args = {
                        header   : prc.header,
                        loop     : prc.loop,
                        tradePlan: prc.tradePlan,
                        shiny    : prc.shiny
                    }
                );
            }

            prc.responseObj.success    = true;
            prc.responseObj.statusCode = 200;
        }

        renderJson(event = event, response = prc.responseObj);
    }

}
