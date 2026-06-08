component extends="base" {

    this.allowedMethods = {
        detail           : 'GET',
        updateDetail     : 'POST',
        search           : 'GET',
        getPreviousEvents: 'GET'
    };

    property name="pokemonService" inject="services.pokemon";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.metaDescription = 'View a detailed breakdown of all a Pokemon''s Information';
    }

    /**
     * Pokemon's detail view
     *
     * @rc.ses SES url that is a unique key for a pokemon
     */
    function detail(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'pokemon.detail')) {
            htmlValidationFailure(event = event, redirectEvent = 'home');
            return;
        }

        /**
         * Attempt to load detail based on ses
         */
        prc.detail = pokemonService.getDetail(ses = rc.ses);
        if(!prc.detail.keyExists('pokemon')) {
            event.setLayout('basic');
            htmlNotFound(event = event);
            return;
        }

        prc.metaDescription = prc.detail.metaDescription;
        prc.title           = '#prc.detail.title# | #getSetting('title')#';
        prc.suppressH1      = true; // pokemon's name is h1
    }

    /**
     * Update a pokemon's detail
     *
     * @rc.pokemonid         pokemon pk
     * @rc.liveSwitch        (optional) on/off switch
     * @rc.shinySwitch       (optional) on/off switch
     * @rc.shadowSwitch      (optional) on/off switch
     * @rc.shinyShadowSwitch (optional) on/off switch
     * @rc.tradableSwitch    (optional) on/off switch
     */
    function updateDetail(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'pokemon.updateDetail')) {
            htmlValidationFailure(event = event, redirectEvent = 'home');
            return;
        }

        prc.pokemon = pokemonService.getFromId(rc.pokemonid);

        pokemonService.updateDetail(
            pokemon     = prc.pokemon,
            live        = (rc?.liveSwitch ?: 'off') == 'on',
            shiny       = (rc?.shinySwitch ?: 'off') == 'on',
            shadow      = (rc?.shadowSwitch ?: 'off') == 'on',
            shinyShadow = (rc?.shinyShadowSwitch ?: 'off') == 'on',
            tradable    = (rc?.tradableSwitch ?: 'off') == 'on'
        );

        relocate(uri = '/pokemon/#prc.pokemon.getSes()#');
    }

    /**
     * Load more previous events for a pokemon's detail page
     *
     * @rc.ses    pokemon SES key
     * @rc.offset number of events already shown
     */
    function getPreviousEvents(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'pokemon.getPreviousEvents')) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.detail = pokemonService.getDetail(ses = rc.ses);
        if(!prc.detail.keyExists('pokemon')) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.events = pokemonService.getPreviousEvents(
            pokemon = prc.detail.pokemon,
            limit   = 5,
            offset  = rc.offset
        );

        event.setView(
            view     = '/views/pokemon/fragment/eventrows',
            nolayout = true,
            args     = {
                events: prc.events,
                ses   : rc.ses,
                offset: rc.offset + 5,
                limit : 5
            }
        );
    }

    /**
     * Paginated search of pokemon filtered against the cached search array
     *
     * @rc.search (optional) search term
     * @rc.page   numeric page number
     */
    function search(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'pokemon.search')) {
            jsonValidationFailure(event = event, message = 'Invalid Pokemon Search');
            return;
        }

        prc.responseObj.data = pokemonService.searchPokemon(search = rc?.search ?: '', page = rc.page);

        jsonOk(event = event, data = prc.responseObj.data);
    }

}
