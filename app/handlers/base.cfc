component extends="coldbox.system.EventHandler" {

    property name="auditService" inject="services.audit";

    /**
     * Allow HEAD wherever GET is allowed so crawlers, link checkers, and uptime monitors don't get a 405
     * Runs after the child handler's pseudo-constructor has set this.allowedMethods
     */
    public any function init() {
        super.init();

        for(var action in this.allowedMethods) {
            var methods = this.allowedMethods[action];
            if(listFindNoCase(methods, "GET") && !listFindNoCase(methods, "HEAD")) {
                this.allowedMethods[action] = listAppend(methods, "HEAD");
            }
        }

        return this;
    }

    /**
     * The request's audit object (prc.auditInfo) - the current trainer, the referer and the event
     */
    public void function setRequestAuditInfo(required struct rc, required struct prc) {
        prc.auditInfo = auditService.getAuditObj(
            trainerid = (prc?.oCurrentUser?.getId() ?: -1),
            referer   = rc?.referer ?: "",
            event     = rc?.event ?: "NA"
        );
    }

    /**
     * Generic JSON render
     */
    public void function renderJson(required any event, required struct response) {
        event.renderData(
            type       = "json",
            data       = response,
            statusCode = response?.statusCode ?: 200
        );
    }

    /**
     * JSON validation failure (400)
     */
    public void function jsonValidationFailure(required any event, string message = "Invalid request") {
        renderJson(
            event    = event,
            response = {
                success   : false,
                message   : message,
                statusCode: 400
            }
        );
    }

    /**
     * JSON not found failure (404)
     */
    public void function jsonNotFound(required any event, string message = "Resource not found") {
        renderJson(
            event    = event,
            response = {
                success   : false,
                message   : message,
                statusCode: 404
            }
        );
    }

    /**
     * JSON success helper (200)
     */
    public void function jsonOk(required any event, any data = {}) {
        renderJson(
            event    = event,
            response = {
                success   : true,
                statusCode: 200,
                data      : data
            }
        );
    }

    /**
     * HTML validation failure
     * Redirects or shows blank fragment depending on use case
     * The blank fragment is for fetched fragments - it carries an error status so the caller reports the failure
     */
    public void function htmlValidationFailure(
        required any event,
        string redirectEvent = "",
        string redirectUri   = "",
        string view          = "/views/fragment/blank",
        numeric statusCode   = 400
    ) {
        if(len(redirectEvent)) {
            relocate(event = redirectEvent);
        }
        else if(len(redirectUri)) {
            relocate(uri = redirectUri);
        }
        else {
            event.setHTTPHeader(statusCode = statusCode);
            event.setView(view = view, nolayout = true);
        }
    }

    /**
     * HTML not found (404)
     */
    public void function htmlNotFound(required any event, string view = "/views/fragment/404") {
        event.setHTTPHeader(statusCode = 404);
        event.setView(view = view);
    }

    /**
     * Runs validation and returns true if errors exist
     */
    public boolean function hasValidationErrors(required any target, required string constraints) {
        var validation = validate(target = target, constraints = constraints);
        return validation.hasErrors();
    }

    /**
     * Safe deserializeJSON wrapper
     */
    public any function safeDeserializeJSON(required string json, any fallback = "") {
        try {
            return deserializeJSON(json);
        }
        catch(any e) {
            return fallback;
        }
    }

}
