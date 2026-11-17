component extends="coldbox.system.Interceptor" {

    /**
     * End the request with a json error
     *
     * @event      request context
     * @statusCode http status to send
     * @message    message to show the user
     * @redirect   relative path the caller should navigate to instead, omitted from the response when empty
     */
    public void function renderJsonError(
        required any event,
        required numeric statusCode,
        required string message,
        string redirect = ""
    ) {
        var data = {
            success   : false,
            message   : arguments.message,
            statusCode: arguments.statusCode
        };
        if(arguments.redirect.len()) {
            data.redirect = arguments.redirect;
        }

        arguments.event
            .renderData(
                type       = "json",
                data       = data,
                statusCode = arguments.statusCode
            )
            .noExecution();
    }

}
