/**
 * @param {string} key
 * @returns {string | null} the stored value, or null when unset or storage is blocked
 */
export function getLocalStorage(key) {
    try {
        return localStorage.getItem(key);
    } catch {
        return null;
    }
}

/**
 * Store a value - silently skipped when storage is blocked (private mode, disabled cookies)
 *
 * @param {string} key
 * @param {string} value
 */
export function setLocalStorage(key, value) {
    try {
        localStorage.setItem(key, value);
    } catch {
        // storage blocked - the value only lives for this page
    }
}
