import { Client } from '@stomp/stompjs';

let metricClient = null;

const env = document.getElementById('currentEvent').dataset.environment.toLowerCase();
const port = document.getElementById('currentEvent').dataset.port;

/**
 * Connects websocket for metrics endpoint
 */
export function startMetricsSocket() {
    if (metricClient?.active) return;

    const BROKER_URL = env == 'production' ? 'wss://pogotracker.app/ws' : `ws://127.0.0.1:${port}/ws`;

    metricClient = new Client({
        brokerURL: BROKER_URL,
        reconnectDelay: 5000, // reconnect after 5 seconds
        heartbeatIncoming: 10000,
        heartbeatOutgoing: 10000,
        connectHeaders: {},
        onConnect: () => {
            metricClient.subscribe('metrics', (message) => {
                try {
                    const json = JSON.parse(message.body);
                    if (!(json?.success ?? false)) {
                        return;
                    }

                    // Fire custom event
                    const event = new CustomEvent('metricsUpdate', { detail: json.data });
                    document.dispatchEvent(event);
                } catch (err) {
                    console.error('Failed to process metric message', err);
                }
            });
        },
        onStompError: (frame) => {
            console.error('Broker error', frame.headers['message'], frame.body);
        },
    });

    metricClient.activate();
}

export function stopMetricsSocket() {
    if (!metricClient) return;

    metricClient.deactivate();
    metricClient = null;
}
