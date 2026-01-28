ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Extract from upstream image
# BUILD_VERSION comes automatically from config.yaml 'version' property
FROM alpine:${BUILD_VERSION} AS app-source

# Stage 2: Build on Home Assistant base
FROM ${BUILD_FROM}

# Copy application binary from upstream
# (In real example, this would be the actual application binary)
COPY --from=app-source /bin/busybox /usr/bin/myapp

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate \
    bash

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
