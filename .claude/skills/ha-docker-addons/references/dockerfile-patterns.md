# Dockerfile Patterns for Wrapped Docker Images

This reference provides comprehensive Dockerfile patterns for wrapping existing Docker images as Home Assistant add-ons.

## BUILD_VERSION Automation

Home Assistant automatically passes the `version` field from config.yaml as `BUILD_VERSION` to your Dockerfile during build.

**Key Points:**
- ✅ Version only needs to be defined in config.yaml
- ✅ No need to define BUILD_VERSION in build.yaml args
- ✅ Dockerfile always uses the version from config.yaml
- ✅ Single source of truth for version management

**Example flow:**

```yaml
# config.yaml
version: "3.6.4"
```

```dockerfile
# Dockerfile - BUILD_VERSION automatically available
ARG BUILD_VERSION
FROM grafana/loki:${BUILD_VERSION}
```

Result: `FROM grafana/loki:3.6.4`

## Pattern 1: Single Binary Extraction

**Use when:** Application provides a single binary with minimal dependencies.

**Advantages:**
- Smallest final image size
- Simple to maintain
- Clear separation of concerns
- Easy to update upstream version

**Example: Grafana Loki**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Extract from upstream
FROM grafana/loki:${BUILD_VERSION} AS loki-source

# Stage 2: Build on HA base
FROM ${BUILD_FROM}

# Copy binary only
COPY --from=loki-source /usr/bin/loki /usr/bin/loki

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate

# Create application user
RUN adduser -D -H -u 999 -g loki loki

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
```

**Finding binaries in upstream image:**

```bash
# Run container and explore
docker run --rm -it grafana/loki:3.6.4 sh

# Locate binary
which loki
# Output: /usr/bin/loki

# Check if it's statically linked
ldd /usr/bin/loki
# If "not a dynamic executable" → static binary (easy)
# If shows libraries → need to copy dependencies
```

## Pattern 2: Binary with Shared Libraries

**Use when:** Binary depends on shared libraries not in HA base image.

**Challenge:** Must identify and copy all required .so files.

**Solution:**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy binary
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Copy shared libraries
COPY --from=app-source /usr/lib/libmyapp.so* /usr/lib/
COPY --from=app-source /usr/lib/libspecial.so* /usr/lib/

# Install system library dependencies
RUN apk add --no-cache \
    libstdc++ \
    libgcc

COPY rootfs /
WORKDIR /data
```

**Identify required libraries:**

```bash
# Check dependencies
docker run --rm -it myapp/official:latest sh -c "ldd /usr/bin/myapp"

# Output shows required .so files:
# libmyapp.so.1 => /usr/lib/libmyapp.so.1
# libstdc++.so.6 => /usr/lib/libstdc++.so.6
# libc.musl-x86_64.so.1 => /lib/libc.musl-x86_64.so.1

# Copy custom libraries, install standard ones via apk
```

## Pattern 3: Complete Directory Extraction

**Use when:** Application requires multiple files (configs, plugins, static assets).

**Example: Application with plugins**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy entire application directory
COPY --from=app-source /usr/local/myapp/ /usr/local/myapp/

# Copy binaries
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp
COPY --from=app-source /usr/bin/myapp-admin /usr/bin/myapp-admin

# Copy default configuration
COPY --from=app-source /etc/myapp/ /etc/myapp/

# Install dependencies
RUN apk add --no-cache ca-certificates

COPY rootfs /
WORKDIR /data
```

**Determine what to copy:**

```bash
# List all files in upstream image
docker run --rm myapp/official:latest find / -type f | grep -v /proc | grep -v /sys

# Identify application-specific paths:
# - /usr/bin/myapp* → binaries
# - /etc/myapp/ → config files
# - /usr/local/myapp/ → application files
# - /usr/share/myapp/ → static assets
```

## Pattern 4: Multi-Service Applications

**Use when:** Application requires multiple services (app + database, app + cache).

**Example: Web App + Redis**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG REDIS_VERSION=7.2-alpine

# Stage 1: Application
FROM myapp/server:${BUILD_VERSION} AS app-source

# Stage 2: Redis
FROM redis:${REDIS_VERSION} AS redis-source

# Stage 3: Combine
FROM ${BUILD_FROM}

# Copy application
COPY --from=app-source /usr/local/bin/myapp /usr/bin/myapp
COPY --from=app-source /usr/local/lib/myapp/ /usr/lib/myapp/

# Copy Redis
COPY --from=redis-source /usr/local/bin/redis-server /usr/bin/redis-server
COPY --from=redis-source /usr/local/bin/redis-cli /usr/bin/redis-cli

# Install dependencies for both
RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    libcrypto3

# Copy S6 services (includes services for both app and redis)
COPY rootfs /

WORKDIR /data
```

**S6 service structure for multi-service:**

```
rootfs/etc/s6-overlay/s6-rc.d/
├── redis/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/base
├── myapp/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/
│       ├── base
│       └── redis
└── user/contents.d/
    ├── redis
    └── myapp
```

## Pattern 5: LinuxServer.io Images

**Challenge:** LinuxServer.io images have their own init system (s6-overlay v2).

**Recommended: Extract Binary Only**

```dockerfile
ARG BUILD_FROM
FROM linuxserver/plex:latest AS plex-source

FROM ${BUILD_FROM}

# Extract just the application, not their init
COPY --from=plex-source /usr/lib/plexmediaserver/ /usr/lib/plexmediaserver/

# Install dependencies (check what Plex needs)
RUN apk add --no-cache \
    libstdc++ \
    gcompat \
    ca-certificates

# Use HA's S6-overlay, not LinuxServer's
COPY rootfs /

WORKDIR /data
```

**Replicate their environment setup:**

```bash
# In your run script
#!/command/with-contenv bashio

# LinuxServer.io sets these
export PUID=0
export PGID=0
export TZ=$(bashio::config 'timezone')

# Create expected directories
mkdir -p /config /transcode

# Run application directly
exec /usr/lib/plexmediaserver/Plex\ Media\ Server
```

**Not Recommended: Layer S6 on top**

```dockerfile
# Don't do this - causes init system conflicts
FROM linuxserver/plex:latest

# Trying to add another S6-overlay layer
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
```

## Pattern 6: Architecture-Specific Builds

**Use when:** Upstream image has different binaries for different architectures.

**Strategy 1: Platform-Aware FROM**

Docker automatically selects the right architecture:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Docker automatically pulls the right arch
FROM grafana/loki:${BUILD_VERSION} AS loki-source

FROM ${BUILD_FROM}

# Binary location is the same across architectures
COPY --from=loki-source /usr/bin/loki /usr/bin/loki

COPY rootfs /
```

**Strategy 2: Conditional Logic**

When architectures require different handling:

```dockerfile
ARG BUILD_FROM
ARG BUILD_ARCH
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy binary
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Architecture-specific dependencies
RUN if [ "${BUILD_ARCH}" = "aarch64" ]; then \
      apk add --no-cache libatomic; \
    fi

COPY rootfs /
```

**Strategy 3: Different Source Tags**

When upstream uses different tags per architecture:

```dockerfile
ARG BUILD_FROM
ARG BUILD_ARCH
ARG BUILD_VERSION

# Map HA arch to upstream arch tags
FROM --platform=linux/${BUILD_ARCH} \
  myapp/official:${BUILD_VERSION}-${BUILD_ARCH} AS app-source

FROM ${BUILD_FROM}

COPY --from=app-source /usr/bin/myapp /usr/bin/myapp
COPY rootfs /
```

## Pattern 7: Additional Tools Integration

**Use when:** Application needs templating, monitoring, or helper tools.

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy application
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Install add-on tools
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    yq \
    gomplate \
    ca-certificates \
    tzdata

# Create directories
RUN mkdir -p /data/myapp /var/log/myapp

COPY rootfs /
WORKDIR /data
```

**Common additional tools:**
- `gomplate` - Template rendering (Go-based)
- `tempio` - Template rendering (Python-based, HA standard)
- `jq` - JSON processing
- `yq` - YAML processing
- `curl` - API calls and health checks
- `bash` - Advanced scripting
- `tzdata` - Timezone support

## User and Permission Handling

**Challenge:** Upstream image runs as specific user/UID, HA base runs as root.

**Solution: Create Matching User**

```dockerfile
ARG BUILD_FROM
FROM myapp/official:latest AS app-source

FROM ${BUILD_FROM}

# Check upstream user first (docker inspect or explore container)
# Suppose upstream uses uid=999, gid=999, name=myapp

# Create matching user in final image
RUN addgroup -g 999 myapp && \
    adduser -D -H -u 999 -G myapp -s /sbin/nologin myapp

# Copy application
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Set ownership
RUN chown -R myapp:myapp /data/myapp

COPY rootfs /
```

**Run script with user:**

```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting myapp as user myapp"

# Ensure ownership
chown -R myapp:myapp /data/myapp

# Run as myapp user
exec s6-setuidgid myapp /usr/bin/myapp
```

## Best Practices

### 1. Preserve Executable Permissions

```dockerfile
# Permissions are preserved in COPY
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# But verify and set explicitly if needed
RUN chmod +x /usr/bin/myapp
```

### 2. Minimal Dependencies

```dockerfile
# Install only what's needed
RUN apk add --no-cache \
    ca-certificates  # HTTPS support
    # Don't install: build tools, dev packages, docs
```

### 3. Layer Optimization

```dockerfile
# Combine RUN commands to reduce layers
RUN apk add --no-cache ca-certificates && \
    adduser -D -H myapp && \
    mkdir -p /data/myapp

# Instead of:
# RUN apk add --no-cache ca-certificates
# RUN adduser -D -H myapp
# RUN mkdir -p /data/myapp
```

### 4. Verify Extraction

```dockerfile
# After copying binary, test it
RUN /usr/bin/myapp --version || \
    (echo "Binary not working" && exit 1)
```

### 5. Document Source

```dockerfile
# Add labels to track upstream
LABEL \
  io.hass.upstream.image="grafana/loki" \
  io.hass.upstream.version="${BUILD_VERSION}" \
  io.hass.upstream.url="https://github.com/grafana/loki"
```

## Troubleshooting

### Binary Not Found

```dockerfile
# Symptom: /usr/bin/myapp: not found

# Check architecture match
RUN file /usr/bin/myapp
# Should show correct arch (x86-64, aarch64, etc.)

# Check if it's a script needing interpreter
RUN head -n 1 /usr/bin/myapp
# If #!/bin/bash, ensure bash is installed
```

### Missing Libraries

```dockerfile
# Symptom: error while loading shared libraries

# Identify missing libraries
RUN ldd /usr/bin/myapp
# Shows: libfoo.so.1 => not found

# Solution 1: Copy from source
COPY --from=app-source /usr/lib/libfoo.so* /usr/lib/

# Solution 2: Install from apk
RUN apk add --no-cache libfoo
```

### Permission Denied

```dockerfile
# Symptom: Permission denied when running binary

# Fix permissions
RUN chmod +x /usr/bin/myapp

# Or set ownership
RUN chown root:root /usr/bin/myapp && \
    chmod 755 /usr/bin/myapp
```

### Architecture Mismatch

```dockerfile
# Symptom: exec format error

# Check binary architecture
RUN file /usr/bin/myapp

# Ensure source stage uses correct arch
FROM --platform=linux/${BUILD_ARCH} \
  myapp/official:${BUILD_VERSION} AS app-source
```

## Complete Example: Prometheus

Full example wrapping Prometheus:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Extract from upstream
FROM prom/prometheus:v${BUILD_VERSION} AS prom-source

# Build on HA base
FROM ${BUILD_FROM}

# Copy Prometheus binaries
COPY --from=prom-source /bin/prometheus /usr/bin/prometheus
COPY --from=prom-source /bin/promtool /usr/bin/promtool

# Copy console templates
COPY --from=prom-source /usr/share/prometheus/console_libraries/ /usr/share/prometheus/console_libraries/
COPY --from=prom-source /usr/share/prometheus/consoles/ /usr/share/prometheus/consoles/

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate \
    bash

# Create prometheus user
RUN addgroup -g 65534 prometheus && \
    adduser -D -H -u 65534 -G prometheus -s /sbin/nologin prometheus

# Create data directories
RUN mkdir -p /data/prometheus && \
    chown -R prometheus:prometheus /data/prometheus

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.upstream.image="prom/prometheus" \
  io.hass.upstream.url="https://github.com/prometheus/prometheus"
```

This provides a solid foundation for wrapping any Docker image as a Home Assistant add-on.
