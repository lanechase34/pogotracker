import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import globals from 'globals';

export default defineConfig([
    {
        // Global ignores
        ignores: ['**/node_modules/**', '**/build/**', 'eslint.config.js'],
    },
    eslint.configs.recommended,
    {
        files: ['**/*.js', '**/*.jsx'], // Target TypeScript files
        ignores: [],
        languageOptions: {
            parser: eslint.parser,
            parserOptions: {
                ecmaVersion: 'latest',
                sourceType: 'module',
            },
            globals: {
                // js running in browser
                ...globals.browser,
                // libraries
                DataTable: 'readonly',
                bootstrap: 'readonly',
                globalModals: 'readonly',
                Masonry: 'readonly',
                Chart: 'readonly',
                $: 'readonly',
                moment: 'readonly',
                grecaptcha: 'readonly',
                MultiSelect: 'readonly',
                // editorjs and extensions
                edjsHTML: 'readonly',
                EditorJS: 'readonly',
                Paragraph: 'readonly',
                Header: 'readonly',
                RawTool: 'readonly',
                ImageTool: 'readonly',
                EditorjsList: 'readonly',
                Quote: 'readonly',
                CodeTool: 'readonly',
                bodyJson: 'readonly',
                // cfm to js vars
                statDataset: 'readonly',
                pokemonSearchArray: 'readonly',
            },
        },
        rules: {},
    },
]);
