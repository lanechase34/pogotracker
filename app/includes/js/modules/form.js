import { $alertDiv, createAlert } from 'alert';
import { $submitBtn } from 'loading';

export const $forms = document.querySelectorAll('.needs-validation');

/**
 * The reCAPTCHA v3 site key
 */
const siteKey = document.getElementById('currentEvent').dataset.sitekey;

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
    let valid = form.checkValidity();

    // Custom validation
    // Exactly one of the two '.optionalSelect' elements must have a value
    const optionalSelect = form.querySelectorAll('.optionalSelect');
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
        const submitter = event.submitter;
        const originalLabel = submitter.innerHTML;

        // Show loading state on the submit button.
        submitter.innerHTML = $submitBtn;
        submitter.disabled = true;

        if (form.classList.contains('verifyRecaptcha')) {
            let token = null;

            try {
                token = await executeRecaptcha(form.dataset.action);
            } catch (error) {
                console.log(error);
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
                submitter.innerHTML = originalLabel;
                submitter.disabled = false;
                return false;
            }
        }

        // Still valid, submit the form
        form.submit();
    }

    return valid;
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
 *                                   if it failed. Rejects if the `grecaptcha`
 *                                   SDK is unavailable or the network request fails.
 *
 * @throws {Error} If the `fetch` to `/verifyrecaptcha` fails or returns
 *                 an unparseable response.
 */
async function executeRecaptcha(action) {
    if (!siteKey) {
        throw new Error('reCAPTCHA site key not found.');
    }

    await new Promise((resolve) => grecaptcha.ready(resolve));

    const token = await grecaptcha.execute(siteKey, { action });

    const response = await fetch('/verifyrecaptcha', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recaptchaToken: token }),
    });

    if (!response.ok) {
        throw new Error(`Server responded with status ${response.status}`);
    }

    const data = await response.json();

    if (!data.success) {
        createAlert(
            $alertDiv,
            'danger',
            'bi-exclamation-diamond-fill',
            data.message ?? 'reCAPTCHA verification failed.',
            1
        );
        return null;
    }

    return token;
}
