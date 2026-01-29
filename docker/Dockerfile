# Commandbox jdk image
FROM ortussolutions/commandbox:jdk21

# Metadata
LABEL maintainer="Chase Lane <lanechase34@outlook.com>"
LABEL respository="https://github.com/lanechase34/pogotracker"

# Env set up
ENV LUCEE_EXTENSIONS="671B01B8-B3B3-42B9-AC055A356BED5281;version=42.7.3,D062D72F-F8A2-46F0-8CBC91325B2F067B;version=6.5.2"
ENV HEALTHCHECK_URI="http://127.0.0.1:${PORT}/healthcheck"

# Copy application files to root - Uses .dockerignore to ignore files
COPY ./ ${APP_DIR}/

# The following commands will be ran against the app directory
WORKDIR ${APP_DIR}

# Make sure dependencies are installed
RUN box install --production

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh

# Run it
CMD $BUILD_DIR/run.sh