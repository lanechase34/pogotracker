const $copied = `<i class="bi bi-check2 me-1"></i>Copied`;

/**
 * Show one label of a .label-swap button (global.css) - the others stay in the layout, hidden, so the width never changes
 *
 * @param {HTMLElement} $btn
 * @param {string} label - data-label of the .label-swap-item to show
 */
export function showSwapLabel($btn, label) {
    $btn.querySelectorAll('.label-swap-item').forEach(($item) => {
        $item.classList.toggle('active', /** @type {HTMLElement} */ ($item).dataset.label === label);
    });
}

export function copyString($btns, string) {
    navigator.clipboard.writeText(string);

    $btns.forEach(($btn) => {
        $btn.disabled = true;

        if ($btn.classList.contains('label-swap')) {
            showSwapLabel($btn, 'copied');
            setTimeout(() => {
                showSwapLabel($btn, 'default');
                $btn.disabled = false;
            }, 4 * 1000);
            return;
        }

        const temp = $btn.innerHTML;

        $btn.innerHTML = $copied;
        setTimeout(() => {
            $btn.innerHTML = temp;
            $btn.disabled = false;
        }, 4 * 1000);
    });
}

/**
 * Remove duplicates in a comma delimited string
 */
export function removeDuplicates(str) {
    return [...new Set(str.split(',').map((s) => s.trim()))].join(',');
}
