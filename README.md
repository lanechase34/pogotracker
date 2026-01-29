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

## Dev Setup

### Prerequisites

- Node.js and npm
- CommandBox CLI
- PostgreSQL

1. Install and run commandbox with `box`

2. Install modules using

    ```
    install
    ```

3. Create PostgreSQL database with user

4. Generate and populate a development `.env` file

    ```
    run-script blankEnv
    ```

5. Create the database tables and seed with dev data
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

6. Start server

    ```
    server start
    ```

7. Open site

    ```
    server open
    ```
