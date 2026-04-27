import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import importPlugin from 'eslint-plugin-import';
import simpleImportSort from 'eslint-plugin-simple-import-sort';

export default defineConfig([
    {
        // Global ignores
        ignores: ['**/node_modules/**', '**/build/**', 'eslint.config.js'],
    },
    eslint.configs.recommended,

    // Import/Export organization
    importPlugin.flatConfigs.recommended,

    {
        files: ['**/*.js', '**/*.jsx'],
        plugins: {
            'simple-import-sort': simpleImportSort,
        },
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
                process: 'readonly',
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
        rules: {
            'simple-import-sort/imports': 'error',
            'simple-import-sort/exports': 'error',
            'import/first': 'error',
            'import/newline-after-import': 'error',
            'import/no-duplicates': 'error',
            'import/no-unresolved': [
                'error',
                {
                    ignore: ['@stomp/stompjs'],
                },
            ],
            eqeqeq: ['error', 'always', { null: 'ignore' }],
            'no-console': ['warn', { allow: ['warn', 'error'] }],
            'no-var': 'error',
            'prefer-const': 'error',
            'no-unused-vars': [
                'error',
                {
                    argsIgnorePattern: '^_',
                    varsIgnorePattern: '^_',
                },
            ],
            'no-use-before-define': ['error', { functions: false, classes: false, variables: true }],
            'no-await-in-loop': 'warn',
            'no-promise-executor-return': 'error',
            'require-await': 'error',
            'prefer-arrow-callback': 'error',
            'arrow-body-style': ['error', 'as-needed'],
            'object-shorthand': ['error', 'always'],
            'prefer-template': 'error',
            'no-useless-concat': 'error',
            'no-param-reassign': ['warn', { props: false }],
            'no-shadow': 'error',
            'no-implicit-globals': 'error',
            'no-eval': 'error',
            'no-implied-eval': 'error',
            'no-alert': 'error',
            'import/namespace': 'off',
        },
        settings: {
            'import/resolver': {
                alias: {
                    map: [
                        ['alert', './js/modules/alert.js'],
                        ['contact', './js/modules/contact.js'],
                        ['cookie', './js/modules/cookie.js'],
                        ['copy', './js/modules/copy.js'],
                        ['display', './js/modules/display.js'],
                        ['fetch', './js/modules/fetch.js'],
                        ['form', './js/modules/form.js'],
                        ['loading', './js/modules/loading.js'],
                        ['modals', './js/modules/modals.js'],
                        ['multiselect', './js/modules/multiselect.js'],
                        ['search', './js/modules/search.js'],
                        ['socket', './js/modules/socket.js'],
                        ['toast', './js/modules/toast.js'],
                        ['admin', './js/handlers/admin.js'],
                        ['blog', './js/handlers/blog.js'],
                        ['home', './js/handlers/home.js'],
                        ['login', './js/handlers/login.js'],
                        ['pokedex', './js/handlers/pokedex.js'],
                        ['pokemon', './js/handlers/pokemon.js'],
                        ['stats', './js/handlers/stats.js'],
                        ['trade', './js/handlers/trade.js'],
                        ['trainer', './js/handlers/trainer.js'],
                        ['runtime', './js/runtime.js'],
                    ],
                    extensions: ['.js'],
                },
            },
        },
    },
]);
