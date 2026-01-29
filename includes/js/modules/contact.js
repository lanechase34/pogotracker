import { $alertDiv, createAlert } from 'alert';
import { getWrapper, postWrapper } from 'fetch';
import { $submitBtn } from 'loading';

export const $contactBtn = document.getElementById('contactBtn');

export async function getContactForm() {
    return getWrapper({
        url: '/contact',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            globalModals.$contactFormModal = new bootstrap.Modal(document.getElementById('contactFormModal'), {});
            let $contactForm = document.getElementById('contactForm');
            let $submitContactForm = document.getElementById('submitContactForm');

            $submitContactForm.addEventListener('click', async (evt) => {
                let valid = $contactForm.checkValidity();
                $contactForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                document.getElementById('closeContactForm').disabled = true;

                let formData = new FormData($contactForm);
                let packet = Object.fromEntries(formData.entries());

                await submitContactForm(packet, $submitContactForm);
            });
        },
    });
}

async function submitContactForm(packet, $btn) {
    return postWrapper({
        url: '/home/contact',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: () => {
            globalModals.$contactFormModal.hide();
            createAlert($alertDiv, 'success', 'bi-check-square-fill', 'Email sent! Thanks for contacting us!');
        },
    });
}
