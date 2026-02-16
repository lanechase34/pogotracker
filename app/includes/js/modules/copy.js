const $copied = `<i class="bi bi-check2 me-2"></i>Copied!`;

export function initCopyIcons() {
    let copyIcons = document.querySelectorAll('.copyIcon');
    Array.from(copyIcons).forEach((copyicon) => {
        copyicon.addEventListener('click', (evt) => {
            let text = evt.currentTarget.dataset.copydata;

            navigator.clipboard.writeText(text);

            evt.currentTarget.innerHTML = $copied;
        });
    });
}

export function copyString($btns, string) {
    navigator.clipboard.writeText(string);

    $btns.forEach(($btn) => {
        $btn.disabled = true;
        let temp = $btn.innerHTML;

        $btn.innerHTML = $copied;
        setTimeout(() => {
            $btn.innerHTML = temp;
            $btn.disabled = false;
        }, 4 * 1000);
    });
}
