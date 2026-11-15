import { getWrapper, postWrapper, RequestError } from 'fetch';
import { validatedPacket } from 'form';
import { $submitBtn } from 'loading';
import { appendLoadedModal } from 'modals';
import { createToast } from 'toast';

const $contactBtn = /** @type {HTMLButtonElement} */ (document.getElementById('contactBtn'));

/**
 * Load + show the contact form when the footer Contact button is clicked
 * The footer renders in both layouts, so both call this - the button is only there for logged in trainers
 */
export function initContactButton() {
    if (!$contactBtn) return;

    $contactBtn.addEventListener('click', async () => {
        const temp = $contactBtn.innerHTML;
        $contactBtn.disabled = true;
        $contactBtn.innerHTML = $submitBtn;
        // The form is loaded once and reused - its listeners are added once with it
        if (!document.getElementById('contactFormModal')) {
            await getContactForm();
            document.getElementById('contactFormModal')?.addEventListener('hidden.bs.modal', () => {
                document.querySelector('body').classList.remove('modal-open');
                document.querySelectorAll('.modal-backdrop').forEach((el) => el.remove());
            });
        }

        $contactBtn.innerHTML = temp;
        $contactBtn.disabled = false;
        globalModals.$contactFormModal?.show();
    });
}

async function getContactForm() {
    return await getWrapper({
        url: '/contact',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const $contactFormModal = appendLoadedModal(data, 'contactFormModal');
            globalModals.$contactFormModal = new bootstrap.Modal($contactFormModal, {});
            const $contactForm = /** @type {HTMLFormElement} */ (document.getElementById('contactForm'));
            const $submitContactForm = /** @type {HTMLButtonElement} */ (document.getElementById('submitContactForm'));
            const $closeContactForm = /** @type {HTMLButtonElement} */ (document.getElementById('closeContactForm'));

            // A closed form starts fresh next time it opens
            $contactFormModal.addEventListener('hidden.bs.modal', () => {
                $contactForm.reset();
                $contactForm.classList.remove('was-validated');
            });

            let sending = false;
            $submitContactForm.addEventListener('click', async (evt) => {
                // One send at a time - double clicks don't send the message twice
                if (sending) return;

                const packet = validatedPacket($contactForm, evt);
                if (!packet) return;

                sending = true;
                $closeContactForm.disabled = true;

                const label = $submitContactForm.innerHTML;
                const sent = await submitContactForm(packet, $submitContactForm);

                // postWrapper only restores the button on failure - put it back either way
                $submitContactForm.innerHTML = label;
                $submitContactForm.disabled = false;
                $closeContactForm.disabled = false;
                sending = false;

                if (sent) {
                    globalModals.$contactFormModal.hide();
                }
            });
        },
    });
}

/**
 * Send the contact form
 * A failed send (rate limited, invalid, or the email didn't go out) shows the server's message as a toast
 *
 * @returns {Promise<boolean>} whether the email was sent
 */
async function submitContactForm(packet, $btn) {
    return await postWrapper({
        url: '/home/contact',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data?.success) {
                throw new RequestError(data?.message);
            }
            createToast('Email sent! Thanks for contacting us!', 'success', 'bi-check-square-fill');
        },
    });
}
