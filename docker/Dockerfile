# Commandbox jdk image
FROM ortussolutions/commandbox:jdk21

# Metadata
LABEL maintainer="Chase Lane <lanechase34@outlook.com>"
LABEL respository="https://github.com/lanechase34/pogotracker"

# Env set up
ENV HEALTHCHECK_URI="http://127.0.0.1:${PORT}/healthcheck"

# Copy application files to root - Uses .dockerignore to ignore files
COPY ./ ${APP_DIR}/

# The following commands will be ran against the app directory
WORKDIR ${APP_DIR}

# Set the commandbox lineending
RUN box config set JSON.lineEnding=`#chr 10`

# Make sure dependencies are installed
RUN box install --production

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh

# Run it
CMD $BUILD_DIR/run.sh