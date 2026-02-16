export function getCookie(name) {
    let result = null;
    document.cookie.split(';').forEach((cookie) => {
        if (cookie.split('=')[0].trim() == name) {
            result = cookie.split('=')[1];
        }
    });
    return result;
}

export function setCookie(name, value, days = 1) {
    let expires = new Date();
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000);
    document.cookie = `${name}=${value};expires=${expires}`;
}
