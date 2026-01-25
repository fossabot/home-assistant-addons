#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Romm
# Health check script
# ==============================================================================

# Check if MariaDB is running
if ! mysqladmin ping -h127.0.0.1 --silent 2>/dev/null; then
    bashio::log.error "Health check failed: MariaDB is not responding"
    exit 1
fi

# Check if Redis is running
if ! redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; then
    bashio::log.error "Health check failed: Redis is not responding"
    exit 1
fi

# Check if Romm web interface is responding
if ! curl -f -s http://localhost:8080/ > /dev/null 2>&1; then
    bashio::log.error "Health check failed: Romm web interface is not responding"
    exit 1
fi

bashio::log.debug "Health check passed"
exit 0
