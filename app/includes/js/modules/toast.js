import { getWrapper } from 'fetch';

export async function getFriendRequestToast() {
    return await getWrapper({
        url: '/friend/getFriendRequestToast',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('toastsDiv').appendChild(newDiv);

            const $friendRequestToast = document.getElementById('friendRequestToast');
            if ($friendRequestToast) {
                const friendToast = new bootstrap.Toast($friendRequestToast);
                friendToast.show();
            }
        },
    });
}

export function createToast(message, type = 'primary', icon = 'bi-info-circle', duration = 5000) {
    // Create toast container if it doesn't exist
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }

    // Create toast element
    const toastId = `toast-${Date.now()}`;
    const toastHTML = `
        <div id="${toastId}" class="toast align-items-center text-bg-${type} border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="bi ${icon} me-2"></i>${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    `;

    // Insert toast
    toastContainer.insertAdjacentHTML('beforeend', toastHTML);

    // Get toast element and show it
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, {
        autohide: true,
        delay: duration,
    });

    toast.show();

    // Remove from DOM after hidden
    toastElement.addEventListener('hidden.bs.toast', () => {
        toastElement.remove();
    });

    return toast;
}
