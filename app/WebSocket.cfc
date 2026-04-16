component extends="modules.socketbox.models.WebSocketSTOMP" hint="WebSocket Endpoint for SocketBox" {

    /**
	 * Socket destination -> Allowed security level
	 */
    this.validSockets = {'metrics': 50};

    // Initialize dependencies and store in app scope
    function initDeps() {
        application.wsLog = application.wirebox.getInstance('logbox:logger:WebSocket');
    }

    function configure() {
        return {
            debugMode  : false,
            heartBeatMS: 10000,
            exchanges  : {
                // Topic exchange routes messages based on a pattern match to their incoming destination
                topic: {bindings: {metrics: 'metrics'}}
            },
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
            var authenticated = session?.authenticated ?: false;
            var trainerid     = session?.trainerid ?: -1;

            return authenticated && trainerid > 0;
        }
        catch(any e) {
            application.wsLog.error('WebSocket authentication failed unexpectedly: #e.message#', e.stackTrace);
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
		 * We want the sessionID for this connection, so we'll get the details about this channel's connectio
		 */
        var connectionDetails = getConnectionDetails(channel);
        var sessionID         = connectionDetails['sessionID'] ?: '';

        if(!sessionID.len()) {
            application.wsLog.warn('WebSocket authorization failed - no sessionID for destination: #arguments.destination#');
            return false;
        }

        try {
            var securityLevel = session?.securityLevel ?: 0;
            return securityLevel >= this.validSockets[destination];
        }
        catch(any e) {
            application.wsLog.error(
                'WebSocket authorization failed unexpectedly for destination "#arguments.destination#": #e.message#',
                e.stackTrace
            );
        }

        return false;
    }

}
