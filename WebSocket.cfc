component extends="modules.socketbox.models.WebSocketSTOMP" {

    /**
	 * Socket destination -> Allowed security level
	 */
    this.validSockets = {'metrics': 50};

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
        required Struct connectionMetadata
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
        required Struct connectionMetadata
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
            return false;
        }

        try {
            var securityLevel = session?.securityLevel ?: 0;
            return securityLevel >= this.validSockets[destination];
        }
        catch(any e) {
        }

        return false;
    }

}
