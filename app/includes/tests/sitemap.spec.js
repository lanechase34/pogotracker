import { expect, test } from '@playwright/test';

test.describe('Sitemap', () => {
    test('sitemap.xml is served with application/xml content-type', async ({ request }) => {
        const response = await request.get('/sitemap.xml');

        expect(response.status()).toBe(200);
        expect(response.headers()['content-type']).toContain('application/xml');
    });

    test('sitemap.xml returns valid XML with urlset root element', async ({ request }) => {
        const response = await request.get('/sitemap.xml');
        const body = await response.text();

        expect(body).toContain('<urlset');
        expect(body).toContain('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"');
        expect(body).toContain('xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"');
    });
});
