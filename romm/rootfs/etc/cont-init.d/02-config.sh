#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Romm
# Prepares configuration and directories
# ==============================================================================

bashio::log.info "Preparing Romm directories..."

# Create necessary directories
mkdir -p /data/resources
mkdir -p /data/assets
mkdir -p /data/mysql
mkdir -p /data/redis
mkdir -p /data/config
mkdir -p /share/romm/library/roms

# Set permissions
chmod -R 755 /data/resources
chmod -R 755 /data/assets
chmod -R 755 /share/romm

# Check if library directory has proper structure
if [ ! -d "/share/romm/library/roms" ]; then
    bashio::log.warning "ROM library structure not found. Creating..."
    mkdir -p /share/romm/library/roms
    bashio::log.info "Created /share/romm/library/roms"
    bashio::log.info "Please place your ROMs in subdirectories by platform"
    bashio::log.info "Example: /share/romm/library/roms/n64/Super Mario 64.z64"
fi

# Display configuration summary
bashio::log.info "-----------------------------------------------------------"
bashio::log.info "Configuration Summary:"
bashio::log.info "-----------------------------------------------------------"

if bashio::config.has_value 'igdb_client_id'; then
    bashio::log.info "IGDB: Configured ✓"
else
    bashio::log.info "IGDB: Not configured"
fi

if bashio::config.has_value 'screenscraper_user'; then
    bashio::log.info "Screenscraper: Configured ✓"
else
    bashio::log.info "Screenscraper: Not configured"
fi

if bashio::config.has_value 'steamgriddb_api_key'; then
    bashio::log.info "SteamGridDB: Configured ✓"
else
    bashio::log.info "SteamGridDB: Not configured"
fi

if bashio::config.has_value 'retroachievements_api_key'; then
    bashio::log.info "RetroAchievements: Configured ✓"
else
    bashio::log.info "RetroAchievements: Not configured"
fi

if bashio::config.has_value 'mobygames_api_key'; then
    bashio::log.info "MobyGames: Configured ✓"
else
    bashio::log.info "MobyGames: Not configured"
fi

bashio::log.info "-----------------------------------------------------------"
bashio::log.info "Scheduled Rescan: $(bashio::config 'enable_scheduled_rescan')"
bashio::log.info "Log Level: $(bashio::config 'log_level')"
bashio::log.info "-----------------------------------------------------------"

bashio::log.info "Configuration setup complete"
