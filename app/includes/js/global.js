// Global functions that appear for every page
import { $contactBtn, getContactForm } from 'contact';
import { $forms, addValidator } from 'form';
import { getFriendRequestToast } from 'toast';
import { addLogoutHandler, startIdleTimer } from 'login';
import { runtime } from 'runtime';

runtime();

const userAuthenticated = document.getElementById('currentEvent').dataset.userauthenticated;
addValidator($forms);

if (userAuthenticated == 'true') {
    getFriendRequestToast();
}

if ($contactBtn) {
    $contactBtn.addEventListener('click', async () => {
        if (!document.getElementById('contactFormModal')) {
            await getContactForm();
        }
        document.getElementById('contactFormModal').addEventListener('hidden.bs.modal', () => {
            document.getElementById('contactFormModal').remove();
            document.querySelector('body').classList.remove('modal-open');
            document.querySelectorAll('.modal-backdrop').forEach((el) => el.remove());
        });

        globalModals.$contactFormModal.show();
    });
}

addLogoutHandler();
startIdleTimer();
