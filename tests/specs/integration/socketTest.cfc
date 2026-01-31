component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');
    }

    function run() {
        describe('Socketbox Integration Tests', () => {
            beforeEach(() => {
                setup();
            });

            afterEach(() => {
                if(session.keyExists('mocktrainerid')) mockTrainer.delete();
            });

            it('Socket can be created', () => {
                var ws = new app.WebSocket();
                expect(ws).toBeComponent();
            });

            it('Can configure correctly and register metrics topic', () => {
                var ws     = new app.WebSocket();
                var config = ws.getConfig();
                expect(config.exchanges.topic.bindings).toHaveKey('metrics');
            });

            it('Can authenticate via session successfully', () => {
                var ws = new app.WebSocket();

                var trainer = mockTrainer.make();

                var authenticateResult = ws.authenticate(
                    login              = '',
                    passcode           = '',
                    host               = 'localhost',
                    channel            = {},
                    connectionMetadata = {}
                );
                expect(authenticateResult).toBeTrue();
            });

            it('Can fail session authentication', () => {
                var ws = new app.WebSocket();

                // Attempt with no valid session
                var authenticateResult = ws.authenticate(
                    login              = '',
                    passcode           = '',
                    host               = 'localhost',
                    channel            = {},
                    connectionMetadata = {}
                );
                expect(authenticateResult).toBeFalse();
            });

            it('Can authorize ADMIN user to metrics topic', () => {
                var ws = new app.WebSocket();

                // Admin user
                var trainer = mockTrainer.make(securityLevel = 50);

                var metadata = {};

                /**
                 * Mock the connection channel
                 */
                var channel = mockChannel();

                application.STOMPBroker.STOMPConnections[channel.hashCode()] = {
                    channel           : channel,
                    login             : '',
                    connectDate       : now(),
                    sessionID         : channel.hashCode(),
                    connectionMetadata: {}
                }

                var authenticateResult = ws.authenticate(
                    login              = '',
                    passcode           = '',
                    host               = 'localhost',
                    channel            = {},
                    connectionMetadata = {}
                );
                expect(authenticateResult).toBeTrue();

                var authorizeResult = ws.authorize(
                    login              = '',
                    exchange           = 'topic',
                    destination        = 'metrics',
                    access             = 'subscribe',
                    channel            = channel,
                    connectionMetadata = application.STOMPBroker.STOMPConnections[channel.hashCode()].connectionMetadata
                );
                expect(authorizeResult).toBeTrue();
            });

            it('Can fail authorization with non ADMIN user to metrics topic', () => {
                var ws = new app.WebSocket();

                var trainer = mockTrainer.make(securityLevel = 10);

                var metadata = {};

                /**
                 * Mock the connection channel
                 */
                var channel = mockChannel();

                application.STOMPBroker.STOMPConnections[channel.hashCode()] = {
                    channel           : channel,
                    login             : '',
                    connectDate       : now(),
                    sessionID         : channel.hashCode(),
                    connectionMetadata: {}
                }

                /**
                 * Can authenticate, but the authorization will fail (insufficient permission)
                 */
                var authenticateResult = ws.authenticate(
                    login              = '',
                    passcode           = '',
                    host               = 'localhost',
                    channel            = {},
                    connectionMetadata = {}
                );
                expect(authenticateResult).toBeTrue();

                var authorizeResult = ws.authorize(
                    login              = '',
                    exchange           = 'topic',
                    destination        = 'metrics',
                    access             = 'subscribe',
                    channel            = channel,
                    connectionMetadata = application.STOMPBroker.STOMPConnections[channel.hashCode()].connectionMetadata
                );
                expect(authorizeResult).toBeFalse();
            });

            it('Can broadcast a message to metrics', () => {
                var ws = new app.WebSocket();

                expect(() => {
                    ws.send('topic/metrics', {time: now()});
                }).notToThrow();
            });
        });
    }

    /**
     * Mock session id for websocket channel
     */
    private struct function mockChannel() {
        return {hashCode: () => 'mockChannelHash123', isOpen: () => true};
    }

}
