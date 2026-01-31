# Development Guide

This document covers developer workflows including dependency updates, formatting, and testing.

There are many tasks available that cover these topics below. Run tasks in vscode using `ctrl + shift + p` then typing `Run Task`

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
    http://localhost:${HTTP_PORT}/tests/runner.cfm
    ```

## Running in WSL

- Access with `localhost:${HTTP_PORT}`
- Add winhost mapping to ~/.bashrc for database connection

    ```
    # Add DNS entry for Windows host
    if ! grep -q 'winhost' /etc/hosts; then
        echo 'Adding DNS entry for Windows host in /etc/hosts'
        # Get the Windows host IP from the default gateway or ip route
        WIN_HOST_IP=$(ip route show default | awk '{print $3}')

        if [ -n "$WIN_HOST_IP" ]; then
            echo '' | sudo tee -a /etc/hosts
            echo '# Windows host - added via ~/.bashrc' | sudo tee -a /etc/hosts
            echo "$WIN_HOST_IP    winhost" | sudo tee -a /etc/hosts
            echo "Added winhost entry: $WIN_HOST_IP"
        else
            echo "Warning: Could not determine Windows host IP"
        fi
    fi
    ```

- Connect to database using the following

    Install PostgreSQL client if needed

    ```
    sudo apt install postgresql-client-common
    sudo apt install postgresql-client-16
    ```

    Check connection

    ```
    psql -h winhost -p 5432 -U postgres
    ```

- Make sure you set the following `.env` keys for WSL

    ```
    HTTP_HOST=0.0.0.0 # allows access from windows
    OS=linux

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

- Debugging (commands assume powershell)
    - Clean up contains that may have not been properly removed after each run

    ```
    # Stop all act containers
    docker ps -a --filter "name=act-" -q | ForEach-Object { docker stop $_ }

    # Remove all act containers
    docker ps -a --filter "name=act-" -q | ForEach-Object { docker rm $_ }

    # Remove all act networks
    docker network ls --filter "name=act-" -q | ForEach-Object { docker network rm $_ }
    ```

    - Clean everything docker related (warning, destructive operation!)

    ```
    docker system prune -af --volumes
    ```

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
