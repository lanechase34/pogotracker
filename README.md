# POGO Tracker

POGO Tracker offers in-depth analytics on your Pokemon collection, catches, walking distance, medal achievements, and much more

## Features

### Pokedex

- Track catches, shiny catches, and shadow catches across all regions, mega forms, gigantamax forms, and unown

### Custom Pokedex

- User-entered subsets of Pokemon that use pokedex information to see completion
- System generated subsets that match upcoming in-game events

### Trade Plan

- Find mismatches between your collection and a friend's collection to trade

### Stats

- Track daily km walked, catches, pokestops spun, and xp
- Track medal progress
- See breakdown of progress

## Documentation

- Deployment: `docs/deployment.md`
- Development workflows: `docs/development.md`

## Dev Docker Setup

See `docs/development.md` on how to run without using Docker.

Follow these steps to run the App + PostgreSQL database locally in Docker.

The database container will automatically be seeded with dev data.

### Prerequisites

- Docker Desktop

### Setup

1. Using `docker/env.docker.example` as a template, populate `app/.env`

2. Navigate to Docker dir

    ```
    cd docker
    ```

3. Start docker

    ```
    docker compose up -d
    ```

4. Verify app is running (this may be a few minutes on first start)
    - **Health Check**: http://localhost:8081/healthcheck
    - **App**: http://localhost:8081

5. Stop containers by running

    ```
    docker compose down
    ```

6. Install NPM packages for formatting, linting frontend files

    ```bash
    cd /app/includes
    npm install
    ```

7. Setup GitHooks from root
    ```bash
    npm install -g lefthook
    lefthook install
    ```

### Commands

- Stop containers and clear all data

    ```
    docker compose down -v
    ```

- Restart the containers

    ```
    docker compose restart
    ```

- View logs from all services

    ```
    docker compose logs -f
    ```

- View logs from specific service

    ```
    docker compose logs -f pogotracker_app
    docker compose logs -f pogotracker_db
    ```

### Connecting to database

| Setting      | Value                |
| ------------ | -------------------- |
| **Host**     | `localhost`          |
| **Port**     | `5432`               |
| **Database** | `pogotracker_db`     |
| **Username** | `pogotracker_docker` |
| **Password** | `docker1234`         |
| **Schema**   | `public`             |
