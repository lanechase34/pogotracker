import { escapeHtml } from 'escape';
import { setButtonLoading } from 'loading';
import { createToast } from 'toast';

/**
 * The session's CSRF token, rendered into <meta name="csrf-token"> by layouts/header.cfm
 * Every non-GET request must send it (cbcsrf) - postWrapper adds it as the x-csrf-token header
 *
 * @returns {string}
 */
export function csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ?? '';
}

/**
 * Make sure a natively submitted POST form carries the CSRF token
 * Forms in server cached fragments can't render a per-session token themselves
 *
 * @param {HTMLFormElement} form
 */
export function addCsrfField(form) {
    if (form.method.toLowerCase() !== 'post' || form.querySelector('input[name="csrf"]')) {
        return;
    }
    appendHiddenInput(form, 'csrf', csrfToken());
}

/**
 * @param {HTMLFormElement} form
 * @param {string} name
 * @param {string} value
 */
function appendHiddenInput(form, name, value) {
    const $input = document.createElement('input');
    $input.type = 'hidden';
    $input.name = name;
    $input.value = value;
    form.appendChild($input);
}

const REQUEST_MESSAGES = {
    network: "Couldn't reach the server. Check your connection and try again.",
    403: "You don't have permission to do that.",
    404: "That couldn't be found. It may have been removed.",
    429: 'Too many requests. Please wait a moment and try again.',
    default: 'Something went wrong. Please try again.',
};

/**
 * A failed request whose message is safe to show the trainer
 * Throw one from a dataHandler to show a server provided message, e.g. throw new RequestError(data.message)
 */
export class RequestError extends Error {
    /**
     * @param {string} [message] - user facing text, falls back to the generic message
     * @param {number} [status] - HTTP status, 0 when the server wasn't reached
     */
    constructor(message, status = 0) {
        super(message || REQUEST_MESSAGES.default);
        this.name = 'RequestError';
        this.status = status;
    }
}

/**
 * Throw one from a dataHandler when the caller has already shown the failure in its own UI
 * The wrapper still restores its loading button and calls errorHandler, but shows nothing itself
 */
export class HandledError extends Error {
    constructor() {
        super('Handled');
        this.name = 'HandledError';
    }
}

/**
 * The text to show the trainer for a failed request - never the raw exception
 *
 * @param {unknown} error
 * @returns {string}
 */
export function requestErrorMessage(error) {
    return error instanceof RequestError ? error.message : REQUEST_MESSAGES.default;
}

function statusError(status) {
    return new RequestError(REQUEST_MESSAGES[status] ?? REQUEST_MESSAGES.default, status);
}

/**
 * Default failure UI when the caller has no errorHandler
 * Shown in the loading div when there is one, otherwise as a toast
 *
 * @param {unknown} error
 * @param {HTMLElement | null} [$div]
 */
function showRequestError(error, $div = null) {
    if (error instanceof HandledError) return;

    const message = escapeHtml(requestErrorMessage(error));
    if ($div) {
        $div.innerHTML = `<div class="alert alert-danger m-2" role="alert"><i class="bi bi-exclamation-triangle me-2"></i>${message}</div>`;
    } else {
        createToast(message, 'danger', 'bi-exclamation-triangle');
    }
}

/**
 * Log a failed request without the exception details
 */
function logFailure(url, error) {
    const status = error instanceof RequestError && error.status ? ` (${error.status})` : '';
    console.warn(`Request failed: ${url}${status}`);
}

/**
 * An expired session is relocated to /login, which fetch follows transparently
 */
function isLoginRedirect(response) {
    return response.status === 401 || (response.redirected && new URL(response.url).pathname.startsWith('/login'));
}

/**
 * Let the idle timer know the server session was just extended
 */
function notifyActivity() {
    document.dispatchEvent(new Event('app:request'));
}

function checkSession(response) {
    if (isLoginRedirect(response)) {
        location.href = '/login';
        throw new HandledError();
    }
    notifyActivity();
}

/**
 * Throw for any response the caller shouldn't treat as its data
 * A fragment endpoint that relocates (error page, home, access denied) would otherwise hand back a whole page with a 200
 *
 * @param {Response} response
 * @param {string} url - the requested url
 */
function checkResponse(response, url) {
    if (!response.ok) {
        throw statusError(response.status);
    }
    if (response.redirected && new URL(response.url).pathname !== new URL(url, location.href).pathname) {
        throw statusError(0);
    }
}

/**
 * fetch, with a network failure turned into a RequestError
 */
async function request(url, init) {
    try {
        return await fetch(url, init);
    } catch {
        throw new RequestError(REQUEST_MESSAGES.network);
    }
}

/**
 * @typedef {object} GetOptions
 * @property {string} url
 * @property {HTMLElement | null} [$loadingDiv] - replaced with `loading` while the request runs, and with an error message if it fails
 * @property {string} [loading]
 * @property {'json' | 'text'} [responseType] - how the body is read for dataHandler, defaults to text
 * @property {(data: any) => any} dataHandler
 * @property {(error: Error) => void} [errorHandler] - called on network/server/handler failure in place of the default error UI
 */

/**
 * @param {GetOptions} options
 * @returns {Promise<boolean>} whether the request and dataHandler succeeded
 */
export async function getWrapper({ url, $loadingDiv, loading, responseType = 'text', dataHandler, errorHandler }) {
    if ($loadingDiv) {
        $loadingDiv.innerHTML = loading;
    }

    try {
        const response = await request(url, { method: 'GET' });
        checkSession(response);
        checkResponse(response, url);
        await dataHandler(await response[responseType]());
        return true;
    } catch (error) {
        logFailure(url, error);
        if (errorHandler) {
            errorHandler(error);
        } else {
            showRequestError(error, $loadingDiv);
        }
        return false;
    }
}

/**
 * @typedef {object} PostOptions
 * @property {string} url
 * @property {HTMLButtonElement | null} [$loadingBtn] - shows `loading` and is disabled while the request runs
 * @property {string} [loading]
 * @property {boolean} [restoreOnSuccess] - also restore $loadingBtn once the response arrives (before dataHandler), not only on failure
 * @property {BodyInit} packet
 * @property {'json' | 'text'} responseType
 * @property {(data: any) => any} dataHandler
 * @property {(error: Error) => void} [errorHandler] - called on network/server/handler failure in place of the default error UI
 */

/**
 * @param {PostOptions} options
 * @returns {Promise<boolean>} whether the request and dataHandler succeeded
 */
export async function postWrapper({
    url,
    $loadingBtn,
    loading,
    restoreOnSuccess = false,
    packet,
    responseType,
    dataHandler,
    errorHandler,
}) {
    const restore = $loadingBtn ? setButtonLoading($loadingBtn, loading) : null;

    try {
        const response = await request(url, {
            method: 'POST',
            headers: {
                Accept: responseType === 'json' ? 'application/json' : 'text/html',
                'x-csrf-token': csrfToken(),
            },
            body: packet,
        });
        checkSession(response);

        let data;
        if (
            !response.ok &&
            responseType === 'json' &&
            response.headers.get('Content-Type')?.includes('application/json')
        ) {
            // Validation failures (400) still carry { success: false, message } for the caller to show
            data = await response.json().catch(() => null);
            if (data?.success !== false) throw statusError(response.status);
        } else {
            checkResponse(response, url);
            data = await response[responseType]();
        }

        if (restoreOnSuccess) restore?.();
        await dataHandler(data);
        return true;
    } catch (error) {
        restore?.();
        logFailure(url, error);
        if (errorHandler) {
            errorHandler(error);
        } else {
            showRequestError(error);
        }
        return false;
    }
}
