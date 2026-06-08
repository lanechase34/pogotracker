const $copied = `<i class="bi bi-check2 me-1"></i>Copied`;

export function initCopyIcons() {
    const copyIcons = document.querySelectorAll('.copyIcon');
    Array.from(copyIcons).forEach((copyicon) => {
        copyicon.addEventListener('click', (evt) => {
            const text = evt.currentTarget.dataset.copydata;

            navigator.clipboard.writeText(text);

            evt.currentTarget.innerHTML = $copied;
        });
    });
}

/**
 * Used when a button changes text
 * Locks the button to the width of largest of the text (original or what it changes to)
 */
export function lockButtonWidth($btn, html) {
    const orig = $btn.innerHTML;
    const origWidth = $btn.offsetWidth;
    $btn.innerHTML = html;
    $btn.style.minWidth = `${Math.max(origWidth, $btn.offsetWidth)}px`;
    $btn.innerHTML = orig;
}

export function lockCopyButtonWidth($btn) {
    lockButtonWidth($btn, $copied);
}

export function copyString($btns, string) {
    navigator.clipboard.writeText(string);

    $btns.forEach(($btn) => {
        $btn.disabled = true;
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
