import { $alertDiv, createAlert } from 'alert';
import { $submitBtn } from 'loading';

export const $forms = document.querySelectorAll('.needs-validation');

const siteKey = document.getElementById('currentEvent').dataset.sitekey;

export async function checkFormValidity(form, event, submit = true) {
    event.preventDefault();
    let valid = form.checkValidity();

    // Custom checks
    let optionalSelect = form.querySelectorAll('.optionalSelect');
    // At least one of these selects must have an option selected
    if (
        optionalSelect.length == 2 &&
        ((optionalSelect[0].value == '' && optionalSelect[1].value == '') ||
            (optionalSelect[0].value != '' && optionalSelect[1].value != ''))
    ) {
        valid = false;
    }

    if (!valid) {
        event.stopPropagation();
    }

    form.classList.add('was-validated');

    if (valid && submit) {
        let temp = event.submitter.innerHTML;
        event.submitter.innerHTML = $submitBtn;
        event.submitter.disabled = true;

        if (form.classList.contains('verifyRecaptcha')) {
            let validRecaptcha = await executeRecaptcha(form.dataset.action);

            if (!validRecaptcha) {
                event.submitter.innerHTML = temp;
                event.submitter.disabled = false;
                valid = false;
            }
        }

        // Still valid, submit the form
        if (valid) {
            form.submit();
        }
    }

    return valid;
}

export async function addValidator(forms) {
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

async function executeRecaptcha(action) {
    return new Promise((resolve) => {
        grecaptcha.ready(() => {
            grecaptcha.execute(siteKey, { action: action }).then((token) => {
                fetch('/verifyrecaptcha', {
                    method: 'POST',
                    body: JSON.stringify({ recaptchaToken: token }),
                })
                    .then((response) => response.json())
                    .then((data) => {
                        if (!data.success) {
                            createAlert($alertDiv, 'danger', 'bi-exclamation-diamond-fill', data.message, 1);
                        }

                        return resolve(data.success);
                    });
            });
        });
    });
}
