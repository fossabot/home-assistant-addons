#!/usr/bin/with-contenv bashio

bashio::log.info "Setting up Profilarr configuration..."

# Create data directories
bashio::log.info "Creating data directories..."
mkdir -p /data/config
mkdir -p /data/logs
mkdir -p /data/db

# Helper function to export environment variables for s6 services
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Export log level using export_env function
LOG_LEVEL="$(bashio::config 'log_level')"
export_env LOG_LEVEL "$LOG_LEVEL"

# Export timezone
TZ="$(bashio::config 'tz')"
export_env TZ "$TZ"

# Export ingress port for nginx
PROFILARR_PORT="6099"
export_env PROFILARR_PORT "$PROFILARR_PORT"

# Export Flask configuration
export_env FLASK_ENV "production"
export_env FLASK_APP "/profilarr/app/main.py"

# Set Python environment
export_env PYTHONUNBUFFERED 1
export_env PYTHONDONTWRITEBYTECODE 1
export_env PYTHONPATH /profilarr

bashio::log.info "Profilarr initialization complete"
