component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");

        personas = {
            admin          : mockTrainer.make(securityLevel = 50, autoLogin = false),
            user           : mockTrainer.make(securityLevel = 10, autoLogin = false),
            // Unverified trainers have no permissions, whatever their level
            unverifiedAdmin: mockTrainer.make(
                securityLevel = 50,
                verified      = false,
                autoLogin     = false
            )
        };
    }

    function afterAll() {
        application.STOMPBroker.STOMPConnections.delete(mockChannel().hashCode());
        personas.each((name, trainer) => mockTrainer.deleteTrainer(trainer.id));
        super.afterAll();
    }

    function run() {
        describe("Socketbox Integration Tests", () => {
            beforeEach(() => {
                setup();
            });

            afterEach(() => {
                mockTrainer.actAsGuest();
            });

            it("Can configure correctly and register metrics topic", () => {
                var ws     = new WebSocket();
                var config = ws.getConfig();
                expect(config.exchanges.topic.bindings).toHaveKey("metrics");
            });

            it("Can authenticate via session successfully", () => {
                mockTrainer.actAs(personas.user);
                expect(authenticateSession(getWebSocket())).toBeTrue();
            });

            it("Can fail session authentication", () => {
                // Attempt with no valid session
                expect(authenticateSession(getWebSocket())).toBeFalse();
            });

            it("Can authorize ADMIN user to metrics topic", () => {
                var ws = getWebSocket();
                mockTrainer.actAs(personas.admin);

                expect(authenticateSession(ws)).toBeTrue();
                expect(authorizeMetrics(ws, registerConnection())).toBeTrue();
            });

            it("Can fail authorization with non ADMIN user to metrics topic", () => {
                var ws = getWebSocket();
                mockTrainer.actAs(personas.user);

                // Can authenticate, but the authorization will fail (insufficient permission)
                expect(authenticateSession(ws)).toBeTrue();
                expect(authorizeMetrics(ws, registerConnection())).toBeFalse();
            });

            it("Cannot authorize a guest to metrics topic", () => {
                expect(authorizeMetrics(getWebSocket(), registerConnection())).toBeFalse();
            });

            it("Cannot authorize an unverified admin to metrics topic", () => {
                var ws = getWebSocket();
                mockTrainer.actAs(personas.unverifiedAdmin);

                expect(authorizeMetrics(ws, registerConnection())).toBeFalse();
            });

            it("Rejects an unknown destination", () => {
                var ws = getWebSocket();
                mockTrainer.actAs(personas.admin);

                expect(
                    ws.authorize(
                        login              = "",
                        exchange           = "topic",
                        destination        = "not-a-topic",
                        access             = "subscribe",
                        channel            = mockChannel(),
                        connectionMetadata = {}
                    )
                ).toBeFalse();
            });

            it("Can broadcast a message to metrics", () => {
                var ws = getWebSocket();

                expect(() => {
                    ws.send("topic/metrics", {time: now()});
                }).notToThrow();
            });
        });
    }

    /**
     * Mock session id for websocket channel
     */
    private struct function mockChannel() {
        return {hashCode: () => "mockChannelHash123", isOpen: () => true};
    }

    /**
     * Register the mock channel as an open STOMP connection (afterAll removes it)
     */
    private struct function registerConnection() {
        var channel = mockChannel();

        application.STOMPBroker.STOMPConnections[channel.hashCode()] = {
            channel           : channel,
            login             : "",
            connectDate       : now(),
            sessionID         : channel.hashCode(),
            connectionMetadata: {}
        };
        return channel;
    }

    /**
     * Authenticate a connection from the current session
     */
    private boolean function authenticateSession(required component ws) {
        return arguments.ws.authenticate(
            login              = "",
            passcode           = "",
            host               = "localhost",
            channel            = {},
            connectionMetadata = {}
        );
    }

    /**
     * Subscribe the channel to the metrics topic
     */
    private boolean function authorizeMetrics(required component ws, required struct channel) {
        return arguments.ws.authorize(
            login              = "",
            exchange           = "topic",
            destination        = "metrics",
            access             = "subscribe",
            channel            = arguments.channel,
            connectionMetadata = application.STOMPBroker.STOMPConnections[arguments.channel.hashCode()].connectionMetadata
        );
    }

    /**
     * Wrapper to instantiate new websocket component and run the initial configure
     */
    private component function getWebSocket() {
        var ws = new WebSocket();
        ws.initDeps();
        ws.getConfig();
        return ws;
    }

}
