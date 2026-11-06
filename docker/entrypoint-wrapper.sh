#!/bin/bash
# will attempt to set up database and seed with dev data
set -e

echo "Starting POGO Tracker..."

# Install dependencies first - commandbox-migrations lives in the container's CommandBox home,
# so it is gone whenever the container is recreated even though app/modules persists on the mount
box install

# Check if migration table exists by attempting to install
echo "Checking migration status..."
INSTALL_OUTPUT=$(box migrate install 2>&1) || {
    echo "ERROR: Migration install failed!"
    echo "$INSTALL_OUTPUT"
    exit 1
}

if echo "$INSTALL_OUTPUT" | grep -q "Migration table already installed"; then
  echo "Database already initialized - applying any new migrations"
  box migrate up
else
  echo "First run detected - running migrations..."
  box recipe scripts/docker-firstrun.boxr
  echo "Database setup complete!"
fi

# Execute the original CommandBox run script
exec ${BUILD_DIR}/run.sh
