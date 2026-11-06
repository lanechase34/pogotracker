import os from 'node:os';
import process from 'node:process';

import { defineConfig, devices } from '@playwright/test';

const isWindows = process.platform === 'win32';

function workerCount() {
    if (process.env.E2E_WORKERS) return Number(process.env.E2E_WORKERS);
    if (process.env.CI) return 1;

    const threads = os.availableParallelism();
    return threads >= 12 ? Math.floor(threads / 2) : 2;
}

export default defineConfig({
    testDir: './tests',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: workerCount(),
    reporter: process.env.CI ? [['html'], ['junit', { outputFile: 'test-results/junit.xml' }]] : [['html']],
    use: {
        baseURL: process.env.BASE_URL || 'http://localhost:8081',
        trace: 'on-first-retry',
        navigationTimeout: 30000,
    },
    timeout: 30000,
    expect: {
        timeout: 10000,
    },
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        ...(!isWindows
            ? [
                  {
                      name: 'webkit',
                      use: { ...devices['Desktop Safari'] },
                  },
              ]
            : []),

        {
            name: 'Mobile Chrome',
            use: { ...devices['Pixel 5'] },
        },

        ...(!isWindows
            ? [
                  {
                      name: 'Mobile Safari',
                      use: { ...devices['iPhone 12'] },
                  },
              ]
            : []),
    ],
});
