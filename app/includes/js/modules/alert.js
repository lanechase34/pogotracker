export const $alertDiv = document.getElementById('alertDiv');

export function createAlert(target, type, icon, message, mt = 3) {
    target.innerHTML = `<div class="mt-${mt} alert alert-${type} alert-dismissible" role="alert"><i class="bi ${icon} me-2"></i>${message}<button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button></div>`;
}
