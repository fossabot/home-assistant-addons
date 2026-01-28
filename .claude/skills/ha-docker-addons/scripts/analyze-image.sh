#!/usr/bin/env bash
# Analyze a Docker image for wrapping as Home Assistant add-on

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <image:tag>"
    echo "Example: $0 grafana/loki:3.6.4"
    exit 1
fi

IMAGE="$1"

echo "=== Analyzing Docker Image: ${IMAGE} ==="
echo

echo "--- Pulling image ---"
docker pull "${IMAGE}"
echo

echo "--- Image Configuration ---"
docker inspect "${IMAGE}" | jq '.[0].Config | {Env, ExposedPorts, Volumes, WorkingDir, User, Entrypoint, Cmd}'
echo

echo "--- Architecture ---"
docker inspect "${IMAGE}" | jq -r '.[0].Architecture'
echo

echo "--- Binaries (common locations) ---"
docker run --rm "${IMAGE}" sh -c 'ls -la /usr/bin/ /usr/local/bin/ 2>/dev/null | head -20' || true
echo

echo "--- Configuration Files ---"
docker run --rm "${IMAGE}" sh -c 'find /etc -maxdepth 2 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.conf" -o -name "*.toml" \) 2>/dev/null' || true
echo

echo "=== Analysis Complete ==="
echo "Next steps:"
echo "1. Identify the main binary location"
echo "2. Check required shared libraries with: docker run --rm ${IMAGE} ldd /path/to/binary"
echo "3. Review default configuration files"
echo "4. Plan port and volume mappings"
