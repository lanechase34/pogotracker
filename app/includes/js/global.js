// Global functions that appear for every page
import { $contactBtn, getContactForm } from 'contact';
import { $forms, addValidator } from 'form';
import { $submitBtn } from 'loading';
import { addLogoutHandler, startIdleTimer } from 'login';
import { runtime } from 'runtime';
import { getFriendRequestToast } from 'toast';

runtime();

const userAuthenticated = document.getElementById('currentEvent').dataset.userauthenticated;
addValidator($forms);

if (userAuthenticated === 'true') {
    getFriendRequestToast();
}

if ($contactBtn) {
    // Load + Show the contact form when requested
    $contactBtn.addEventListener('click', async () => {
        const temp = $contactBtn.innerHTML;
        $contactBtn.disabled = true;
        $contactBtn.innerHTML = $submitBtn;
        if (!document.getElementById('contactFormModal')) {
            await getContactForm();
        }
        document.getElementById('contactFormModal').addEventListener('hidden.bs.modal', () => {
            document.querySelector('body').classList.remove('modal-open');
            document.querySelectorAll('.modal-backdrop').forEach((el) => el.remove());
        });

        globalModals.$contactFormModal.show();
        $contactBtn.innerHTML = temp;
        $contactBtn.disabled = false;
    });
}

addLogoutHandler();
startIdleTimer();
