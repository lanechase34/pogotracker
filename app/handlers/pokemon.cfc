component extends="base" {

    this.allowedMethods = {detail: 'GET', updateDetail: 'POST'};

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

        prc.pokemonSearch = pokemonService.getSearch();

        /**
         * Attempt to load detail based on ses
         */
        prc.detail = pokemonService.getDetail(ses = rc.ses);
        if(!prc.detail.keyExists('pokemon')) {
            htmlNotFound(event = event);
            return;
        }

        prc.metaDescription = prc.detail.metaDescription;
        prc.metaKeywords    = prc.detail.metaKeywords;
        prc.title           = prc.detail.title;
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

}
