import { expect, test } from '@playwright/test';

test.describe('Login page', () => {
    test.beforeEach(async ({ page }) => {
        await page.route('**/recaptcha/**', (route) => route.abort());
        await page.goto('/login', { waitUntil: 'load' });
    });

    test.describe('Page load', () => {
        test('Has the correct page title', async ({ page }) => {
            await expect(page).toHaveTitle(/POGO Tracker/);
        });

        test('Displays the POGO Tracker logo', async ({ page }) => {
            const logo = page.locator('img.logo');
            await expect(logo).toBeVisible();
            await expect(logo).toHaveAttribute('alt', 'POGO Tracker Logo');
        });

        test('Displays the POGO Tracker heading', async ({ page }) => {
            await expect(page.locator('.auth-hero span.fw-bold')).toContainText('POGO Tracker');
        });

        test('Renders the email input', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toBeVisible();
        });

        test('Renders the password input', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toBeVisible();
        });

        test('Renders the remember me checkbox', async ({ page }) => {
            await expect(page.locator('#inputPersist')).toBeVisible();
        });

        test('Renders the log in submit button', async ({ page }) => {
            await expect(page.locator('#submitForm')).toBeVisible();
            await expect(page.locator('#submitForm')).toContainText('Sign In');
        });

        test('Renders the forgot password link', async ({ page }) => {
            const link = page.locator('a[href="/forgot"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Forgot password?');
        });

        test('Renders the sign up link', async ({ page }) => {
            const link = page.locator('a[href="/register"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Sign up now');
        });

        test('Email input is empty on load', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toHaveValue('');
        });

        test('Password input is empty on load', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveValue('');
        });

        test('Remember me checkbox is unchecked on load', async ({ page }) => {
            await expect(page.locator('#inputPersist')).not.toBeChecked();
        });

        test('Password input type is password', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('type', 'password');
        });

        test('Email input has envelope icon', async ({ page }) => {
            await expect(page.locator('.bi-envelope')).toBeVisible();
        });

        test('Password input has key icon', async ({ page }) => {
            await expect(page.locator('.bi-key')).toBeVisible();
        });
    });

    test.describe('Email field', () => {
        test('Accepts valid email input', async ({ page }) => {
            await page.locator('#inputEmail').fill('test@example.com');
            await expect(page.locator('#inputEmail')).toHaveValue('test@example.com');
        });

        test('Shows invalid state when submitting with empty email', async ({ page }) => {
            await page.locator('#inputPassword').fill('validpassword123');
            await page.locator('#submitForm').click();
            await expect(page.locator('#loginForm')).toHaveClass(/was-validated/);
        });

        test('Enforces minlength of 1 on email', async ({ page }) => {
            const minlength = await page.locator('#inputEmail').getAttribute('minlength');
            expect(minlength).toBe('1');
        });

        test('Enforces maxlength of 100 on email', async ({ page }) => {
            const maxlength = await page.locator('#inputEmail').getAttribute('maxlength');
            expect(maxlength).toBe('100');
        });

        test('Does not accept more than 100 characters in email', async ({ page }) => {
            const longEmail = `${'a'.repeat(95)}@b.com`;
            await page.locator('#inputEmail').fill(longEmail);
            const value = await page.locator('#inputEmail').inputValue();
            expect(value.length).toBeLessThanOrEqual(100);
        });

        test('Email field is marked as required', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toHaveAttribute('required', '');
        });

        test('Email label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="inputEmail"]')).toContainText('Email');
        });
    });

    test.describe('Password field', () => {
        test('Accepts valid password input', async ({ page }) => {
            await page.locator('#inputPassword').fill('validpassword123');
            await expect(page.locator('#inputPassword')).toHaveValue('validpassword123');
        });

        test('Shows invalid state when submitting with empty password', async ({ page }) => {
            await page.locator('#inputEmail').fill('test@example.com');
            await page.locator('#submitForm').click();
            await expect(page.locator('#loginForm')).toHaveClass(/was-validated/);
        });

        test('Enforces minlength of 12 on password', async ({ page }) => {
            const minlength = await page.locator('#inputPassword').getAttribute('minlength');
            expect(minlength).toBe('12');
        });

        test('Enforces maxlength of 50 on password', async ({ page }) => {
            const maxlength = await page.locator('#inputPassword').getAttribute('maxlength');
            expect(maxlength).toBe('50');
        });

        test('Does not accept more than 50 characters in password', async ({ page }) => {
            const longPassword = 'a'.repeat(55);
            await page.locator('#inputPassword').fill(longPassword);
            const value = await page.locator('#inputPassword').inputValue();
            expect(value.length).toBeLessThanOrEqual(50);
        });

        test('Password field is marked as required', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('required', '');
        });

        test('Password label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="inputPassword"]')).toContainText('Password');
        });

        test('Password value is masked', async ({ page }) => {
            await page.locator('#inputPassword').fill('mysecretpassword');
            await expect(page.locator('#inputPassword')).toHaveAttribute('type', 'password');
        });
    });

    test.describe('Remember me checkbox', () => {
        test('Can be checked', async ({ page }) => {
            await page.locator('#inputPersist').check();
            await expect(page.locator('#inputPersist')).toBeChecked();
        });

        test('Can be unchecked after being checked', async ({ page }) => {
            await page.locator('#inputPersist').check();
            await page.locator('#inputPersist').uncheck();
            await expect(page.locator('#inputPersist')).not.toBeChecked();
        });

        test('Has the correct label', async ({ page }) => {
            await expect(page.locator('label[for="inputPersist"]')).toContainText('Remember me');
        });

        test('Checkbox name attribute is persist', async ({ page }) => {
            await expect(page.locator('#inputPersist')).toHaveAttribute('name', 'persist');
        });
    });

    test.describe('Form submission', () => {
        test('Does not submit when both fields are empty', async ({ page }) => {
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/login');
        });

        test('Does not submit when only email is filled', async ({ page }) => {
            await page.locator('#inputEmail').fill('test@example.com');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/login');
        });

        test('Does not submit when only password is filled', async ({ page }) => {
            await page.locator('#inputPassword').fill('validpassword123');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/login');
        });

        test('Does not submit when password is shorter than 12 characters', async ({ page }) => {
            await page.locator('#inputEmail').fill('test@example.com');
            await page.locator('#inputPassword').fill('short');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/login');
        });

        test('Form has correct action attribute', async ({ page }) => {
            await expect(page.locator('#loginForm')).toHaveAttribute('action', '/login/doLogin');
        });

        test('Form method is post', async ({ page }) => {
            await expect(page.locator('#loginForm')).toHaveAttribute('method', 'post');
        });

        test('Form has novalidate attribute for custom validation handling', async ({ page }) => {
            await expect(page.locator('#loginForm')).toHaveAttribute('novalidate', '');
        });

        test('Form has the recaptcha class applied', async ({ page }) => {
            await expect(page.locator('#loginForm')).toHaveClass(/verifyRecaptcha/);
        });

        test('Shows both invalid states when submitting completely empty form', async ({ page }) => {
            await page.locator('#submitForm').click();
            const form = page.locator('#loginForm');
            await expect(form).toHaveClass(/was-validated/);
        });

        test('Proceeds past client validation when both fields are valid', async ({ page }) => {
            await page.locator('#inputEmail').fill('test@example.com');
            await page.locator('#inputPassword').fill('validpassword123!');
            await page.locator('#submitForm').click();
            // Client validation passed — request reached the server (reCAPTCHA blocked in tests)
            await expect(page.locator('.alert')).toBeVisible();
            await expect(page).toHaveURL('/login');
        });
    });

    test.describe('Navigation links', () => {
        test('Forgot password link navigates to /forgot', async ({ page }) => {
            await page.locator('a[href="/forgot"]').click();
            await expect(page).toHaveURL('/forgot');
        });

        test('Sign up link navigates to /register', async ({ page }) => {
            await page.locator('a[href="/register"]').click();
            await expect(page).toHaveURL('/register');
        });

        test('Forgot password link has correct href', async ({ page }) => {
            await expect(page.locator('a[href="/forgot"]')).toHaveAttribute('href', '/forgot');
        });

        test('Sign up link has correct href', async ({ page }) => {
            await expect(page.locator('a[href="/register"]')).toHaveAttribute('href', '/register');
        });
    });

    test.describe('Dev login buttons', () => {
        test('Dev login button is visible', async ({ page }) => {
            await expect(page.locator('#populateFields')).toBeVisible();
        });

        test('User login button is visible', async ({ page }) => {
            await expect(page.locator('#populateFields2')).toBeVisible();
        });

        test('Dev login button populates email with test_0@gmail.com', async ({ page }) => {
            await page.locator('#populateFields').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_0@gmail.com');
        });

        test('Dev login button populates password field', async ({ page }) => {
            await page.locator('#populateFields').click();
            await expect(page.locator('#inputPassword')).not.toHaveValue('');
        });

        test('User login button populates email with test_1@gmail.com', async ({ page }) => {
            await page.locator('#populateFields2').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_1@gmail.com');
        });

        test('User login button populates password field', async ({ page }) => {
            await page.locator('#populateFields2').click();
            await expect(page.locator('#inputPassword')).not.toHaveValue('');
        });

        test('Dev login button overwrites existing email value', async ({ page }) => {
            await page.locator('#inputEmail').fill('other@example.com');
            await page.locator('#populateFields').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_0@gmail.com');
        });

        test('User login button overwrites existing email value', async ({ page }) => {
            await page.locator('#inputEmail').fill('other@example.com');
            await page.locator('#populateFields2').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_1@gmail.com');
        });

        test('Clicking dev login then user login updates email to test_1', async ({ page }) => {
            await page.locator('#populateFields').click();
            await page.locator('#populateFields2').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_1@gmail.com');
        });

        test('Clicking user login then dev login updates email to test_0', async ({ page }) => {
            await page.locator('#populateFields2').click();
            await page.locator('#populateFields').click();
            await expect(page.locator('#inputEmail')).toHaveValue('test_0@gmail.com');
        });
    });

    test.describe('reCAPTCHA', () => {
        test('reCAPTCHA site key is set on the page', async ({ page }) => {
            const sitekey = await page.locator('#currentEvent').getAttribute('data-sitekey');
            expect(sitekey).toBeTruthy();
        });
    });

    test.describe('Accessibility', () => {
        test('Email input has an associated label', async ({ page }) => {
            await expect(page.locator('label[for="inputEmail"]')).toBeAttached();
        });

        test('Password input has an associated label', async ({ page }) => {
            await expect(page.locator('label[for="inputPassword"]')).toBeAttached();
        });

        test('Remember me checkbox has an associated label', async ({ page }) => {
            await expect(page.locator('label[for="inputPersist"]')).toBeAttached();
        });

        test('Submit button is of type submit', async ({ page }) => {
            await expect(page.locator('#submitForm')).toHaveAttribute('type', 'submit');
        });

        test('Logo has a meaningful alt attribute', async ({ page }) => {
            const alt = await page.locator('img.logo').getAttribute('alt');
            expect(alt).not.toBe('');
            expect(alt).not.toBeNull();
        });

        test('Form has a name attribute', async ({ page }) => {
            await expect(page.locator('#loginForm')).toHaveAttribute('name', 'loginForm');
        });
    });
});
