import { expect, test } from '@playwright/test';

// Every page using the default layout preloads the global entry and its tree
const GLOBAL_TREE = ['contact', 'form', 'loading', 'login', 'runtime', 'toast', 'fetch', 'alert', 'escape'];

// Pages that load different handler modules - expected lists the import map names that must be preloaded
const PAGES = [
    { path: '/', handler: 'home', expected: ['home', 'blog', 'stats', 'search'] },
    {
        path: '/mypokedex',
        handler: 'pokedex',
        expected: ['pokedex', 'multiselect', 'modals', 'copy', 'localstorage', 'search'],
    },
    { path: '/custompokedexlist', handler: 'pokedex', expected: ['pokedex', 'multiselect'] },
    { path: '/overview', handler: 'stats', expected: ['stats', 'modals', 'copy'] },
    { path: '/pokemon', handler: 'pokemon', expected: ['pokemon', 'search'] },
    { path: '/profile', handler: 'trainer', expected: ['trainer', 'stats', 'modals', 'search'] },
    { path: '/buildtradeplan', handler: 'trade', expected: ['trade', 'search'] },
    { path: '/admin', handler: 'admin', expected: ['admin', 'socket', '@stomp/stompjs', 'json', 'localstorage'] },
    { path: '/admin/serverinfo', handler: 'admin', expected: ['admin', 'socket', '@stomp/stompjs'] },
];

// Log in as the dev account (test_0) through the login form's dev login button
async function loginAsDevUser(page) {
    await page.addInitScript(() => {
        window.grecaptcha = {
            ready: (callback) => callback(),
            execute: (_siteKey, _options) => Promise.resolve('mock-token'),
        };
    });
    await page.route('**/recaptcha/**', (route) => route.abort());
    await page.route('**/verifyrecaptcha', (route) =>
        route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ success: true }) })
    );

    await page.goto('/login', { waitUntil: 'load' });
    await page.locator('#populateFields').click();
    await expect(page.locator('#inputEmail')).toHaveValue('test_0@gmail.com');
    await page.locator('#submitForm').click();
    await page.waitForURL('/', { timeout: 10000, waitUntil: 'domcontentloaded' });

    // Let home finish its card fetches - leaving mid-request aborts them and logs fetch errors into the next page's checks
    await page.waitForLoadState('networkidle');
}

// Browser messages for a module that could not be resolved or fetched (Chromium, Firefox, WebKit wording)
const MODULE_ERROR =
    /Failed to resolve module specifier|Failed to fetch dynamically imported module|error loading dynamically imported module|Importing a module script failed|Loading module from .* was blocked|import map/i;

// Same file whatever the URL spelling - catches a .min or cache buster mismatch loading one module twice
const fileKey = (url) => new URL(url).pathname.replace(/\.min\.js$/, '.js');

/**
 * Record every same-origin JS request from here on, plus anything that fails or errors
 */
function trackScripts(page, baseURL) {
    const origin = new URL(baseURL).origin;
    const tracker = { requests: [], finished: new Set(), failures: [], errors: [] };
    const isOurScript = (url) => {
        const parsed = new URL(url);
        return parsed.origin === origin && parsed.pathname.endsWith('.js');
    };

    page.on('request', (request) => {
        if (isOurScript(request.url())) tracker.requests.push(request.url());
    });
    page.on('requestfinished', async (request) => {
        if (!isOurScript(request.url())) return;
        const response = await request.response();
        if (response && response.status() >= 400) tracker.failures.push(`${response.status()} ${request.url()}`);
        tracker.finished.add(request.url());
    });
    page.on('requestfailed', (request) => {
        if (isOurScript(request.url())) tracker.failures.push(`${request.failure()?.errorText} ${request.url()}`);
    });
    page.on('pageerror', (error) => tracker.errors.push(error.message));
    page.on('console', (message) => {
        if (message.type() === 'error' && MODULE_ERROR.test(message.text())) tracker.errors.push(message.text());
    });
    return tracker;
}

/**
 * Import map, modulepreload links and the module entry script as the browser sees them (absolute URLs)
 */
function readPageAssets(page) {
    return page.evaluate(() => {
        const mapText = document.querySelector('script[type="importmap"]')?.textContent ?? '';
        let imports = null;
        try {
            imports = Object.fromEntries(
                Object.entries(JSON.parse(mapText).imports).map(([name, url]) => [
                    name,
                    new URL(url, location.href).href,
                ])
            );
        } catch {
            imports = null;
        }
        return {
            imports,
            preloads: [...document.querySelectorAll('link[rel="modulepreload"]')].map((link) => link.href),
            entryScripts: [...document.querySelectorAll('script[type="module"][src]')].map((script) => script.src),
            handler: document.getElementById('currentEvent')?.dataset.handler,
        };
    });
}

/**
 * Load a page and assert its module graph: valid import map, preloads cover what loads, nothing fetched twice
 */
async function checkPageModules(page, baseURL, { path, handler, expected, entry }) {
    const tracker = trackScripts(page, baseURL);
    await page.goto(path, { waitUntil: 'load' });

    const assets = await readPageAssets(page);
    expect(assets.handler, `${path} rendered the wrong handler`).toBe(handler);
    expect(assets.imports, `${path} import map is missing or not valid JSON`).not.toBeNull();

    // Preloads are import map URLs, plus the layout's entry script
    const allowed = new Set([...Object.values(assets.imports), ...assets.entryScripts]);
    const nameOf = new Map(Object.entries(assets.imports).map(([name, url]) => [url, name]));
    for (const url of assets.entryScripts) nameOf.set(url, fileKey(url).split('/').pop().replace(/\.js$/, ''));
    for (const url of assets.preloads) {
        expect(allowed.has(url), `${path} preloads ${url}, which is not in the import map`).toBe(true);
    }
    expect(new Set(assets.preloads).size, `${path} has duplicate modulepreload links`).toBe(assets.preloads.length);

    // The modules this page should pull in are preloaded
    const preloadedNames = assets.preloads.map((url) => nameOf.get(url) ?? url);
    for (const name of [entry, ...(entry === 'global' ? GLOBAL_TREE : []), ...expected]) {
        expect(preloadedNames, `${path} is missing a preload for ${name}`).toContain(name);
    }

    // The handler module is imported last by runtime.js - once it lands, every static module has too
    const handlerURL = assets.imports[handler];
    await expect
        .poll(() => tracker.finished.has(handlerURL), { message: `${path} never loaded ${handler}` })
        .toBe(true);
    await expect
        .poll(() => assets.preloads.filter((url) => !tracker.finished.has(url)), {
            message: `${path} preloads that never finished loading`,
        })
        .toEqual([]);

    // Every script that loaded was preloaded - nothing slipped through one import level at a time
    const notPreloaded = [...new Set(tracker.requests)].filter((url) => !assets.preloads.includes(url));
    expect(notPreloaded, `${path} loaded modules that were not preloaded`).toEqual([]);

    // Each file was fetched once, under one URL
    const byFile = new Map();
    for (const url of tracker.requests) byFile.set(fileKey(url), [...(byFile.get(fileKey(url)) ?? []), url]);
    const duplicates = [...byFile.entries()].filter(([, urls]) => urls.length > 1);
    expect(duplicates, `${path} fetched a module more than once`).toEqual([]);

    expect(tracker.failures, `${path} had failed script requests`).toEqual([]);
    expect(tracker.errors, `${path} had script errors`).toEqual([]);
}

test.describe('Module loading', () => {
    test('Login page (basic layout) preloads the runtime tree', async ({ page, baseURL }) => {
        await checkPageModules(page, baseURL, {
            path: '/login',
            handler: 'login',
            entry: 'runtime',
            expected: ['login', 'form', 'fetch'],
        });

        const { preloads } = await readPageAssets(page);
        expect(
            preloads.some((url) => fileKey(url).endsWith('/global.js')),
            'Basic layout should not preload global'
        ).toBe(false);
    });

    test.describe('Authenticated pages', () => {
        test.beforeEach(async ({ page }) => {
            await loginAsDevUser(page);
        });

        for (const pageDef of PAGES) {
            test(`${pageDef.path} loads ${pageDef.handler} modules once, all preloaded`, async ({ page, baseURL }) => {
                await checkPageModules(page, baseURL, { ...pageDef, entry: 'global' });
            });
        }
    });
});
