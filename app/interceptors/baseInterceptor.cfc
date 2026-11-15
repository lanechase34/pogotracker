component extends="coldbox.system.Interceptor" {

    /**
     * End the request with a json error
     *
     * @event      request context
     * @statusCode http status to send
     * @message    message to show the user
     */
    public void function renderJsonError(
        required any event,
        required numeric statusCode,
        required string message
    ) {
        arguments.event
            .renderData(
                type = "json",
                data = {
                    success   : false,
                    message   : arguments.message,
                    statusCode: arguments.statusCode
                },
                statusCode = arguments.statusCode
            )
            .noExecution();
    }

}
