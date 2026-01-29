export const $loading =
    '<div class="d-flex justify-content-center min-vh-100">' +
    // '<div class="spinner-border" role="status">' +
    //'<span class="visually-hidden">Loading...</span>' +
    '</div>' +
    '</div>';

export const $loadingCard =
    '<div class="card">' +
    '<div class="card-body d-flex justify-content-center">' +
    //   '<div class="spinner-border" role="status">' +
    // '<span class="visually-hidden">Loading...</span>' +
    '</div>' +
    '</div>' +
    '</div>';

export const $loadingModal = new bootstrap.Modal(document.getElementById('loadingModal'));

export const $submitBtn = '<span class="spinner-border spinner-border-sm mx-1" aria-hidden="true"></span>';
