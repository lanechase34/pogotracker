import { createToast } from 'toast';

// Validate the incoming json
export function validate(editor) {
    try {
        JSON.parse(editor.value);
        return true;
    } catch (e) {
        createToast(`Invalid JSON: ${e.message}`, 'danger', 'bi-exclamation-triangle');
        return false;
    }
}

// Nicely format the json
export function format(editor) {
    try {
        const parsed = JSON.parse(editor.value);
        editor.value = JSON.stringify(parsed, null, 4);
    } catch (e) {
        createToast(`Invalid JSON: ${e.message}`, 'danger', 'bi-exclamation-triangle');
    }
}
