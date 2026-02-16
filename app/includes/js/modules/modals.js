import { $submitBtn } from 'loading';

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
                        <h5>${message}</h5>
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

    let $confirmModal = document.getElementById('confirmModal');
    let confirmModal = new bootstrap.Modal($confirmModal, {});
    confirmModal.show();

    $confirmModal.addEventListener('hidden.bs.modal', () => {
        $confirmModal.remove();
    });

    document.getElementById('confirmModalBtn').addEventListener('click', async () => {
        document.getElementById('confirmModalBtn').innerHTML = $submitBtn;
        await handler(true);
        confirmModal.hide();
    });
}

export const $confirmModalDiv = document.getElementById('confirmModalDiv');

function preventClose(e) {
    e.preventDefault();
    return;
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
