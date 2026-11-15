import { RequestError } from 'fetch';
import { $submitBtn } from 'loading';

const $confirmModalDiv = document.getElementById('confirmModalDiv');

/**
 * Add a fetched modal fragment to #loadedModal
 * Anything that isn't the expected modal (an error or redirected page) is dropped instead of injected
 *
 * @param {string} html - the fetched fragment
 * @param {string} id - id of the modal the fragment must contain
 * @returns {HTMLElement} the modal element
 */
export function appendLoadedModal(html, id) {
    const newDiv = document.createElement('div');
    newDiv.innerHTML = html;

    const $modal = /** @type {HTMLElement | null} */ (newDiv.querySelector(`#${id}`));
    if (!$modal) {
        throw new RequestError();
    }

    document.getElementById('loadedModal').appendChild(newDiv);
    return $modal;
}

/** Ids of modals whose fragment is being fetched */
const modalsLoading = new Set();

/**
 * Show a fetched modal, fetching it first when it isn't on the page
 * Clicks while it is being fetched are ignored
 *
 * @param {string} id - id of the modal element, its instance is globalModals[`$${id}`]
 * @param {() => Promise<boolean>} load - fetches the modal and creates its instance, resolves whether it loaded
 */
export async function openLoadedModal(id, load) {
    if (modalsLoading.has(id)) return;

    if (!document.getElementById(id)) {
        modalsLoading.add(id);
        const loaded = await load();
        modalsLoading.delete(id);
        if (!loaded) return;
    }
    globalModals[`$${id}`].show();
}

export function confirmModal(message, submitText = 'Submit', handler) {
    $confirmModalDiv.innerHTML = `
        <div 
            class="modal fade" 
            id="confirmModal"
            data-bs-backdrop="static" 
            data-bs-keyboard="false" 
            tabindex="-1" 
            aria-labelledby="confirmModalLabel"
            aria-hidden="true"
        > 
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header"></div>
                    <div class="modal-body">
                        <h5 id="confirmModalLabel">${message}</h5>
                    </div>
                    <div class="modal-footer">
                        <div class="btn-group" role="group">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                            <button type="button" id="confirmModalBtn" class="btn btn-primary">
                                ${submitText}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>`;

    const $confirmModal = document.getElementById('confirmModal');
    const confirmModalInstance = new bootstrap.Modal($confirmModal, {});

    confirmModalInstance.show();

    $confirmModal.addEventListener('hidden.bs.modal', () => {
        $confirmModal.remove();
    });

    const $confirmModalBtn = /** @type {HTMLButtonElement} */ (document.getElementById('confirmModalBtn'));
    $confirmModalBtn.addEventListener('click', async () => {
        // Runs the handler once - repeat clicks while it works are ignored
        if ($confirmModalBtn.disabled) return;
        $confirmModalBtn.disabled = true;
        $confirmModalBtn.innerHTML = $submitBtn;
        await handler(true);
        confirmModalInstance.hide();
    });
}

/**
 * Shows the edit profile current password field only once the password is typed in or the email is changed
 * While hidden it is disabled, so it is neither required nor sent
 *
 * @param {HTMLFormElement} $form - the edit profile form
 */
export function toggleCurrentPassword($form) {
    const $currentPasswordDiv = $form.querySelector('#currentPasswordDiv');
    if (!$currentPasswordDiv) return;

    const $currentPassword = /** @type {HTMLInputElement} */ ($form.querySelector('#inputCurrentPassword'));
    const $password = /** @type {HTMLInputElement} */ ($form.querySelector('#inputPassword'));
    const $email = /** @type {HTMLInputElement} */ ($form.querySelector('#inputEmail'));
    const originalEmail = $email.value.trim().toLowerCase();

    const update = () => {
        const changing = $password.value.length > 0 || $email.value.trim().toLowerCase() !== originalEmail;
        $currentPasswordDiv.classList.toggle('d-none', !changing);
        $currentPassword.disabled = !changing;
        $currentPassword.required = changing;
        if (!changing) $currentPassword.value = '';
    };

    $password.addEventListener('input', update);
    $email.addEventListener('input', update);
}

function preventClose(e) {
    e.preventDefault();
}

/**
 * Disables all buttons and prevents modal from being closed on submit
 *
 * @$modal {Element} the modal element
 * @$submitter {Element} the button submitter
 */
export function submitHandler($modal, $submitter, useLoadingBtn = true) {
    // Disable all buttons
    const btns = $modal.querySelectorAll('button');
    btns.forEach(($btn) => {
        $btn.disabled = true;
    });

    if (useLoadingBtn) {
        // Update submitter to be loading button
        $submitter.innerHTML = $submitBtn;
    }

    // Prevent modal from being closed
    $modal.addEventListener('hide.bs.modal', preventClose);
}

/**
 * Enables buttons after modal has finished submitting
 *
 * @$modal {Element} the modal element
 * @$submitter {Element} the button submitter
 * @temp {String} the text of the submitter button
 */
export function resetHandler($modal, $submitter, temp) {
    // Enable all buttons
    const btns = $modal.querySelectorAll('button');
    btns.forEach(($btn) => {
        $btn.disabled = false;
    });

    if (temp) {
        // Update submitter to the original text
        $submitter.innerHTML = temp;
    }

    // Allow modal to be closed
    $modal.removeEventListener('hide.bs.modal', preventClose);
}
