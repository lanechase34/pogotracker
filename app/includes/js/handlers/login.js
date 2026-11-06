import { $forms, addValidator } from 'form';

const $logoutBtn = document.getElementById('logoutBtn');

function idleLogout() {
    window.location.href = '/logout/idle/true';
}

function refreshPage() {
    window.location.reload();
}

export function addLogoutHandler() {
    // Listen for when a tab logs out
    window.addEventListener('storage', (event) => {
        if (event.key === 'logout-event') {
            window.location.href = '/logout';
        }
    });

    if ($logoutBtn) {
        $logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.setItem('logout-event', `logout${Math.random()}`);
            window.location.href = '/logout';
        });
    }
}

/**
 * Idle = no request has reached the server (from any tab) for the session timeout
 * The last request time is shared across tabs via localStorage so an idle tab
 * doesn't log out a trainer who is active in another tab
 */
const LAST_REQUEST_KEY = 'last-request';
let idleTimer = null;
let idleTimeoutMs = 0;
let lastRequestFallback = Date.now();

function getLastRequest() {
    try {
        return Number(localStorage.getItem(LAST_REQUEST_KEY)) || lastRequestFallback;
    } catch {
        return lastRequestFallback;
    }
}

function scheduleIdleCheck() {
    clearTimeout(idleTimer);
    const remaining = getLastRequest() + idleTimeoutMs - Date.now();
    idleTimer = setTimeout(
        () => {
            if (Date.now() - getLastRequest() >= idleTimeoutMs) {
                idleLogout();
            } else {
                scheduleIdleCheck();
            }
        },
        Math.max(remaining, 0)
    );
}

function recordRequest() {
    lastRequestFallback = Date.now();
    try {
        localStorage.setItem(LAST_REQUEST_KEY, String(lastRequestFallback));
    } catch {
        // Storage unavailable - fall back to this tab's own activity
    }
    scheduleIdleCheck();
}

export function startIdleTimer() {
    // Force logout the user a minute before the server session would time out
    const sessionTimeout = Number(document.getElementById('currentEvent').dataset.idletimeout) - 1;
    idleTimeoutMs = Math.max(sessionTimeout, 1) * 60 * 1000;

    // This page load reached the server, as does every fetch/ajax request after it
    recordRequest();
    document.addEventListener('app:request', recordRequest);
    window.jQuery?.(document).ajaxComplete(recordRequest);
}

function startCsrfTimer() {
    setTimeout(refreshPage, 600000); // Reload page if 10 minutes of inactivity
}

export const runtime = {
    all: () => {
        addValidator($forms);
        startCsrfTimer();
    },
    verifyform: () => {
        const $resendForm = /** @type {HTMLFormElement} */ (document.getElementById('resendVerificationForm'));
        document.getElementById('submitResend').addEventListener('click', () => {
            $resendForm.submit();
        });
    },
};
