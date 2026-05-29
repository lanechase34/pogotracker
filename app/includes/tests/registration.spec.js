import { expect, test } from '@playwright/test';
import { randomInt, randomUUID } from 'crypto';

async function mockRecaptcha(page) {
    await page.addInitScript(() => {
        window.grecaptcha = {
            ready: (callback) => callback(),
            execute: (_siteKey, _options) => Promise.resolve('mock-token'),
        };
    });
    await page.route('**/recaptcha/**', (route) => route.abort());
    await page.route('http://localhost:8081/verifyrecaptcha', async (route) => {
        await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ success: true }),
        });
    });
}

async function registerNewUser(page) {
    const unique = randomUUID().replace(/-/g, '');
    const firstOption = await page.locator('#iconList option:not([disabled])').first().getAttribute('value');

    await page.locator('#inputUsername').fill(`reg${unique.slice(0, 10)}`);
    await page.locator('#inputPassword').fill('testpassword123!');
    await page.locator('#inputEmail').fill(`reg${unique.slice(0, 10)}@example.com`);
    await page.locator('#friendcode').fill(randomInt(100000000000, 1000000000000).toString());
    await page.locator('#iconList').selectOption(firstOption);
    await page.locator('#submitForm').click();
    await page.waitForURL('/verify', { timeout: 10000, waitUntil: 'domcontentloaded' });
}

//  Registration page

test.describe('Registration page', () => {
    test.beforeEach(async ({ page }) => {
        await page.route('**/recaptcha/**', (route) => route.abort());
        await page.goto('/register', { waitUntil: 'load' });
    });

    test.describe('Page load', () => {
        test('Has the correct page title', async ({ page }) => {
            await expect(page).toHaveTitle(/POGO Tracker/);
        });

        test('Displays the POGO Tracker brand', async ({ page }) => {
            await expect(page.locator('.auth-hero span.fw-bold')).toContainText('POGO Tracker');
        });

        test('Displays the Create Account heading', async ({ page }) => {
            await expect(page.locator('.auth-hero h1')).toContainText('Create Account');
        });

        test('Displays the POGO Tracker logo', async ({ page }) => {
            const logo = page.locator('img.logo');
            await expect(logo).toBeVisible();
            await expect(logo).toHaveAttribute('alt', 'POGO Tracker Logo');
        });

        test('Renders the username input', async ({ page }) => {
            await expect(page.locator('#inputUsername')).toBeVisible();
        });

        test('Renders the password input', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toBeVisible();
        });

        test('Renders the email input', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toBeVisible();
        });

        test('Renders the friend code input', async ({ page }) => {
            await expect(page.locator('#friendcode')).toBeVisible();
        });

        test('Renders the icon select', async ({ page }) => {
            await expect(page.locator('#iconList')).toBeVisible();
        });

        test('Icon select has at least one selectable option', async ({ page }) => {
            const options = page.locator('#iconList option:not([disabled])');
            await expect(options).not.toHaveCount(0);
        });

        test('Renders the submit button', async ({ page }) => {
            await expect(page.locator('#submitForm')).toBeVisible();
            await expect(page.locator('#submitForm')).toContainText('Create Account');
        });

        test('Renders the sign in link', async ({ page }) => {
            const link = page.locator('a[href="/login"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Sign in');
        });

        test('All text inputs are empty on load', async ({ page }) => {
            await expect(page.locator('#inputUsername')).toHaveValue('');
            await expect(page.locator('#inputPassword')).toHaveValue('');
            await expect(page.locator('#inputEmail')).toHaveValue('');
            await expect(page.locator('#friendcode')).toHaveValue('');
        });
    });

    test.describe('Labels', () => {
        test('Username label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="inputUsername"]')).toContainText('Username');
        });

        test('Password label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="inputPassword"]')).toContainText('Password');
        });

        test('Email label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="inputEmail"]')).toContainText('Email');
        });

        test('Friend code label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="friendcode"]')).toContainText('Friend Code');
        });

        test('Icon label is rendered correctly', async ({ page }) => {
            await expect(page.locator('label[for="iconList"]')).toContainText('Icon');
        });
    });

    test.describe('Field attributes', () => {
        test('Username minlength is 1', async ({ page }) => {
            await expect(page.locator('#inputUsername')).toHaveAttribute('minlength', '1');
        });

        test('Username maxlength is 30', async ({ page }) => {
            await expect(page.locator('#inputUsername')).toHaveAttribute('maxlength', '30');
        });

        test('Username is required', async ({ page }) => {
            await expect(page.locator('#inputUsername')).toHaveAttribute('required', '');
        });

        test('Password minlength is 10', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('minlength', '10');
        });

        test('Password maxlength is 50', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('maxlength', '50');
        });

        test('Password is required', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('required', '');
        });

        test('Password type is password', async ({ page }) => {
            await expect(page.locator('#inputPassword')).toHaveAttribute('type', 'password');
        });

        test('Email minlength is 1', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toHaveAttribute('minlength', '1');
        });

        test('Email maxlength is 100', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toHaveAttribute('maxlength', '100');
        });

        test('Email is required', async ({ page }) => {
            await expect(page.locator('#inputEmail')).toHaveAttribute('required', '');
        });

        test('Friend code minlength is 12', async ({ page }) => {
            await expect(page.locator('#friendcode')).toHaveAttribute('minlength', '12');
        });

        test('Friend code maxlength is 12', async ({ page }) => {
            await expect(page.locator('#friendcode')).toHaveAttribute('maxlength', '12');
        });

        test('Friend code is required', async ({ page }) => {
            await expect(page.locator('#friendcode')).toHaveAttribute('required', '');
        });

        test('Icon select is required', async ({ page }) => {
            await expect(page.locator('#iconList')).toHaveAttribute('required', '');
        });
    });

    test.describe('Form structure', () => {
        test('Form has correct action', async ({ page }) => {
            await expect(page.locator('#registrationForm')).toHaveAttribute('action', '/login/register');
        });

        test('Form method is post', async ({ page }) => {
            await expect(page.locator('#registrationForm')).toHaveAttribute('method', 'post');
        });

        test('Form has novalidate attribute', async ({ page }) => {
            await expect(page.locator('#registrationForm')).toHaveAttribute('novalidate', '');
        });

        test('Form has the recaptcha class applied', async ({ page }) => {
            await expect(page.locator('#registrationForm')).toHaveClass(/verifyRecaptcha/);
        });

        test('Form has a name attribute', async ({ page }) => {
            await expect(page.locator('#registrationForm')).toHaveAttribute('name', 'registrationForm');
        });

        test('Submit button is of type submit', async ({ page }) => {
            await expect(page.locator('#submitForm')).toHaveAttribute('type', 'submit');
        });
    });

    test.describe('Validation', () => {
        test('Stays on /register when submitted empty', async ({ page }) => {
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/register');
        });

        test('Stays on /register when only username is filled', async ({ page }) => {
            await page.locator('#inputUsername').fill('testuser');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/register');
        });

        test('Stays on /register when password is shorter than 10 characters', async ({ page }) => {
            await page.locator('#inputUsername').fill('testuser');
            await page.locator('#inputPassword').fill('short');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/register');
        });

        test('Friend code does not accept fewer than 12 characters', async ({ page }) => {
            await page.locator('#friendcode').fill('12345');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/register');
        });
    });

    test.describe('Navigation', () => {
        test('Sign in link navigates to /login', async ({ page }) => {
            await page.locator('a[href="/login"]').click();
            await expect(page).toHaveURL('/login');
        });
    });
});

//  Registration circuit

test.describe('Registration circuit', () => {
    test('Valid registration redirects to the verification page', async ({ page }) => {
        await mockRecaptcha(page);
        await page.goto('/register', { waitUntil: 'domcontentloaded' });
        await registerNewUser(page);
        await expect(page).toHaveURL('/verify');
    });
});

//  Verification page

test.describe('Verification page', () => {
    test.beforeEach(async ({ page }) => {
        await mockRecaptcha(page);
        await page.goto('/register', { waitUntil: 'domcontentloaded' });
        await registerNewUser(page);
    });

    test.describe('Page load', () => {
        test('Has the correct page title', async ({ page }) => {
            await expect(page).toHaveTitle(/POGO Tracker/);
        });

        test('Displays the POGO Tracker brand', async ({ page }) => {
            await expect(page.locator('.auth-hero span.fw-bold')).toContainText('POGO Tracker');
        });

        test('Displays the Verify Your Account heading', async ({ page }) => {
            await expect(page.locator('.auth-hero h1')).toContainText('Verify Your Account');
        });

        test('Displays the POGO Tracker logo', async ({ page }) => {
            const logo = page.locator('img.logo');
            await expect(logo).toBeVisible();
            await expect(logo).toHaveAttribute('alt', 'POGO Tracker Logo');
        });

        test('Shows inbox instruction text', async ({ page }) => {
            await expect(page.locator('p.text-muted')).toContainText('Check your inbox');
        });

        test('Shows the pogotracker.app sender domain hint', async ({ page }) => {
            await expect(page.locator('p.text-muted')).toContainText('@pogotracker.app');
        });

        test('Resend code link is present and labelled correctly', async ({ page }) => {
            await expect(page.locator('#submitResend')).toBeVisible();
            await expect(page.locator('#submitResend')).toContainText('Resend code');
        });

        test('Renders the verification code input', async ({ page }) => {
            await expect(page.locator('#inputCode')).toBeVisible();
        });

        test('Renders the submit button', async ({ page }) => {
            await expect(page.locator('#submitForm')).toBeVisible();
            await expect(page.locator('#submitForm')).toContainText('Verify Account');
        });
    });

    test.describe('Code input', () => {
        test('Code input is empty on load', async ({ page }) => {
            await expect(page.locator('#inputCode')).toHaveValue('');
        });

        test('Code input minlength is 8', async ({ page }) => {
            await expect(page.locator('#inputCode')).toHaveAttribute('minlength', '8');
        });

        test('Code input maxlength is 8', async ({ page }) => {
            await expect(page.locator('#inputCode')).toHaveAttribute('maxlength', '8');
        });

        test('Code input is required', async ({ page }) => {
            await expect(page.locator('#inputCode')).toHaveAttribute('required', '');
        });

        test('Code input has autocomplete one-time-code', async ({ page }) => {
            await expect(page.locator('#inputCode')).toHaveAttribute('autocomplete', 'one-time-code');
        });

        test('Code input has an associated label', async ({ page }) => {
            await expect(page.locator('label[for="inputCode"]')).toBeAttached();
        });

        test('Accepts typed input', async ({ page }) => {
            await page.locator('#inputCode').fill('ABCD1234');
            await expect(page.locator('#inputCode')).toHaveValue('ABCD1234');
        });

        test('Does not accept more than 8 characters', async ({ page }) => {
            await page.locator('#inputCode').fill('ABCDEFGHI');
            const value = await page.locator('#inputCode').inputValue();
            expect(value.length).toBeLessThanOrEqual(8);
        });

        test('Can be cleared after typing', async ({ page }) => {
            await page.locator('#inputCode').fill('ABCD1234');
            await page.locator('#inputCode').clear();
            await expect(page.locator('#inputCode')).toHaveValue('');
        });

        test('Can be overwritten', async ({ page }) => {
            await page.locator('#inputCode').fill('AAAA1111');
            await page.locator('#inputCode').fill('BBBB2222');
            await expect(page.locator('#inputCode')).toHaveValue('BBBB2222');
        });
    });

    test.describe('Form structure', () => {
        test('Verification form has correct action', async ({ page }) => {
            await expect(page.locator('#verificationForm')).toHaveAttribute('action', '/login/verify');
        });

        test('Verification form method is post', async ({ page }) => {
            await expect(page.locator('#verificationForm')).toHaveAttribute('method', 'post');
        });

        test('Verification form has novalidate attribute', async ({ page }) => {
            await expect(page.locator('#verificationForm')).toHaveAttribute('novalidate', '');
        });

        test('Submit button is of type submit', async ({ page }) => {
            await expect(page.locator('#submitForm')).toHaveAttribute('type', 'submit');
        });

        test('Resend form is attached to the DOM', async ({ page }) => {
            await expect(page.locator('#resendVerificationForm')).toBeAttached();
        });

        test('Resend form has correct action', async ({ page }) => {
            await expect(page.locator('#resendVerificationForm')).toHaveAttribute('action', '/verify');
        });
    });

    test.describe('Validation', () => {
        test('Stays on /verify when submitted empty', async ({ page }) => {
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/verify');
        });

        test('Stays on /verify when code is shorter than 8 characters', async ({ page }) => {
            await page.locator('#inputCode').fill('ABC');
            await page.locator('#submitForm').click();
            await expect(page).toHaveURL('/verify');
        });
    });
});
