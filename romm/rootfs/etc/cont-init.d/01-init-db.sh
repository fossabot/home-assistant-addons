#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Romm
# Initializes database and generates secure credentials
# ==============================================================================

bashio::log.info "Initializing database configuration..."

# Generate database password if not set
if ! bashio::config.has_value 'db_password'; then
    bashio::log.info "Generating secure database password..."
    DB_PASS=$(openssl rand -hex 24)
    bashio::addon.option 'db_password' "${DB_PASS}"
else
    DB_PASS=$(bashio::config 'db_password')
fi

# Generate auth secret key if not set
if ! bashio::config.has_value 'auth_secret_key'; then
    bashio::log.info "Generating secure authentication secret..."
    AUTH_SECRET=$(openssl rand -hex 32)
    bashio::addon.option 'auth_secret_key' "${AUTH_SECRET}"
else
    AUTH_SECRET=$(bashio::config 'auth_secret_key')
fi

# Ensure MariaDB PID directory exists
mkdir -p /var/run/mysqld
chmod 755 /var/run/mysqld

# Start MariaDB temporarily for initialization
bashio::log.info "Starting MariaDB for initialization..."
mysqld --datadir=/data/mysql --user=root --bind-address=127.0.0.1 --skip-networking=0 &
MYSQL_PID=$!

# Wait for MariaDB to start
bashio::log.info "Waiting for MariaDB to start..."
for i in {1..30}; do
    if mysqladmin ping -h127.0.0.1 --silent 2>/dev/null; then
        bashio::log.info "MariaDB is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        bashio::log.error "MariaDB failed to start in time"
        exit 1
    fi
    sleep 2
done

# Create database and user
bashio::log.info "Setting up Romm database and user..."
mysql -h127.0.0.1 -uroot <<EOF
CREATE DATABASE IF NOT EXISTS romm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'romm'@'localhost' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS 'romm'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON romm.* TO 'romm'@'localhost';
GRANT ALL PRIVILEGES ON romm.* TO 'romm'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    bashio::log.info "Database setup completed successfully"
else
    bashio::log.error "Database setup failed"
    kill $MYSQL_PID
    exit 1
fi

# Stop temporary MariaDB instance
bashio::log.info "Stopping temporary MariaDB instance..."
mysqladmin -h127.0.0.1 -uroot shutdown
wait $MYSQL_PID

bashio::log.info "Database initialization complete"
