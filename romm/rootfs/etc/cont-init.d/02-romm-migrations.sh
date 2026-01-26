#!/usr/bin/with-contenv bashio

# Start Valkey in background for migrations
bashio::log.info "Starting Valkey for database migrations..."
valkey-server --dir /data/redis_data --daemonize yes --loglevel warning --pidfile /tmp/valkey-init.pid

# Wait for Valkey to be ready
bashio::log.info "Waiting for Valkey to be ready..."
for i in {1..30}; do
    if valkey-cli -h 127.0.0.1 -p 6379 ping >/dev/null 2>&1; then
        bashio::log.info "Valkey is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        bashio::exit.nok "Valkey failed to start after 30 seconds"
    fi
    sleep 1
done

bashio::log.info "Running database migrations..."
cd /backend || bashio::exit.nok "Failed to change to /backend directory"

if ! alembic upgrade head; then
    bashio::exit.nok "Database migrations failed"
fi

bashio::log.info "Running startup tasks..."
if ! python startup.py; then
    bashio::exit.nok "Startup tasks failed"
fi

bashio::log.info "Startup complete"
