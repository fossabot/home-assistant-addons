#!/usr/bin/env bash
# Scaffold a new Home Assistant add-on structure for wrapping Docker images

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <addon-name> <upstream-image>"
    echo "Example: $0 loki grafana/loki"
    exit 1
fi

ADDON_NAME="$1"
UPSTREAM_IMAGE="$2"

echo "Creating add-on structure for: ${ADDON_NAME}"
echo "Upstream image: ${UPSTREAM_IMAGE}"
echo

# Create directory structure
mkdir -p "${ADDON_NAME}"/{rootfs/etc/s6-overlay/s6-rc.d,rootfs/defaults,translations}

# Create S6 service structure
mkdir -p "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/{init-config,${ADDON_NAME},user/contents.d}
mkdir -p "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/{init-config,${ADDON_NAME}}/dependencies.d

# Create service type files
echo "oneshot" > "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/init-config/type
echo "longrun" > "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/${ADDON_NAME}/type

# Create empty dependency files
touch "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d/base
touch "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/${ADDON_NAME}/dependencies.d/base
touch "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/${ADDON_NAME}/dependencies.d/init-config
touch "${ADDON_NAME}"/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/${ADDON_NAME}

echo "✓ Created S6-overlay structure"

# Create placeholder files
cat > "${ADDON_NAME}"/config.yaml << EOF
name: "${ADDON_NAME^}"
version: "1.0.0"  # docker:UPSTREAM_IMAGE_HERE  # Update with actual upstream image
slug: "${ADDON_NAME}"
description: "Home Assistant add-on for ${UPSTREAM_IMAGE}"

arch:
  - aarch64
  - amd64

init: false
startup: services
boot: auto

port: 8080
ports:
  8080/tcp: 8080

map:
  - type: addon_config
    read_only: false

options:
  log_level: "info"

schema:
  log_level: list(debug|info|warn|error)

apparmor: true
EOF
echo "✓ Created config.yaml"

cat > "${ADDON_NAME}"/build.yaml << EOF
build_from:
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.23"
  amd64: "ghcr.io/home-assistant/amd64-base:3.23"

labels:
  org.opencontainers.image.title: "Home Assistant Add-on: ${ADDON_NAME^}"
  io.hass.upstream.image: "${UPSTREAM_IMAGE}"
EOF
echo "✓ Created build.yaml"

cat > "${ADDON_NAME}"/Dockerfile << EOF
ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${UPSTREAM_IMAGE}:\${BUILD_VERSION} AS app-source

FROM \${BUILD_FROM}

# TODO: Copy application binary and dependencies
# COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# TODO: Install runtime dependencies
# RUN apk add --no-cache ca-certificates gomplate

COPY rootfs /

WORKDIR /data

LABEL io.hass.version="\${BUILD_VERSION}" io.hass.type="addon" io.hass.arch="\${BUILD_ARCH}"
EOF
echo "✓ Created Dockerfile"

cat > "${ADDON_NAME}"/DOCS.md << EOF
# ${ADDON_NAME^} Add-on Documentation

## About

This add-on wraps the ${UPSTREAM_IMAGE} Docker image for Home Assistant.

## Installation

1. Add this repository to Home Assistant
2. Install "${ADDON_NAME^}" from the add-on store
3. Configure options
4. Start the add-on

## Configuration

### Option: \`log_level\`

Set logging verbosity.

**Options**: debug, info, warn, error  
**Default**: info

## Usage

Access the application at http://homeassistant.local:8080

## Support

Report issues at: [your-repo-url]
EOF
echo "✓ Created DOCS.md"

cat > "${ADDON_NAME}"/README.md << EOF
# Home Assistant Add-on: ${ADDON_NAME^}

Wraps ${UPSTREAM_IMAGE} as a Home Assistant add-on.

## Installation

Add this repository to Home Assistant and install the ${ADDON_NAME^} add-on.

## Configuration

See DOCS.md for detailed configuration options.
EOF
echo "✓ Created README.md"

cat > "${ADDON_NAME}"/CHANGELOG.md << EOF
# Changelog

## [1.0.0] - $(date +%Y-%m-%d)

### Added
- Initial release
- Wrapped ${UPSTREAM_IMAGE}
EOF
echo "✓ Created CHANGELOG.md"

echo
echo "=== Add-on structure created successfully! ==="
echo
echo "Next steps:"
echo "1. Analyze upstream image: ./scripts/analyze-image.sh ${UPSTREAM_IMAGE}:version"
echo "2. Edit Dockerfile to copy correct binaries"
echo "3. Create S6 service scripts in rootfs/etc/s6-overlay/s6-rc.d/${ADDON_NAME}/"
echo "4. Create configuration template in rootfs/defaults/"
echo "5. Update config.yaml with correct version and options"
