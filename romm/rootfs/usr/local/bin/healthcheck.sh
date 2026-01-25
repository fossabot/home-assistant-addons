#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Romm
# Health check script
# ==============================================================================

# Check if Romm web interface is responding
if ! curl -f -s http://localhost:8080/ > /dev/null 2>&1; then
    bashio::log.error "Health check failed: Romm web interface is not responding"
    exit 1
fi

bashio::log.debug "Health check passed"
exit 0
