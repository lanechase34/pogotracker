import { $alertDiv, createAlert } from 'alert';
import { escapeHtml } from 'escape';
import { addCsrfField, csrfToken } from 'fetch';
import { $submitBtn } from 'loading';

export const $forms = /** @type {NodeListOf<HTMLFormElement>} */ (document.querySelectorAll('.needs-validation'));

/**
 * The reCAPTCHA v3 site key
 */
const siteKey = document.getElementById('currentEvent').dataset.sitekey;

/**
 * Development only - set when the reCAPTCHA keys are missing, forms submit without a token
 */
const skipRecaptcha = document.getElementById('currentEvent').dataset.skiprecaptcha === 'true';

/**
 * Validates a form, optionally running a reCAPTCHA check before submission.
 *
 * Workflow:
 *  1. Prevent the default browser submission.
 *  2. Run native HTML5 constraint validation via `checkValidity()`.
 *  3. Run any custom validation rules (e.g. the optional-select pair check).
 *  4. If valid and `submit` is `true`, optionally verify reCAPTCHA, and call `form.submit()`.
 *
 * @param {HTMLFormElement} form    - The form element to validate.
 * @param {SubmitEvent}     event   - The submit event that triggered validation.
 * @param {boolean}         [submit=true] - Whether to submit the form after
 *                                          successful validation. Pass `false`
 *                                          when you only need the validity result.
 * @returns {Promise<boolean>} Resolves to `true` if the form is valid (and was
 *                             submitted if `submit` is `true`), `false` otherwise.
 *
 * @example
 * form.addEventListener('submit', async (event) => {
 *   const isValid = await checkFormValidity(form, event);
 *   if (!isValid) console.log('Form has errors');
 * });
 */
export async function checkFormValidity(form, event, submit = true) {
    event.preventDefault();

    // Already submitting (double click, Enter while the recaptcha check runs) - drop the repeat
    if (submit && form.dataset.submitting === 'true') {
        event.stopPropagation();
        return false;
    }

    let valid = form.checkValidity();

    // Custom validation
    // Exactly one of the two '.optionalSelect' elements must have a value
    const optionalSelect = /** @type {NodeListOf<HTMLSelectElement>} */ (form.querySelectorAll('.optionalSelect'));
    if (optionalSelect.length === 2) {
        const firstFilled = optionalSelect[0].value !== '';
        const secondFilled = optionalSelect[1].value !== '';
        const exactlyOneFilled = firstFilled !== secondFilled;
        if (!exactlyOneFilled) {
            valid = false;
        }
    }

    if (!valid) {
        event.stopPropagation();
    }

    form.classList.add('was-validated');

    if (valid && submit) {
        form.dataset.submitting = 'true';

        // Enter in a field submits without a submitter on some browsers - fall back to the form's submit button
        const submitter = /** @type {HTMLButtonElement | null} */ (
            event.submitter ?? form.querySelector('[type="submit"]')
        );
        const originalLabel = submitter?.innerHTML ?? '';

        // Show loading state on the submit button.
        if (submitter) {
            submitter.dataset.originalLabel = originalLabel;
            submitter.innerHTML = $submitBtn;
            submitter.disabled = true;
        }

        if (form.classList.contains('verifyRecaptcha') && !skipRecaptcha) {
            let token = null;

            try {
                token = await executeRecaptcha(form.dataset.action);
            } catch (error) {
                console.error('Recaptcha error:', error);
                createAlert(
                    $alertDiv,
                    'danger',
                    'bi-exclamation-diamond-fill',
                    'Invalid Recaptcha. Login disabled.',
                    1
                );
            }

            if (!token) {
                if (submitter) {
                    submitter.innerHTML = originalLabel;
                    submitter.disabled = false;
                }
                delete form.dataset.submitting;
                return false;
            }
        }

        // Still valid, submit the form
        addCsrfField(form);
        form.submit();
    }

    return valid;
}

/**
 * Validate a modal form when its submit button is clicked
 * An invalid form is marked validated and the click is stopped
 *
 * @param {HTMLFormElement} form
 * @param {Event} event - the submit button's click
 * @returns {Record<string, FormDataEntryValue> | null} the form's fields, or null when the form is invalid
 */
export function validatedPacket(form, event) {
    const valid = form.checkValidity();
    form.classList.add('was-validated');

    if (!valid) {
        event.preventDefault();
        event.stopPropagation();
        return null;
    }
    return Object.fromEntries(new FormData(form).entries());
}

/**
 * Attaches a `submit` event listener to every form in the provided collection.
 * Each listener delegates to {@link checkFormValidity} with `submit = true`.
 *
 * @param {NodeListOf<HTMLFormElement> | HTMLFormElement[]} forms
 *   The collection of form elements to activate validation on.
 * @returns {void}
 */
export function addValidator(forms) {
    Array.from(forms).forEach((form) => {
        // Bound once - a second listener would run the recaptcha check and submit twice
        if (form.dataset.validatorBound === 'true') return;
        form.dataset.validatorBound = 'true';

        form.addEventListener(
            'submit',
            async (event) => {
                await checkFormValidity(form, event, true);
            },
            false
        );
    });
}

/**
 * A page restored from the back/forward cache keeps the submitting state of the form that navigated away
 * Unlock those forms so they can be submitted again
 */
window.addEventListener('pageshow', (event) => {
    if (!event.persisted) return;
    document.querySelectorAll('form[data-submitting="true"]').forEach((form) => {
        delete (/** @type {HTMLFormElement} */ (form).dataset.submitting);
        form.querySelectorAll('[type="submit"]').forEach(($btn) => {
            const $submit = /** @type {HTMLButtonElement} */ ($btn);
            if ($submit.dataset.originalLabel !== undefined) {
                $submit.innerHTML = $submit.dataset.originalLabel;
                delete $submit.dataset.originalLabel;
            }
            $submit.disabled = false;
        });
    });
});

/**
 * Executes a reCAPTCHA v3 challenge and verifies the resulting token
 * server-side via `POST /verifyrecaptcha`.
 *
 * The function waits for the `grecaptcha` library to be ready, requests a
 * token for the given action, then sends that token to the server. If the
 * server reports success that means the current session now stores a valid token.
 * This token is then validation server-side using the session scope and checks it.
 *
 * @param {string} action - The reCAPTCHA action label (e.g. `"login"`, `"signup"`).
 *                          Used by Google to score bot-like behaviour per action.
 * @returns {Promise<string | null>} Resolves with the reCAPTCHA token if the
 *                                   server-side verification passed, or `null`
 *                                   if it failed or the server sent a redirect
 *                                   (already logged in). Rejects if the `grecaptcha`
 *                                   SDK is unavailable or the network request fails.
 *
 * @throws {Error} If the `fetch` to `/verifyrecaptcha` fails or returns
 *                 an unparseable response.
 */
async function executeRecaptcha(action) {
    if (!siteKey) {
        throw new Error('reCAPTCHA site key not found.');
    }

    await new Promise((resolve) => {
        grecaptcha.ready(resolve);
    });

    const token = await grecaptcha.execute(siteKey, { action });

    const response = await fetch('/verifyrecaptcha', {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'x-csrf-token': csrfToken(),
        },
        body: JSON.stringify({ recaptchaToken: token }),
    });

    const data = await response.json().catch(() => null);

    // Remember me logged the trainer in on this request (the page itself loaded without the cookie)
    // The form no longer applies - go where the server sends a logged in trainer
    const redirect = data?.redirect;
    if (typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//')) {
        location.href = redirect;
        return null;
    }

    if (!response.ok || !data) {
        throw new Error(`Server responded with status ${response.status}`);
    }

    if (!data.success) {
        createAlert(
            $alertDiv,
            'danger',
            'bi-exclamation-diamond-fill',
            escapeHtml(data.message ?? 'reCAPTCHA verification failed.'),
            1
        );
        return null;
    }

    return token;
}
