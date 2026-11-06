/**
 * Escape a value for safe interpolation into HTML text or a quoted attribute
 */
export function escapeHtml(str) {
    return String(str ?? '')
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

/**
 * Encode each segment of a relative path for use in a URL
 */
export function encodePath(path) {
    // encodeURIComponent intentionally skips ' (apostrophe), so replace it manually
    return String(path ?? '')
        .split('/')
        .map((s) => encodeURIComponent(s).replace(/'/g, '%27'))
        .join('/');
}
