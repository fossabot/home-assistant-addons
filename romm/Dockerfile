ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Romm version
ARG ROMM_VERSION=3.5.1

# Install system dependencies
RUN apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-common \
    redis \
    python3 \
    py3-pip \
    nginx \
    nodejs \
    npm \
    git \
    p7zip \
    file \
    bash \
    curl \
    openssl \
    && rm -rf /var/cache/apk/*

# Install Python uv package manager
COPY --from=ghcr.io/astral-sh/uv:0.7.19 /uv /uvx /usr/local/bin/

# Clone Romm repository
RUN git clone --depth 1 --branch ${ROMM_VERSION} \
    https://github.com/rommapp/romm.git /opt/romm \
    && rm -rf /opt/romm/.git

# Build frontend
WORKDIR /opt/romm/frontend
RUN npm ci --legacy-peer-deps \
    && npm run build \
    && rm -rf node_modules \
    && npm cache clean --force

# Install Python dependencies
WORKDIR /opt/romm
RUN uv sync --all-extras --no-dev

# Create necessary directories
RUN mkdir -p \
    /data/mysql \
    /data/redis \
    /data/resources \
    /data/assets \
    /data/config \
    /share/romm/library \
    && chmod -R 755 /data

# Copy rootfs
COPY rootfs /

# Set permissions for scripts
RUN chmod +x /etc/services.d/*/run \
    && chmod +x /etc/services.d/*/finish \
    && chmod +x /etc/cont-init.d/*.sh \
    && chmod +x /usr/local/bin/*.sh

# Labels
LABEL \
    io.hass.name="Romm - ROM Manager" \
    io.hass.description="Beautiful, powerful, self-hosted ROM manager for retro gaming" \
    io.hass.arch="aarch64|amd64|armv7" \
    io.hass.type="addon" \
    io.hass.version="${ROMM_VERSION}" \
    maintainer="Your Name <your.email@example.com>" \
    org.opencontainers.image.title="Romm - ROM Manager" \
    org.opencontainers.image.description="Beautiful, powerful, self-hosted ROM manager for retro gaming" \
    org.opencontainers.image.source="https://github.com/rommapp/romm" \
    org.opencontainers.image.licenses="AGPL-3.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1

# Use S6-Overlay init
CMD ["/init"]
