component extends="base" {

    this.allowedMethods = {
        index      : 'GET',
        home       : 'GET,POST',
        contactForm: 'GET',
        contact    : 'POST'
    };

    property name="emailService"   inject="services.email";
    property name="pokemonService" inject="services.pokemon";

    function index(event, rc, prc) {
        relocate(uri = '/');
    }

    /**
     * Home Page
     */
    function home(event, rc, prc) {
        prc.pokemonSearch = pokemonService.getSearch();
    }

    /**
     * Contact Form Modal
     */
    function contactForm(event, rc, prc) {
        event.setView(view = '/views/modal/contactform', nolayout = true);
    }

    /**
     * Submit contact form and send an email
     *
     * @rc.subject subject
     * @rc.message message
     */
    function contact(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'home.contactForm')) {
            jsonValidationFailure(event = event, message = 'Unable to submit contact form at this time');
            return;
        }

        emailService.sendContact(
            email   = session.email,
            subject = rc.subject,
            message = rc.message
        );
        jsonOk(event = event);
    }

}
