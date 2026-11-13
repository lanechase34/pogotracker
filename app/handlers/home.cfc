component extends="base" {

    this.allowedMethods = {
        index      : "GET",
        home       : "GET,POST",
        contactForm: "GET",
        contact    : "POST"
    };

    property name="blogService"  inject="services.blog";
    property name="emailService" inject="services.email";

    /**
     * /home - permanently redirect to / so search engines only see one home page url
     */
    function index(event, rc, prc) {
        relocate(uri = "/", statusCode = 301);
    }

    /**
     * Home Page
     */
    function home(event, rc, prc) {
        prc.suppressH1 = true; // hero title is the h1

        // First blog batch renders with the page
        prc.blogCount = 6;
        prc.blogs     = blogService.get(count = prc.blogCount, offset = 0);
    }

    /**
     * Contact Form Modal
     */
    function contactForm(event, rc, prc) secured="user" {
        event.setView(view = "/views/modal/contactform", nolayout = true);
    }

    /**
     * Submit contact form and send an email
     *
     * @rc.subject subject
     * @rc.message message
     */
    function contact(event, rc, prc) secured="user" {
        if(hasValidationErrors(target = rc, constraints = "home.contactForm")) {
            jsonValidationFailure(event = event, message = "Unable to submit contact form at this time");
            return;
        }

        emailService.sendContact(
            email     = prc.oCurrentUser.getEmail(),
            subject   = rc.subject,
            message   = rc.message,
            trainerid = prc.oCurrentUser.getId()
        );
        jsonOk(event = event);
    }

}
