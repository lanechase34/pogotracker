component extends="modules.socketbox.models.WebSocketSTOMP" hint="WebSocket Endpoint for SocketBox" {

    /**
	 * Socket destination -> required permission
	 */
    this.validSockets = {"metrics": "admin"};

    // Initialize dependencies and store in app scope
    function initDeps() {
        application.wsLog     = application.wirebox.getInstance("logbox:logger:WebSocket");
        application.wsAuth    = application.wirebox.getInstance("authenticationService@cbauth");
        application.wsSession = application.wirebox.getInstance("services.session");
    }

    function configure() {
        return {
            debugMode    : false,
            heartBeatMS  : 10000,
            exchanges    : {topic: {bindings: {metrics: "metrics"}}},
            subscriptions: {}
        };
    };

    /**
	 * Authenticate the incoming websocket connection using the current session
	 */
    boolean function authenticate(
        required string login,
        required string passcode,
        string host,
        required channel,
        required struct connectionMetadata
    ) {
        /**
         * Verify this session is authenticated
         */
        try {
            return application.wsAuth.isLoggedIn();
        }
        catch(any e) {
            application.wsLog.error("WebSocket authentication failed unexpectedly: #e.message#", e.stackTrace);
        }

        return false;
    }

    /**
	 * Authorize the incoming websocket connection using the current session
	 */
    boolean function authorize(
        required string login,
        required string exchange,
        required string destination,
        required string access,
        required channel,
        required struct connectionMetadata
    ) {
        /**
         * Check this is a valid destination
         */
        if(!this.validSockets.keyExists(destination)) {
            return false;
        }

        /**
		 * We want the sessionID for this connection, so we'll get the details about this channel's connection
		 */
        var connectionDetails = getConnectionDetails(channel);
        var sessionID         = connectionDetails["sessionID"] ?: "";

        if(!sessionID.len()) {
            application.wsLog.warn("WebSocket authorization failed - no sessionID for destination: #arguments.destination#");
            return false;
        }

        try {
            /**
             * Check the permissions associated with this trainer
             */
            if(!application.wsAuth.isLoggedIn()) {
                application.wsLog.warn("WebSocket authorization failed - not logged in for destination: #arguments.destination#");
                return false;
            }

            var trainer = application.wsAuth.getUser();

            // A session signed out by a password change can't subscribe either
            if(!application.wsSession.isCurrentVersion(trainer)) {
                application.wsLog.warn("WebSocket authorization failed - stale session version for trainer: ""#trainer.getId()#""");
                return false;
            }

            var permission = this.validSockets[destination];
            var hasAccess  = trainer.hasPermission(permission);

            if(!hasAccess) {
                application.wsLog.warn(
                    "WebSocket authorization failed - insufficient permission for destination ""#arguments.destination#"". " &
                    "Required: ""#permission#"", trainer: ""#trainer.getId()#"""
                );
            }

            return hasAccess;
        }
        catch(any e) {
            application.wsLog.error(
                "WebSocket authorization failed unexpectedly for destination ""#arguments.destination#"": #e.message#",
                e.stackTrace
            );
        }

        return false;
    }

}
