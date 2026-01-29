component extends="base" {

    this.allowedMethods = {tradePlanForm: 'GET', tradePlan: 'POST'}

    property name="customService"     inject="services.custom";
    property name="friendService"     inject="services.friend";
    property name="generationService" inject="services.generation";
    property name="tradeService"      inject="services.trade";
    property name="trainerService"    inject="services.trainer";

    this.prehandler_only = 'tradePlanForm';

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = 'Trade - #getSetting('title')#';
        prc.metaDescription = 'Compare your Pokedex with a friend''s and find Pokemon to trade.';
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
        rc.region   = rc?.region ?: '';
        rc.customid = rc?.customid ?: -1;
        rc.shiny    = rc?.shiny ?: 'off';

        prc.responseObj.type = 'danger';
        prc.responseObj.data = '';

        // Validation and make sure trainer is friends with target
        prc.validation = validate(target = rc, constraints = 'trade.tradePlan');
        if(
            prc.validation.hasErrors() ||
            (rc.region.len() && rc.customid > 0)
        ) {
            prc.responseObj.message = 'Invalid Trade Plan.';
        }

        if(!prc.responseObj.message.len()) {
            prc.shiny   = rc.shiny == 'on' ? true : false;
            prc.trainer = trainerService.getFromId(session.trainerid);
            prc.friend  = trainerService.getFromId(parseNumber(rc.friend));

            prc.trainerOnlyArgs = {
                leftTrainer : prc.trainer,
                rightTrainer: prc.friend,
                shiny       : prc.shiny
            };

            prc.friendOnlyArgs = {
                leftTrainer : prc.friend,
                rightTrainer: prc.trainer,
                shiny       : prc.shiny
            };

            if(rc.region.len()) {
                prc.generation                 = generationService.getFromRegion(rc.region);
                prc.trainerOnlyArgs.generation = prc.generation;
                prc.friendOnlyArgs.generation  = prc.generation;
            }
            else {
                // Check trainer access to custom pokedex
                prc.custom = customService.get(parseNumber(rc.customid), prc.trainer)
                if(!prc.custom.len()) {
                    prc.responseObj.message = 'Invalid Trade Plan.';
                }
                else {
                    prc.trainerOnlyArgs.custom = prc.custom[1];
                    prc.friendOnlyArgs.custom  = prc.custom[1];
                }
            }
        }

        // If still valid, generate the trade plan
        if(!prc.responseObj.message.len()) {
            prc.tradePlan = {
                'trainerOnly': tradeService.findExclusive(argumentCollection = prc.trainerOnlyArgs),
                'friendOnly' : tradeService.findExclusive(argumentCollection = prc.friendOnlyArgs)
            };

            // Check if trade plan has pokemon
            if(!prc.tradePlan.trainerOnly.len() && !prc.tradePlan.friendOnly.len()) {
                prc.responseObj.message = 'No Pokemon Eligible For Trade Plan.';
                prc.responseObj.type    = 'warning';
            }
            else {
                prc.header           = '#prc.shiny ? 'Shiny - ' : ''##rc.region.len() ? rc.region : encodeForHTML(prc.custom[1].getName())# Trade Plan';
                prc.loop             = prc.tradePlan.trainerOnly.len() > prc.tradePlan.friendOnly.len() ? prc.tradePlan.trainerOnly.len() : prc.tradePlan.friendOnly.len();
                prc.responseObj.data = view(
                    view = '/views/trade/tradeplan',
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

        event.renderData(
            type       = 'json',
            data       = prc.responseObj,
            statusCode = prc.responseObj.statusCode
        );
    }

}
