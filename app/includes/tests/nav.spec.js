import { expect, test } from '@playwright/test';

const isMobile = (projectName) => projectName.toLowerCase().includes('mobile');

test.describe('Login Page Navigation', () => {
    test.describe('Desktop', () => {
        test('Sidebar is visible without interaction', async ({ page }, testInfo) => {
            test.skip(isMobile(testInfo.project.name), 'Desktop only');

            await page.goto('/');

            const sidebar = page.locator('#sideNavbar');
            await expect(sidebar).toBeVisible();
        });

        test('Hamburger button is not visible on desktop', async ({ page }, testInfo) => {
            test.skip(isMobile(testInfo.project.name), 'Desktop only');

            await page.goto('/');

            const hamburger = page.locator('button.hamburgerButton');
            await expect(hamburger).not.toBeVisible();
        });

        test('Login button is visible in sidebar without interaction', async ({ page }, testInfo) => {
            test.skip(isMobile(testInfo.project.name), 'Desktop only');

            await page.goto('/');

            const loginBtn = page.locator('#loginBtn');
            await expect(loginBtn).toBeVisible();
            await expect(loginBtn).toContainText('Log In');
        });

        test('login button navigates to /login', async ({ page }, testInfo) => {
            test.skip(isMobile(testInfo.project.name), 'Desktop only');

            await page.goto('/');

            await page.locator('#loginBtn').click();
            await expect(page).toHaveURL('/login');
        });
    });

    test.describe('Mobile', () => {
        test('Hamburger button is visible on mobile', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            const hamburger = page.locator('button.hamburgerButton');
            await expect(hamburger).toBeVisible();
        });

        test('Sidebar is hidden before opening hamburger menu', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            const sidebar = page.locator('#sideNavbar');
            await expect(sidebar).not.toBeVisible();
        });

        test('Login button is not visible before opening hamburger menu', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            const loginBtn = page.locator('#loginBtn');
            await expect(loginBtn).not.toBeVisible();
        });

        test('Hamburger opens the sidebar', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            await page.locator('button.hamburgerButton').click();

            const sidebar = page.locator('#sideNavbar');
            await expect(sidebar).toBeVisible();
        });

        test('Login button is visible after opening hamburger menu', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            await page.locator('button.hamburgerButton').click();

            const loginBtn = page.locator('#loginBtn');
            await expect(loginBtn).toBeVisible();
            await expect(loginBtn).toContainText('Log In');
        });

        test('Login button navigates to /login after opening hamburger menu', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            await page.locator('button.hamburgerButton').click();
            await expect(page.locator('#sideNavbar')).toBeVisible();

            await page.locator('#loginBtn').click();
            await expect(page).toHaveURL('/login');
        });

        test('Sidebar closes when close button is clicked', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            await page.locator('button.hamburgerButton').click();
            await expect(page.locator('#sideNavbar')).toBeVisible();

            await page.locator('#closeSideNavbar').click();
            await expect(page.locator('#sideNavbar')).not.toBeVisible();
        });

        test('Login button is no longer visible after closing sidebar', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            await page.locator('button.hamburgerButton').click();
            await expect(page.locator('#sideNavbar')).toBeVisible();

            await page.locator('#closeSideNavbar').click();
            await expect(page.locator('#loginBtn')).not.toBeVisible();
        });

        test('Sidebar can be reopened after closing', async ({ page }, testInfo) => {
            test.skip(!isMobile(testInfo.project.name), 'Mobile only');

            await page.goto('/');

            // Open
            await page.locator('button.hamburgerButton').click();
            await expect(page.locator('#sideNavbar')).toBeVisible();

            // Close
            await page.locator('#closeSideNavbar').click();
            await expect(page.locator('#sideNavbar')).not.toBeVisible();

            // Reopen
            await page.locator('button.hamburgerButton').click();
            await expect(page.locator('#sideNavbar')).toBeVisible();
            await expect(page.locator('#loginBtn')).toBeVisible();
        });
    });

    test.describe('Shared', () => {
        test('Page title is correct', async ({ page }) => {
            await page.goto('/');
            await expect(page).toHaveTitle(/POGO Tracker/);
        });

        test('Login button has correct href', async ({ page }, testInfo) => {
            await page.goto('/');

            if (isMobile(testInfo.project.name)) {
                await page.locator('button.hamburgerButton').click();
                await expect(page.locator('#sideNavbar')).toBeVisible();
            }

            const loginBtn = page.locator('#loginBtn');
            await expect(loginBtn).toHaveAttribute('href', '/login');
        });

        test('Login button contains person icon', async ({ page }, testInfo) => {
            await page.goto('/');

            if (isMobile(testInfo.project.name)) {
                await page.locator('button.hamburgerButton').click();
                await expect(page.locator('#sideNavbar')).toBeVisible();
            }

            const icon = page.locator('#loginBtn .bi-person');
            await expect(icon).toBeVisible();
        });
    });
});
