#!/usr/bin/with-contenv bashio

bashio::log.info "Setting up Romm configuration..."

# Validate required configuration
if ! bashio::config.has_value 'database.host'; then
    bashio::exit.nok "Database host is required!"
fi

if ! bashio::config.has_value 'database.password'; then
    bashio::exit.nok "Database password is required!"
fi

if ! bashio::config.has_value 'auth_secret_key'; then
    bashio::exit.nok "Auth secret key is required! Generate with: openssl rand -hex 32"
fi

# Create required directories with proper ownership
bashio::log.info "Creating data directories..."
mkdir -p /data/romm_resources
mkdir -p /data/redis_data
mkdir -p /data/romm_assets

# Get library path from config
LIBRARY_PATH="$(bashio::config 'library_path')"
if [ ! -d "$LIBRARY_PATH" ]; then
    bashio::log.warning "Library path ${LIBRARY_PATH} does not exist. Creating..."
    mkdir -p "$LIBRARY_PATH"
fi

# Export database configuration
export DB_HOST="$(bashio::config 'database.host')"
export DB_PORT="$(bashio::config 'database.port')"
export DB_NAME="$(bashio::config 'database.name')"
export DB_USER="$(bashio::config 'database.user')"
export DB_PASSWD="$(bashio::config 'database.password')"

# Export auth configuration
export ROMM_AUTH_SECRET_KEY="$(bashio::config 'auth_secret_key')"

# Export metadata provider credentials (optional)
if bashio::config.has_value 'metadata_providers.screenscraper_user'; then
    export SCREENSCRAPER_USER="$(bashio::config 'metadata_providers.screenscraper_user')"
fi
if bashio::config.has_value 'metadata_providers.screenscraper_password'; then
    export SCREENSCRAPER_PASSWORD="$(bashio::config 'metadata_providers.screenscraper_password')"
fi
if bashio::config.has_value 'metadata_providers.retroachievements_api_key'; then
    export RETROACHIEVEMENTS_API_KEY="$(bashio::config 'metadata_providers.retroachievements_api_key')"
fi
if bashio::config.has_value 'metadata_providers.steamgriddb_api_key'; then
    export STEAMGRIDDB_API_KEY="$(bashio::config 'metadata_providers.steamgriddb_api_key')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_id'; then
    export IGDB_CLIENT_ID="$(bashio::config 'metadata_providers.igdb_client_id')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_secret'; then
    export IGDB_CLIENT_SECRET="$(bashio::config 'metadata_providers.igdb_client_secret')"
fi
if bashio::config.has_value 'metadata_providers.mobygames_api_key'; then
    export MOBYGAMES_API_KEY="$(bashio::config 'metadata_providers.mobygames_api_key')"
fi

# Export provider flags
export HASHEOUS_API_ENABLED="$(bashio::config 'metadata_providers.hasheous_enabled')"
export PLAYMATCH_API_ENABLED="$(bashio::config 'metadata_providers.playmatch_enabled')"
export LAUNCHBOX_API_ENABLED="$(bashio::config 'metadata_providers.launchbox_enabled')"

# Export volume paths
export ROMM_RESOURCES_PATH="/data/romm_resources"
export REDIS_DATA_PATH="/data/redis_data"
export ROMM_LIBRARY_PATH="$(bashio::config 'library_path')"
export ROMM_ASSETS_PATH="/data/romm_assets"

# Export scheduled tasks configuration
export ENABLE_SCHEDULED_RESCAN="$(bashio::config 'scheduled_tasks.enable_rescan')"
export ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB="$(bashio::config 'scheduled_tasks.enable_switch_titledb')"
export ENABLE_SCHEDULED_UPDATE_LAUNCHBOX_METADATA="$(bashio::config 'scheduled_tasks.enable_launchbox_metadata')"
export ENABLE_SCHEDULED_CONVERT_IMAGES_TO_WEBP="$(bashio::config 'scheduled_tasks.enable_image_conversion')"
export ENABLE_SCHEDULED_RETROACHIEVEMENTS_PROGRESS_SYNC="$(bashio::config 'scheduled_tasks.enable_retroachievements_sync')"

# Export file watcher configuration
export ENABLE_RESCAN_ON_FILESYSTEM_CHANGE="$(bashio::config 'enable_file_watcher')"

# Export nginx configuration
export ROMM_PORT=$(bashio::addon.ingress_port)
export ROMM_BASE_PATH="/romm"

# Optional: config.yml path
if [ -f "/config/romm/config.yml" ]; then
    export ROMM_CONFIG_PATH="/config/romm/config.yml"
fi

# Set Python environment
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH=/backend

# Disable OpenTelemetry (not needed for HA add-on)
export OTEL_SDK_DISABLED=true

bashio::log.info "Romm initialization complete"
