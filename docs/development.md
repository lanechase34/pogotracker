# Development Guide

This document covers developer workflows including dependency updates, formatting, and testing.

## Updates

### Box Updates

1. Check for updates

    ```
    box update
    ```

2. Review and confirm updates to `box.json` when prompted
3. Restart server
    ```
    server restart
    ```

### NPM Updates

1. Check for updates

    ```
    ncu
    ```

2. Update `package.json` file

    ```
    ncu -u
    ```

3. Install new packages

    ```
    npm install
    ```

4. (Optional) Run audit fixes
    ```
    npm audit fix
    ```

## Code Formatting

### Frontend

1. Make sure vscode can resolve `eslint.config.ts`
2. Check for lint errors by running

    ```
    cd includes/
    npm run lint
    ```

### Backend

1. Format all `*.cfc` files by running this in box

    ```
    run-script format
    ```

## Testing

1. Run Testbox Suite via browser
    ```
    http://localhost:8081/tests/runner.cfm
    ```

## Running in WSL

- Access with localhost:${port}
- Add winhost mapping to ~/.bashrc for database connection

    ```
    # Add DNS entry for Windows host

    if ! $(cat /etc/hosts | grep -q 'winhost'); then
    echo 'Adding DNS entry for Windows host in /etc/hosts'
    echo '\n# Windows host - added via ~/.bashhrc' | sudo tee -a /etc/hosts
    echo -e "$(grep nameserver /etc/resolv.conf | awk '{print $2, "   winhost"}')" | sudo tee -a /etc/hosts
    fi
    ```

- Connect to database using the following

    ```
    psql -h winhost -p 5432 -U postgres

    .env
    DB_HOST=winhost
    DB_PORT=5432
    ```

## Github Actions

Run Github Test action locally using

```

ctrl + shift + p
Tasks: Run Task -> Github Actions Test

```

This runs the yaml file using nektos/act to utilize docker instances
simulating the real steps Github takes when executing this action

## CSS and JS Minifier

Uses clean-css and terser for CSS and Javascript minification respectively.
Minified files go to `/include/build`

1. Install node packages

    `npm install`

2. Run commands to minify

    ```
    npm run-script minJS
    npm run-script minCSS
    ```

    Or, use vscode tasks to run

    ```
    ctrl + shift + p
    Tasks: Run Build Task
    ```
