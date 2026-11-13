import { Client } from '@stomp/stompjs';

let metricClient = null;

// Reconnects back off from 5s up to a minute while the server is unreachable, reset once connected
const RECONNECT_DELAY = 5000;
const MAX_RECONNECT_DELAY = 60000;

const env = document.getElementById('currentEvent').dataset.environment.toLowerCase();
const baseURL = document.getElementById('baseURL')?.dataset?.baseurl ?? '';
const port = document.getElementById('currentEvent').dataset.port;

/**
 * Connects websocket for metrics endpoint
 */
export function startMetricsSocket() {
    if (metricClient?.active) return;

    // Reuse the client after stopMetricsSocket - onConnect subscribes again
    if (metricClient) {
        metricClient.reconnectDelay = RECONNECT_DELAY;
        metricClient.activate();
        return;
    }

    const BROKER_URL = env === 'production' ? 'wss://pogotracker.app/ws' : `ws://${baseURL}:${port}/ws`;

    metricClient = new Client({
        brokerURL: BROKER_URL,
        reconnectDelay: RECONNECT_DELAY,
        heartbeatIncoming: 10000,
        heartbeatOutgoing: 10000,
        connectHeaders: {},
        onConnect: () => {
            metricClient.reconnectDelay = RECONNECT_DELAY;
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
        // Runs before the client schedules its reconnect, so the next attempt waits longer
        onWebSocketClose: () => {
            metricClient.reconnectDelay = Math.min(metricClient.reconnectDelay * 2, MAX_RECONNECT_DELAY);
        },
    });

    metricClient.activate();
}

/**
 * Disconnects the metrics websocket and stops reconnecting (hidden tab) - startMetricsSocket resumes it
 */
export function stopMetricsSocket() {
    metricClient?.deactivate();
}
