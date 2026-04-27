import { expect, test } from '@playwright/test';

const isMobile = (projectName) => projectName.toLowerCase().includes('mobile');

// Reusable helper to log in via the dev credentials
async function loginAsTestUser(page) {
    // Stub grecaptcha before any scripts load
    await page.addInitScript(() => {
        window.grecaptcha = {
            ready: (callback) => callback(),

            execute: (_siteKey, _options) => Promise.resolve('mock-token'),
        };
    });

    // Block the Google reCAPTCHA script
    await page.route('**/recaptcha/**', (route) => route.abort());

    // Mock the verifyrecaptcha endpoint - use a function to log if it fires
    await page.route('http://localhost:8081/verifyrecaptcha', async (route) => {
        await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ success: true }),
        });
    });

    await page.goto('/login');
    await page.locator('#inputEmail').fill('test_1@gmail.com');
    await page.locator('#inputPassword').fill('aaaaaaaaaaaaaa');
    await page.locator('#submitForm').click();
    await page.waitForURL('/', { timeout: 10000 });
}

// Reusable helper to ensure the sidebar is open
async function openSidebarIfMobile(page, testInfo) {
    if (isMobile(testInfo.project.name)) {
        await page.locator('button.hamburgerButton').click();
        await expect(page.locator('#sideNavbar')).toBeVisible();
    }
}

test.describe('Authenticated session', () => {
    test.beforeEach(async ({ page, context }) => {
        await loginAsTestUser(page, context);
    });

    test.describe('Login and redirect', () => {
        test('Valid credentials redirect to the root url', async ({ page }) => {
            await expect(page).toHaveURL('/');
        });

        test('Session is active after redirect', async ({ page }) => {
            const isAuthenticated = await page.locator('#currentEvent').getAttribute('data-userauthenticated');
            expect(isAuthenticated).toBe('true');
        });

        test('Visiting /login while authenticated redirects away from login', async ({ page }) => {
            await page.goto('/login');
            await expect(page).not.toHaveURL('/login');
        });
    });

    test.describe('Authenticated sidebar', () => {
        test('Sidebar displays the username test_1', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#sidebarUsername')).toBeVisible();
            await expect(page.locator('#sidebarUsername')).toHaveText('test_1');
        });

        test('Sidebar profile icon is visible', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#sidebarIcon')).toBeVisible();
        });

        test('Sidebar profile icon has a valid src attribute', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const src = await page.locator('#sidebarIcon').getAttribute('src');
            expect(src).toBeTruthy();
            expect(src).not.toBe('');
        });

        test('Sidebar no longer shows the log in button', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#loginBtn')).not.toBeAttached();
        });

        test('Profile group dropdown is present in the sidebar', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#profileGroup')).toBeAttached();
        });
    });

    test.describe('Profile dropdown', () => {
        test('Profile dropdown opens when clicked', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            const dropdown = page.locator('.dropdown-menu');
            await expect(dropdown).toBeVisible();
        });

        test('Profile dropdown contains the profile link', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            const profileLink = page.locator('.dropdown-menu a[href="/profile"]');
            await expect(profileLink).toBeVisible();
            await expect(profileLink).toContainText('Profile');
        });

        test('Profile dropdown contains the log out button', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await expect(page.locator('#logoutBtn')).toBeVisible();
            await expect(page.locator('#logoutBtn')).toContainText('Log Out');
        });

        test('Profile link navigates to /profile', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await page.locator('.dropdown-menu a[href="/profile"]').click();
            await expect(page).toHaveURL('/profile');
        });
    });

    test.describe('Navigation links', () => {
        test('Home nav link is present and active', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const homeLink = page.locator('a.nav-link[href="/"]');
            await expect(homeLink).toBeVisible();
            await expect(homeLink).toHaveClass(/active/);
        });

        test('Pokedex nav link is present and navigates to /mypokedex', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const link = page.locator('a.nav-link[href="/mypokedex"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Pokedex');
            await link.click();
            await expect(page).toHaveURL('/mypokedex');
        });

        test('Shadow Pokedex nav link is present and navigates to /myshadowpokedex', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const link = page.locator('a.nav-link[href="/myshadowpokedex"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Shadow Pokedex');
            await link.click();
            await expect(page).toHaveURL('/myshadowpokedex');
        });

        test('Custom Pokedex nav link is present and navigates to /custompokedexlist', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const link = page.locator('a.nav-link[href="/custompokedexlist"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Custom Pokedex');
            await link.click();
            await expect(page).toHaveURL('/custompokedexlist');
        });

        test('Trade Plan nav link is present and navigates to /buildtradeplan', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const link = page.locator('a.nav-link[href="/buildtradeplan"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Trade Plan');
            await link.click();
            await expect(page).toHaveURL('/buildtradeplan');
        });

        test('Stats nav link is present and navigates to /overview', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            const link = page.locator('a.nav-link[href="/overview"]');
            await expect(link).toBeVisible();
            await expect(link).toContainText('Stats');
            await link.click();
            await expect(page).toHaveURL('/overview');
        });

        test('Contact button is present in the sidebar', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#contactBtn')).toBeVisible();
            await expect(page.locator('#contactBtn')).toContainText('Contact');
        });
    });

    test.describe('Logout', () => {
        test('Clicking log out redirects to a logged out state', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await page.locator('#logoutBtn').click();
            await expect(page).toHaveURL('/');
        });

        test('User is unauthenticated after logging out', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await page.locator('#logoutBtn').click();
            await page.goto('/');
            const isAuthenticated = await page.locator('#currentEvent').getAttribute('data-userauthenticated');
            expect(isAuthenticated).toBe('false');
        });

        test('Log in button is visible again after logging out', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await page.locator('#logoutBtn').click();
            await page.goto('/');

            await openSidebarIfMobile(page, testInfo);
            await expect(page.locator('#loginBtn')).toBeVisible();
        });

        test('Username is no longer visible after logging out', async ({ page }, testInfo) => {
            await openSidebarIfMobile(page, testInfo);
            await page.locator('#profileGroup').click();
            await page.locator('#logoutBtn').click();
            await page.goto('/');
            await expect(page.locator('#sidebarUsername')).not.toBeAttached();
        });
    });
});
