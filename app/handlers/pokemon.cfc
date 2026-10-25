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
         * Attempt to load the cached detail info based on ses
         * The page body is a cached viewlet (detailContent) so a warm cache never touches the DB
         */
        prc.detailInfo = pokemonService.getDetailInfo(ses = rc.ses);
        if(prc.detailInfo.isEmpty()) {
            event.setLayout('basic');
            htmlNotFound(event = event);
            return;
        }

        prc.detailContentCache = {
            suffix: pokemonService.getDetailContentCacheSuffix(
                ses     = rc.ses,
                isAdmin = (session?.securityLevel ?: -10) >= 50
            ),
            timeout: pokemonService.getCacheTime() * 15
        };

        prc.metaDescription = prc.detailInfo.metaDescription;
        prc.title           = '#prc.detailInfo.title# | #getSetting('title')#';
        prc.suppressH1      = true; // pokemon's name is h1
    }

    /**
     * Viewlet rendering the body of a pokemon's detail page, cached in the template cache by views/pokemon/detail
     *
     * @ses SES url that is a unique key for a pokemon
     */
    private function detailContent(event, rc, prc, required string ses) {
        prc.detail = pokemonService.getDetail(ses = arguments.ses);
        return view(view = '/views/pokemon/fragment/detailcontent', nolayout = true);
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

        prc.pokemon = pokemonService.getFromSes(ses = rc.ses);
        if(isNull(prc.pokemon)) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.events = pokemonService.getPreviousEvents(
            pokemon = prc.pokemon,
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
