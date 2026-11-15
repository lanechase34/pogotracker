/**
 * Writes the banned word list services/profanity.cfc reads, from the maintained @2toad/profanity package
 * Runs on npm install/ci (postinstall), so the list is never committed and updates with the package version
 *
 * Output: assets/profanity.json - the web server blocks /includes/assets, so it is never served
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { profaneWords } from '@2toad/profanity';

const require = createRequire(import.meta.url);
const { version } = JSON.parse(readFileSync(require.resolve('@2toad/profanity/package.json'), 'utf8'));

const words = [
    ...new Set((profaneWords.get('en') ?? []).map((word) => word.trim().toLowerCase()).filter(Boolean)),
].sort();
if (!words.length) {
    throw new Error('@2toad/profanity has no English words - has the package changed shape?');
}

const output = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'profanity.json');
writeFileSync(output, `${JSON.stringify({ source: `@2toad/profanity@${version}`, words }, null, 4)}\n`);
console.warn(`Wrote ${words.length} words from @2toad/profanity@${version} to assets/profanity.json`);
