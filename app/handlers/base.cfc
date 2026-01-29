component extends="coldbox.system.EventHandler" {

    /**
     * Generic JSON render
     */
    function renderJson(required any event, required struct response) {
        event.renderData(
            type       = 'json',
            data       = response,
            statusCode = response?.statusCode ?: 200
        );
    }

    /**
     * JSON validation failure (400)
     */
    function jsonValidationFailure(required any event, string message = 'Invalid request') {
        renderJson(
            event,
            {
                success   : false,
                message   : message,
                statusCode: 400
            }
        );
    }

    /**
     * JSON not found failure (404)
     */
    function jsonNotFound(required any event, string message = 'Resource not found') {
        renderJson(
            event,
            {
                success   : false,
                message   : message,
                statusCode: 404
            }
        );
    }

    /**
     * JSON success helper (200)
     */
    function jsonOk(required any event, any data = {}) {
        renderJson(
            event,
            {
                success   : true,
                statusCode: 200,
                data      : data
            }
        );
    }

    /**
     * HTML validation failure
     * Redirects or shows blank fragment depending on use case
     */
    function htmlValidationFailure(
        required any event,
        string redirectEvent = '',
        string redirectUri   = '',
        string view          = '/views/fragment/blank'
    ) {
        if(len(redirectEvent)) {
            relocate(event = redirectEvent);
        }
        else {
            event.setView(view = view, nolayout = true);
        }
    }

    /**
     * HTML not found (404)
     */
    function htmlNotFound(required any event, string view = '/views/fragment/404') {
        event.setHTTPHeader(statusCode = 404);
        event.setView(view = view);
    }

    /**
     * Runs validation and returns true if errors exist
     */
    boolean function hasValidationErrors(required any target, required string constraints) {
        var validation = validate(target = target, constraints = constraints);
        return validation.hasErrors();
    }

    /**
     * Safe deserializeJSON wrapper
     */
    function safeDeserializeJSON(required string json, any fallback = '') {
        try {
            return deserializeJSON(json);
        }
        catch(any e) {
            return fallback;
        }
    }

}
