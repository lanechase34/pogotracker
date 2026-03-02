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

    You may need to create a new rule in windows firewall

    ```
    New-NetFirewallRule -DisplayName "PostgreSQL WSL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
    ```

    And, update the postgres conf to allow wsl connections
    The file is location in `PostgreSQL/${version}/data/pg_hba.conf`

    ```
    # Allow connections from WSL
    host    all             all             172.16.0.0/12           scram-sha-256
    ```

- Make sure you set the following `.env` keys for WSL

    ```
    HTTP_HOST=0.0.0.0 # allows access from windows
    OS=linux

    DB_HOST=winhost
    DB_PORT=5432
    ```

## Testing Github Actions Locally

GitHub Actions workflows can be run locally using [act](https://github.com/nektos/act), which simulates the GitHub Actions runner environment via Docker.

### Prerequisites

- Docker running locally
- `act` installed
- The `ubuntu-24.04` runner image pulled:

    ```bash
    docker pull ghcr.io/catthehacker/ubuntu:act-24.04
    ```

### Running the Test Workflow

You can run the test workflow from the VS Code Tasks menu (`Terminal > Run Task`) or directly from the terminal at the project root:

```bash
act -W '.github/workflows/test.yml' -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04 --rm --pull=false
```

Note: The `--pull=false` flag prevents `act` from re-pulling the runner image each run. If the container image is missing or outdated, remove this flag to pull a fresh copy.

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

## GitHooks

    Test pre-commit GitHooks by running the following

    ```bash
    lefthook run pre-commit
    ```

## Dev Setup (No Docker)

### Prerequisites

- Node.js and npm
- CommandBox CLI
- PostgreSQL

### Setup

1. cd into /app with `cd /app`

1. Install and run commandbox with `box`

1. Install modules using

    ```
    install
    ```

1. Create PostgreSQL database with user

1. Generate and populate a development `.env` file

    ```
    run-script blankEnv
    ```

1. Create the database tables and seed with dev data

    Uses CFMigrations and interfaces through the commandbox-cfmigrations module

    ```
    # Install the CFMigrations table
    migrate install

    # Run Changesets
    migrate up

    # Seeds dev db
    migrate seed run
    ```

    For future changesets, run them using the following commands

    ```
    # Run changeset
    migrate up

    # Rollback changeset
    migrate down
    ```

1. Start server

    ```
    server start
    ```

1. Open site

    ```
    server open
    ```
