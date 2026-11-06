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
        throw new Error('Session expired');
    }
    notifyActivity();
}

/**
 * @typedef {object} GetOptions
 * @property {string} url
 * @property {HTMLElement | null} [$loadingDiv] - replaced with `loading` while the request runs
 * @property {string} [loading]
 * @property {(data: string) => any} dataHandler
 * @property {(error: Error) => void} [errorHandler] - called on network/server/handler failure
 */

/**
 * @param {GetOptions} options
 */
export async function getWrapper({ url, $loadingDiv, loading, dataHandler, errorHandler }) {
    if ($loadingDiv) {
        $loadingDiv.innerHTML = loading;
    }

    await fetch(url, {
        method: 'GET',
    })
        .then((response) => {
            checkSession(response);
            if (!response.ok) {
                throw new Error(`Server error ${response.status}`);
            }
            return response.text();
        })
        .then(dataHandler)
        .catch((error) => {
            console.error('Fetch error:', error);
            errorHandler?.(error);
        });

    return true;
}

/**
 * @typedef {object} PostOptions
 * @property {string} url
 * @property {HTMLButtonElement | null} [$loadingBtn] - shows `loading` and is disabled while the request runs
 * @property {string} [loading]
 * @property {BodyInit} packet
 * @property {'json' | 'text'} responseType
 * @property {(data: any) => any} dataHandler
 * @property {(error: Error) => void} [errorHandler] - called on network/server/handler failure
 */

/**
 * @param {PostOptions} options
 */
export async function postWrapper({ url, $loadingBtn, loading, packet, responseType, dataHandler, errorHandler }) {
    let temp;
    if ($loadingBtn) {
        temp = $loadingBtn.innerHTML;
        $loadingBtn.innerHTML = loading;
        $loadingBtn.disabled = true;
    }

    await fetch(url, {
        method: 'POST',
        headers: {
            Accept: responseType === 'json' ? 'application/json' : 'text/html',
        },
        body: packet,
    })
        .then(async (response) => {
            checkSession(response);
            if (!response.ok) {
                // Validation failures (400) still carry { success: false, message } for the caller to show
                if (responseType === 'json' && response.headers.get('Content-Type')?.includes('application/json')) {
                    const data = await response.json();
                    if (data?.success === false) return data;
                }
                throw new Error(`Server error ${response.status}`);
            }
            return response[responseType]();
        })
        .then(dataHandler)
        .catch((error) => {
            if ($loadingBtn) {
                $loadingBtn.innerHTML = temp;
                $loadingBtn.disabled = false;
            }
            console.error('Fetch error:', error);
            errorHandler?.(error);
        });
}
