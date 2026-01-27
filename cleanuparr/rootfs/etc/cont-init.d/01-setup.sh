#!/usr/bin/with-contenv bashio
# =============================================================================
# Home Assistant Add-on: Cleanuparr
# Runs during container initialization to set up the environment
# =============================================================================

bashio::log.info "Setting up Cleanuparr..."

# =============================================================================
# Directory Setup
# =============================================================================

bashio::log.info "Creating data directories..."
mkdir -p /config/cleanuparr
mkdir -p /data/cleanuparr/logs

# Create symlinks for Cleanuparr to use /config directory
ln -sf /data/cleanuparr /config/cleanuparr

# =============================================================================
# Environment Variable Export
# =============================================================================

export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Get configuration values
LOG_LEVEL="$(bashio::config 'log_level')"
PORT="$(bashio::addon.port 11011/tcp)"

# Export environment variables for Cleanuparr
export_env LOG_LEVEL "${LOG_LEVEL}"
export_env PORT "${PORT}"

# Set default timezone
export_env TZ "$(bashio::info.timezone)"

# Set PUID and PGID (Home Assistant add-on runs as root by default)
export_env PUID "0"
export_env PGID "0"

# Export addon information
export_env ADDON_NAME "$(bashio::addon.name)"
export_env ADDON_IP "$(bashio::addon.ip_address)"

bashio::log.info "Setup complete"
