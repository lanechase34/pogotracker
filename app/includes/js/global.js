// Global functions that appear for every page
import { initContactButton } from 'contact';
import { $forms, addValidator } from 'form';
import { addLogoutHandler, startIdleTimer } from 'login';
import { runtime } from 'runtime';
import { getFriendRequestToast } from 'toast';

runtime();

document.querySelectorAll('[data-history-back]').forEach(($btn) => {
    $btn.addEventListener('click', () => history.back());
});

const userAuthenticated = document.getElementById('currentEvent').dataset.userauthenticated;
addValidator($forms);

if (userAuthenticated === 'true') {
    getFriendRequestToast();
    startIdleTimer();
}

initContactButton();

addLogoutHandler();
