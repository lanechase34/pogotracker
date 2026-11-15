export const $loading = '<div class="d-flex justify-content-center min-vh-100"></div>';

export const $loadingCard = '<div class="card"><div class="card-body d-flex justify-content-center"></div></div>';

export const $loadingModal = new bootstrap.Modal(document.getElementById('loadingModal'));

export const $submitBtn = '<span class="spinner-border spinner-border-sm mx-1" aria-hidden="true"></span>';

/**
 * Show a loading label on a button and disable it
 *
 * @param {HTMLButtonElement} $btn
 * @param {string} [html] - shown while loading
 * @returns {() => void} puts the original label back and enables the button
 */
export function setButtonLoading($btn, html = $submitBtn) {
    const original = $btn.innerHTML;
    $btn.innerHTML = html;
    $btn.disabled = true;
    return () => {
        $btn.innerHTML = original;
        $btn.disabled = false;
    };
}

const $loadMoreLabel = '<i class="bi bi-arrow-down-circle me-2"></i>Load More';
const $loadMoreLoading =
    '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Loading...';

/**
 * Add a Load More button after $target
 * Each click shows a loading label until loadMore settles, then the button goes away once there is nothing more
 * A failed load leaves the button for a retry (the wrapper toasts the error)
 *
 * @param {HTMLElement} $target
 * @param {() => Promise<boolean>} loadMore - fetches the next page, resolves false once there is nothing more to load
 * @param {object} [options]
 * @param {string} [options.id] - replaces any button with this id already on the page
 * @param {() => void} [options.onSettled] - runs after each click once the button is removed or ready again
 * @returns {HTMLButtonElement}
 */
export function addLoadMoreButton($target, loadMore, { id = '', onSettled = () => {} } = {}) {
    const $btn = document.createElement('button');
    if (id) {
        document.getElementById(id)?.remove();
        $btn.id = id;
    }
    $btn.type = 'button';
    $btn.className = 'btn btn-outline-dark w-100 mt-2';
    $btn.innerHTML = $loadMoreLabel;

    $btn.addEventListener('click', async () => {
        $btn.disabled = true;
        $btn.innerHTML = $loadMoreLoading;

        if (await loadMore()) {
            $btn.disabled = false;
            $btn.innerHTML = $loadMoreLabel;
        } else {
            $btn.remove();
        }
        onSettled();
    });

    $target.after($btn);
    return $btn;
}
