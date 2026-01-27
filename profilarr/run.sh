#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting Profilarr..."

# Export PYTHONPATH for all processes
export PYTHONPATH=/profilarr
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Start s6-overlay to manage services
exec /init
