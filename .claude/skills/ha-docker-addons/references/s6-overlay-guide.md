# S6-Overlay Integration Guide

Comprehensive guide for setting up S6-RC services to manage wrapped Docker applications in Home Assistant add-ons.

## S6-Overlay Basics

S6-overlay provides process supervision and init system capabilities. Home Assistant base images include S6-overlay v3, which uses S6-RC for service management.

**Key Concepts:**
- **longrun**: Long-running services (daemons, applications)
- **oneshot**: Run-once initialization tasks
- **dependencies**: Control startup order
- **user bundle**: Collection of services to start

## Basic Service Structure

Minimal structure for a single application:

```
rootfs/etc/s6-overlay/s6-rc.d/
├── init-config/              # Generate config files (oneshot)
│   ├── type
│   ├── up
│   └── dependencies.d/
│       └── base
├── myapp/                    # Main application (longrun)
│   ├── type
│   ├── run
│   ├── finish
│   └── dependencies.d/
│       ├── base
│       └── init-config
└── user/
    └── contents.d/
        └── myapp
```

**Dependency flow:** `base → init-config → myapp → user`

## Service Types

### Longrun Services

Long-running processes that should be supervised and restarted if they die.

**File: `myapp/type`**
```
longrun
```

**File: `myapp/run`**
```bash
#!/command/with-contenv bashio

# Redirect stderr to stdout for logging
exec 2>&1

bashio::log.info "Starting application..."

# Get configuration
LOG_LEVEL=$(bashio::config 'log_level')
PORT=$(bashio::addon.port 8080)

# Run application (must use exec)
exec /usr/bin/myapp \
  --log-level="${LOG_LEVEL}" \
  --port="${PORT}" \
  --data-dir="/data/myapp"
```

**Critical:** Always use `exec` in run scripts. This replaces the shell process with the application, allowing S6 to manage it directly.

**File: `myapp/finish`**
```bash
#!/bin/sh

# Capture exit code
if [ "$1" -eq 256 ]; then
  # Killed by signal
  exit_code=$((128 + $2))
else
  exit_code="$1"
fi

# Write exit code for container
echo "${exit_code}" > /run/s6-linux-init-container-results/exitcode

# Log exit reason
if [ "${exit_code}" -ne 0 ]; then
  echo "[ERROR] Application exited with code ${exit_code}" >&2
fi

# Exit 0 = S6 will restart the service
# Exit 125 = S6 will not restart
exit 0
```

### Oneshot Services

Run once during startup, typically for initialization tasks.

**File: `init-config/type`**
```
oneshot
```

**File: `init-config/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Initializing configuration..."

# Create directories
mkdir -p /data/myapp/{data,cache,logs}

# Generate configuration
export APP_PORT=$(bashio::addon.port 8080)
export APP_LOG_LEVEL=$(bashio::config 'log_level')

gomplate \
  -f /defaults/config.yaml.gotmpl \
  -o /data/myapp/config.yaml

if [ $? -ne 0 ]; then
  bashio::log.error "Configuration generation failed"
  exit 1
fi

bashio::log.info "Configuration initialized"

# Oneshot must exit 0 to proceed
exit 0
```

**Key Points:**
- Must exit 0 to proceed to dependent services
- Non-zero exit stops the container
- No `exec` needed (script runs once and exits)

## Dependencies

Dependencies control the order in which services start.

**File: `myapp/dependencies.d/base`** (empty file)

Creates dependency: `myapp` depends on `base` (S6's base bundle)

**File: `myapp/dependencies.d/init-config`** (empty file)

Creates dependency: `myapp` depends on `init-config`

**Full dependency chain:**
```
base (S6 base)
  └── init-config (oneshot)
        └── myapp (longrun)
```

**Creating dependencies:**
```bash
# Create dependency directory
mkdir -p rootfs/etc/s6-overlay/s6-rc.d/myapp/dependencies.d/

# Create empty files for each dependency
touch rootfs/etc/s6-overlay/s6-rc.d/myapp/dependencies.d/base
touch rootfs/etc/s6-overlay/s6-rc.d/myapp/dependencies.d/init-config
```

## User Bundle

The `user` bundle is the top-level bundle that S6 starts. Add your services to it.

**File: `user/contents.d/myapp`** (empty file)

Adds `myapp` service to the user bundle.

**For multiple services:**
```bash
# Create user bundle entries
touch rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/redis
touch rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/myapp
touch rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/nginx
```

## Multi-Service Pattern

Example: Application + PostgreSQL database

**Directory structure:**
```
rootfs/etc/s6-overlay/s6-rc.d/
├── init-db/
│   ├── type: oneshot
│   ├── up
│   └── dependencies.d/base
├── postgres/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/
│       ├── base
│       └── init-db
├── webapp/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/
│       ├── base
│       └── postgres
└── user/contents.d/
    ├── postgres
    └── webapp
```

**Dependency flow:** `base → init-db → postgres → webapp`

**File: `init-db/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

if [ ! -f /data/database/initialized ]; then
  bashio::log.info "Initializing PostgreSQL database..."

  # Initialize database
  /usr/bin/initdb -D /data/database

  # Mark as initialized
  touch /data/database/initialized

  bashio::log.info "Database initialized"
else
  bashio::log.info "Database already initialized"
fi

exit 0
```

**File: `postgres/run`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting PostgreSQL..."

# Run as postgres user
exec s6-setuidgid postgres \
  /usr/bin/postgres -D /data/database
```

**File: `webapp/run`**
```bash
#!/command/with-contenv bashio

exec 2>&1

# Wait for PostgreSQL to be ready
bashio::log.info "Waiting for database..."

while ! pg_isready -h localhost -p 5432 >/dev/null 2>&1; do
  sleep 1
done

bashio::log.info "Database ready, starting webapp..."

export DATABASE_URL="postgresql://localhost:5432/myapp"

exec /usr/bin/webapp
```

## Configuration Generation Pattern

Use oneshot services to generate configuration files before starting the main application.

**File: `init-config/type`**
```
oneshot
```

**File: `init-config/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Generating configuration..."

# Set environment variables for gomplate
export APP_HOST="0.0.0.0"
export APP_PORT=$(bashio::addon.port 8080)
export APP_LOG_LEVEL=$(bashio::config 'log_level')
export APP_DATA_DIR="/data/myapp"

# Database settings (if configured)
if bashio::config.has_value 'database.host'; then
  export DB_HOST=$(bashio::config 'database.host')
  export DB_PORT=$(bashio::config 'database.port')
  export DB_NAME=$(bashio::config 'database.name')
  export DB_USER=$(bashio::config 'database.user')
  export DB_PASS=$(bashio::config 'database.password')
fi

# Generate configuration from template
gomplate \
  -f /defaults/app-config.yaml.gotmpl \
  -o /data/myapp/config.yaml

if [ $? -ne 0 ]; then
  bashio::log.error "Configuration generation failed"
  exit 1
fi

# Validate configuration
if ! /usr/bin/myapp validate-config /data/myapp/config.yaml; then
  bashio::log.error "Invalid configuration generated"
  exit 1
fi

bashio::log.info "Configuration generated successfully"

exit 0
```

## Wait for Service Pattern

When a service needs to wait for another service to be fully ready (not just started).

**File: `wait-redis/type`**
```
oneshot
```

**File: `wait-redis/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Waiting for Redis..."

timeout=30

while ! redis-cli -h localhost -p 6379 ping >/dev/null 2>&1; do
  timeout=$((timeout - 1))

  if [ $timeout -le 0 ]; then
    bashio::log.error "Redis did not become ready in time"
    exit 1
  fi

  sleep 1
done

bashio::log.info "Redis is ready"

exit 0
```

**Service dependencies:**
```
base → redis → wait-redis → myapp
```

## Logging Strategies

### Strategy 1: Stdout/Stderr (Recommended)

Application logs to stdout/stderr, S6 captures it.

```bash
#!/command/with-contenv bashio

# Redirect stderr to stdout
exec 2>&1

bashio::log.info "Starting application..."

# Application logs to stdout
exec /usr/bin/myapp
```

**Pros:** Simple, standard, works with HA logs
**Cons:** No log rotation, limited control

### Strategy 2: File Logging with Tail

Application logs to file, tail it to stdout.

```bash
#!/command/with-contenv bashio

exec 2>&1

# Create log file
mkdir -p /data/logs
touch /data/logs/app.log

# Start application (logs to file)
/usr/bin/myapp --log-file=/data/logs/app.log &

# Tail log file to stdout
exec tail -f /data/logs/app.log
```

**Pros:** Logs persist in /data
**Cons:** More complex, process management trickier

### Strategy 3: Named Pipe

Application logs to a named pipe, which is read as stdout.

```bash
#!/command/with-contenv bashio

exec 2>&1

# Create named pipe
mkfifo /tmp/app-log-pipe

# Start application (logs to pipe)
/usr/bin/myapp --log-file=/tmp/app-log-pipe &

# Read from pipe (becomes stdout)
exec cat /tmp/app-log-pipe
```

**Pros:** Clean, no file accumulation
**Cons:** Complex setup

### Strategy 4: S6-Log Service

Use S6's logging infrastructure (advanced).

**Directory structure:**
```
rootfs/etc/s6-overlay/s6-rc.d/
├── myapp-log-prepare/
│   ├── type: oneshot
│   ├── up
│   └── dependencies.d/base
├── myapp/
│   ├── type: longrun
│   ├── run
│   ├── producer-for: myapp-log
│   └── dependencies.d/myapp-log-prepare
├── myapp-log/
│   ├── type: longrun
│   ├── run
│   ├── consumer-for: myapp
│   └── pipeline-name: myapp-pipeline
└── user/contents.d/myapp-pipeline
```

**File: `myapp-log-prepare/up`**
```bash
#!/command/execlineb -P

if { mkdir -p /var/log/myapp }
if { chown nobody:nogroup /var/log/myapp }
chmod 02755 /var/log/myapp
```

**File: `myapp-log/run`**
```bash
#!/bin/sh
exec logutil-service /var/log/myapp
```

## Environment Variable Management

### Pattern 1: Export in Run Script

```bash
#!/command/with-contenv bashio

exec 2>&1

# Set environment for application
export LOG_LEVEL=$(bashio::config 'log_level')
export PORT=$(bashio::addon.port 8080)
export DATA_DIR="/data/myapp"

# Application reads from environment
exec /usr/bin/myapp
```

### Pattern 2: Generate .env File

```bash
#!/command/with-contenv bashio
# File: init-config/up

# Generate .env file
cat > /data/myapp/.env <<EOF
LOG_LEVEL=$(bashio::config 'log_level')
PORT=$(bashio::addon.port 8080)
DATA_DIR=/data/myapp
DATABASE_URL=$(bashio::config 'database_url')
EOF

bashio::log.info "Environment file generated"
exit 0
```

**Run script loads it:**
```bash
#!/command/with-contenv bashio

exec 2>&1

# Load environment file
set -a
source /data/myapp/.env
set +a

exec /usr/bin/myapp
```

## Health Checks

### Internal Health Check

Monitor process and optionally perform health checks.

```bash
#!/command/with-contenv bashio

exec 2>&1

# Start application
/usr/bin/myapp &
APP_PID=$!

bashio::log.info "Application started with PID ${APP_PID}"

# Health check loop
while true; do
  # Check if process is alive
  if ! kill -0 ${APP_PID} 2>/dev/null; then
    bashio::log.error "Application process died"
    exit 1
  fi

  # Optional: HTTP health check
  if ! curl -f http://localhost:8080/health >/dev/null 2>&1; then
    bashio::log.warning "Health check failed"
  fi

  sleep 30
done
```

### Home Assistant Watchdog

Configure watchdog in config.yaml:

```yaml
# config.yaml
watchdog: "http://[HOST]:[PORT:8080]/health"
```

Home Assistant will periodically check this endpoint.

## Restart Policies

Control whether S6 restarts services when they exit.

**File: `myapp/finish`**
```bash
#!/bin/sh

# $1 = exit code (256 if killed by signal)
# $2 = signal number (if killed)

# Clean exit (0) - don't restart
if [ "$1" -eq 0 ]; then
  echo "0" > /run/s6-linux-init-container-results/exitcode
  /run/s6/basedir/bin/halt
fi

# SIGTERM (15) - normal shutdown, don't restart
if [ "$1" -eq 256 ] && [ "$2" -eq 15 ]; then
  echo "0" > /run/s6-linux-init-container-results/exitcode
  /run/s6/basedir/bin/halt
fi

# Any other exit - S6 will restart
# (Just exit 0 from finish script)
exit 0
```

## Permission Management

Run services as non-root users.

```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting application as user myapp..."

# Ensure ownership
chown -R myapp:myapp /data/myapp

# Run as myapp user
exec s6-setuidgid myapp /usr/bin/myapp \
  --data-dir=/data/myapp
```

## Debugging S6 Services

**List all services:**
```bash
s6-rc -l
```

**Check service status:**
```bash
s6-svstat /run/service/myapp
```

**Manually start service:**
```bash
s6-rc -u change myapp
```

**Manually stop service:**
```bash
s6-rc -d change myapp
```

**View service logs:**
```bash
s6-svstat /run/service/myapp
```

## Common Patterns

### Pattern: Database Initialization

```
base → init-db → database → wait-db → webapp
```

### Pattern: Multi-App with Shared Cache

```
base → init-config → redis → (app1, app2, app3)
```

### Pattern: Application + Monitoring

```
base → init-dirs → (app, prometheus-exporter, health-check)
```

## Complete Example: Grafana Loki

Full S6-overlay setup for Loki:

**Directory structure:**
```
rootfs/etc/s6-overlay/s6-rc.d/
├── init-config/
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── loki/
│   ├── type
│   ├── run
│   ├── finish
│   └── dependencies.d/
│       ├── base
│       └── init-config
└── user/contents.d/loki
```

**File: `init-config/type`**
```
oneshot
```

**File: `init-config/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Generating Loki configuration..."

# Create data directories
mkdir -p /data/loki/{chunks,rules}

# Set environment for gomplate
export LOKI_HTTP_PORT=$(bashio::addon.port 3100)
export LOKI_GRPC_PORT=$(bashio::config 'grpc_port')
export LOKI_LOG_LEVEL=$(bashio::config 'log_level')
export LOKI_RETENTION=$(bashio::config 'retention_period')

# Generate configuration
gomplate \
  -f /defaults/loki-config.yaml.gotmpl \
  -o /data/loki-config.yaml

if [ $? -ne 0 ]; then
  bashio::log.error "Configuration generation failed"
  exit 1
fi

bashio::log.info "Configuration generated"
exit 0
```

**File: `loki/type`**
```
longrun
```

**File: `loki/run`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting Grafana Loki..."

LOG_LEVEL=$(bashio::config 'log_level')
CONFIG_FILE="/data/loki-config.yaml"

if [ ! -f "${CONFIG_FILE}" ]; then
  bashio::log.error "Configuration not found"
  exit 1
fi

exec /usr/bin/loki \
  -config.file="${CONFIG_FILE}" \
  -log.level="${LOG_LEVEL}"
```

**File: `loki/finish`**
```bash
#!/bin/sh

if [ "$1" -eq 256 ]; then
  exit_code=$((128 + $2))
else
  exit_code="$1"
fi

echo "${exit_code}" > /run/s6-linux-init-container-results/exitcode

if [ "${exit_code}" -ne 0 ]; then
  echo "[ERROR] Loki exited with code ${exit_code}" >&2
fi

exit 0
```

**Dependencies:**
- `rootfs/etc/s6-overlay/s6-rc.d/loki/dependencies.d/base` (empty)
- `rootfs/etc/s6-overlay/s6-rc.d/loki/dependencies.d/init-config` (empty)
- `rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d/base` (empty)
- `rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/loki` (empty)

This provides complete S6-overlay service management for wrapped Docker applications.
