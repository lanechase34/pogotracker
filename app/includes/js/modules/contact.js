import { getWrapper, postWrapper } from 'fetch';
import { $submitBtn } from 'loading';
import { createToast } from 'toast';

export const $contactBtn = document.getElementById('contactBtn');

export async function getContactForm() {
    return await getWrapper({
        url: '/contact',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            globalModals.$contactFormModal = new bootstrap.Modal(document.getElementById('contactFormModal'), {});
            const $contactForm = document.getElementById('contactForm');
            const $submitContactForm = document.getElementById('submitContactForm');

            $submitContactForm.addEventListener('click', async (evt) => {
                const valid = $contactForm.checkValidity();
                $contactForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                document.getElementById('closeContactForm').disabled = true;

                const formData = new FormData($contactForm);
                const packet = Object.fromEntries(formData.entries());

                await submitContactForm(packet, $submitContactForm);
            });
        },
    });
}

async function submitContactForm(packet, $btn) {
    return await postWrapper({
        url: '/home/contact',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: () => {
            globalModals.$contactFormModal.hide();
            createToast('Email sent! Thanks for contacting us!', 'success', 'bi-check-square-fill');
        },
    });
}
