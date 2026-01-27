ARG BUILD_FROM
FROM ${BUILD_FROM}

# Build arguments
ARG CLEANUPARR_VERSION=2.5.1
ARG TARGETARCH

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    unzip

# Download and install Cleanuparr binary
RUN set -ex; \
    case "${TARGETARCH}" in \
        amd64) BINARY_ARCH="amd64" ;; \
        arm64) BINARY_ARCH="arm64" ;; \
        arm/v7) BINARY_ARCH="arm" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    DOWNLOAD_URL="https://github.com/Cleanuparr/Cleanuparr/releases/download/v${CLEANUPARR_VERSION}/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}.zip"; \
    echo "Downloading Cleanuparr v${CLEANUPARR_VERSION} for ${BINARY_ARCH}..."; \
    curl -fsSL "${DOWNLOAD_URL}" -o /tmp/cleanuparr.zip; \
    unzip /tmp/cleanuparr.zip -d /tmp/; \
    mv "/tmp/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}/Cleanuparr" /usr/bin/cleanuparr; \
    chmod +x /usr/bin/cleanuparr; \
    rm -rf /tmp/cleanuparr.zip "/tmp/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}"

# Copy root filesystem (s6-overlay service scripts)
COPY rootfs /

# Set permissions for service scripts
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;
