import { $forms, addValidator } from 'form';

const $logoutBtn = document.getElementById('logoutBtn');

function idleLogout() {
    window.location = '/logout/idle/true';
}

function refreshPage() {
    window.location.reload();
}

export function addLogoutHandler() {
    // Listen for when a tab logs out
    window.addEventListener('storage', function (event) {
        if (event.key == 'logout-event') {
            window.location = '/logout';
        }
    });

    if ($logoutBtn) {
        $logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.setItem('logout-event', 'logout' + Math.random());
            window.location = '/logout';
        });
    }
}

export function startIdleTimer() {
    // Force logout the user if idle before session timeout
    let sessionTimeout = document.getElementById('currentEvent').dataset.idletimeout - 1;
    setTimeout(idleLogout, sessionTimeout * 60 * 1000);
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
        const $resendForm = document.getElementById('resendVerificationForm');
        document.getElementById('submitResend').addEventListener('click', () => {
            $resendForm.submit();
        });
    },
};
