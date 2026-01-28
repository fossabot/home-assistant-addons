# Configuration Mapping and Templating

Comprehensive guide for translating upstream Docker image configurations to Home Assistant add-on options and generating application configuration files.

## Understanding the Configuration Flow

```
User configures add-on in HA UI
  ↓
Options saved to /data/options.json
  ↓
Init script reads options via bashio
  ↓
Generate application config file
  ↓
Application starts with config file
```

## Port Configuration

**Critical:** Home Assistant has a specific pattern for port configuration.

### Main Port: Use config's `port` Property

The main application port should be defined in config.yaml at the root level, NOT in options:

```yaml
# config.yaml
port: 3100  # Main port at root level

ports:
  3100/tcp: 3100    # Map container port to host
  9095/tcp: null    # Additional ports

options:
  # Port is NOT here
  log_level: "info"
```

**Accessing main port in scripts:**

```bash
# Get main port from config property (not options)
MAIN_PORT=$(bashio::addon.port 3100)

# This works because port is defined in config.yaml 'port' property
```

### Additional Ports: Can Use Options

If the application has multiple configurable ports, additional ones can go in options:

```yaml
# config.yaml
port: 3100  # Main HTTP port

options:
  grpc_port: 9095  # Additional port in options

schema:
  grpc_port: port
```

**Accessing in scripts:**

```bash
# Main port from config property
HTTP_PORT=$(bashio::addon.port 3100)

# Additional port from options
GRPC_PORT=$(bashio::config 'grpc_port')
```

## Analyzing Upstream Configuration

Before mapping configuration, understand what the upstream image expects.

### Step 1: Check Upstream Documentation

Look for:
- Configuration file format (YAML, JSON, TOML, INI, XML)
- Environment variable support
- Command-line arguments
- Default values and required settings

### Step 2: Inspect the Image

```bash
# Check environment variables
docker inspect myapp/image:latest | jq '.[0].Config.Env'

# Check entrypoint and command
docker inspect myapp/image:latest | jq '.[0].Config.Entrypoint'
docker inspect myapp/image:latest | jq '.[0].Config.Cmd'
```

### Step 3: Run Upstream Container

```bash
# Start with shell
docker run --rm -it myapp/image:latest sh

# Look for default configs
find /etc -name "*.yaml" -o -name "*.conf" -o -name "*.toml"
cat /etc/myapp/config.yaml

# Check what application accepts
/usr/bin/myapp --help
```

### Step 4: Create Mapping Table

| Upstream Setting | Type | Format | Add-on Option | Notes |
|-----------------|------|--------|---------------|-------|
| `LOG_LEVEL` | env | string | `log_level` | Map to list |
| `HTTP_PORT` | env | int | config `port` | Use port property |
| `GRPC_PORT` | env | int | `grpc_port` | Optional in options |
| `DATA_DIR` | env | path | hardcoded | Always `/data` |
| `RETENTION_PERIOD` | config | duration | `retention_period` | e.g., "744h" |
| `ENABLE_API` | config | bool | `enable_api` | true/false |

## Configuration File Formats

### YAML Configuration

**Template: `rootfs/defaults/app-config.yaml.gotmpl`**

```yaml
server:
  host: {{ getenv "APP_HOST" "0.0.0.0" }}
  port: {{ getenv "APP_PORT" "8080" }}

logging:
  level: {{ getenv "APP_LOG_LEVEL" "info" }}
  format: {{ getenv "APP_LOG_FORMAT" "json" }}

database:
  type: {{ getenv "DB_TYPE" "sqlite" }}
{{- if eq (getenv "DB_TYPE") "sqlite" }}
  path: {{ getenv "DB_PATH" "/data/app.db" }}
{{- else }}
  host: {{ getenv "DB_HOST" }}
  port: {{ getenv "DB_PORT" }}
  username: {{ getenv "DB_USER" }}
  password: {{ getenv "DB_PASS" }}
  database: {{ getenv "DB_NAME" }}
{{- end }}

features:
  cache_enabled: {{ getenv "CACHE_ENABLED" "true" }}
  cache_ttl: {{ getenv "CACHE_TTL" "3600" }}

retention:
  period: {{ getenv "RETENTION_PERIOD" "30d" }}
  max_size: {{ getenv "RETENTION_MAX_SIZE" "10GB" }}
```

**Generation script:**

```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Generating configuration..."

# Set environment for gomplate
export APP_HOST="0.0.0.0"
export APP_PORT=$(bashio::addon.port 8080)
export APP_LOG_LEVEL=$(bashio::config 'log_level')
export APP_LOG_FORMAT="json"

# Database config
if bashio::config.has_value 'database.type'; then
  export DB_TYPE=$(bashio::config 'database.type')

  if [ "${DB_TYPE}" != "sqlite" ]; then
    export DB_HOST=$(bashio::config 'database.host')
    export DB_PORT=$(bashio::config 'database.port')
    export DB_USER=$(bashio::config 'database.user')
    export DB_PASS=$(bashio::config 'database.password')
    export DB_NAME=$(bashio::config 'database.name')
  fi
else
  export DB_TYPE="sqlite"
  export DB_PATH="/data/app.db"
fi

# Feature flags
export CACHE_ENABLED=$(bashio::config 'cache_enabled' 'true')
export CACHE_TTL=$(bashio::config 'cache_ttl' '3600')

# Retention
export RETENTION_PERIOD=$(bashio::config 'retention_period' '30d')
export RETENTION_MAX_SIZE=$(bashio::config 'retention_max_size' '10GB')

# Generate
gomplate \
  -f /defaults/app-config.yaml.gotmpl \
  -o /data/app-config.yaml

if [ $? -ne 0 ]; then
  bashio::log.error "Configuration generation failed"
  exit 1
fi

bashio::log.info "Configuration generated"
exit 0
```

### JSON Configuration

**Template: `rootfs/defaults/app-config.json.gotmpl`**

```json
{
  "server": {
    "host": "{{ getenv "APP_HOST" "0.0.0.0" }}",
    "port": {{ getenv "APP_PORT" "8080" }}
  },
  "logging": {
    "level": "{{ getenv "APP_LOG_LEVEL" "info" }}"
  },
  "database": {
    "connection_string": "{{ getenv "DB_CONNECTION" }}"
  },
  "features": {
    "caching": {{ getenv "ENABLE_CACHE" "true" }},
    "metrics": {{ getenv "ENABLE_METRICS" "false" }}
  }
}
```

**Note:** JSON doesn't allow trailing commas. Be careful with conditionals.

### TOML Configuration

**Template: `rootfs/defaults/app-config.toml.gotmpl`**

```toml
[server]
host = "{{ getenv "APP_HOST" "0.0.0.0" }}"
port = {{ getenv "APP_PORT" "8080" }}

[logging]
level = "{{ getenv "APP_LOG_LEVEL" "info" }}"
output = "{{ getenv "APP_LOG_OUTPUT" "stdout" }}"

[database]
type = "{{ getenv "DB_TYPE" "sqlite" }}"
{{- if eq (getenv "DB_TYPE") "sqlite" }}
path = "{{ getenv "DB_PATH" "/data/app.db" }}"
{{- else }}
host = "{{ getenv "DB_HOST" }}"
port = {{ getenv "DB_PORT" }}
{{- end }}

[features]
cache_enabled = {{ getenv "CACHE_ENABLED" "true" }}
metrics_enabled = {{ getenv "METRICS_ENABLED" "false" }}
```

### INI Configuration

**Template: `rootfs/defaults/app-config.ini.gotmpl`**

```ini
[server]
host = {{ getenv "APP_HOST" "0.0.0.0" }}
port = {{ getenv "APP_PORT" "8080" }}

[logging]
level = {{ getenv "APP_LOG_LEVEL" "info" }}

[database]
type = {{ getenv "DB_TYPE" "sqlite" }}
{{- if eq (getenv "DB_TYPE") "sqlite" }}
path = {{ getenv "DB_PATH" "/data/app.db" }}
{{- else }}
host = {{ getenv "DB_HOST" }}
port = {{ getenv "DB_PORT" }}
{{- end }}

[features]
cache = {{ getenv "CACHE_ENABLED" "true" }}
```

## Gomplate Functions

### Environment Variables

```gotmpl
{{ getenv "VAR_NAME" }}            # Get env var, fail if not set
{{ getenv "VAR_NAME" "default" }}  # Get env var, use default if not set
```

### Conditionals

```gotmpl
{{- if eq (getenv "TYPE") "postgres" }}
Use PostgreSQL
{{- else if eq (getenv "TYPE") "mysql" }}
Use MySQL
{{- else }}
Use SQLite
{{- end }}
```

### String Manipulation

```gotmpl
{{ getenv "DB_PASS" | strings.Quote }}      # Quote string
{{ getenv "NAME" | strings.ToUpper }}       # Uppercase
{{ getenv "PATH" | strings.TrimSpace }}     # Trim whitespace
```

### Collections

```gotmpl
{{- range (getenv "HOSTS" | strings.Split ",") }}
  - {{ . }}
{{- end }}
```

### File Operations

```gotmpl
{{ file.Read "/etc/secret.key" }}           # Read file
{{ file.Exists "/data/config.yaml" }}       # Check existence
```

## Configuration Without Templates

For simple cases, generate configuration directly in bash.

### Using Heredoc

```bash
#!/command/with-contenv bashio

LOG_LEVEL=$(bashio::config 'log_level')
PORT=$(bashio::addon.port 8080)
DATA_DIR="/data/myapp"

cat > /data/app-config.yaml <<EOF
server:
  host: 0.0.0.0
  port: ${PORT}

logging:
  level: ${LOG_LEVEL}

storage:
  path: ${DATA_DIR}
EOF

bashio::log.info "Configuration generated"
```

### Using yq to Modify Existing Config

```bash
#!/command/with-contenv bashio

# Copy default config
cp /defaults/app-config.yaml /data/app-config.yaml

# Modify with yq
LOG_LEVEL=$(bashio::config 'log_level')
yq eval ".logging.level = \"${LOG_LEVEL}\"" -i /data/app-config.yaml

PORT=$(bashio::addon.port 8080)
yq eval ".server.port = ${PORT}" -i /data/app-config.yaml

bashio::log.info "Configuration patched"
```

## Environment Variable Mapping

### Strategy 1: Export Before Execution

```bash
#!/command/with-contenv bashio

# Map add-on options to upstream environment variables
export MYAPP_LOG_LEVEL=$(bashio::config 'log_level')
export MYAPP_HTTP_PORT=$(bashio::addon.port 8080)
export MYAPP_DATA_DIR="/data/myapp"

# Application reads from environment
exec /usr/bin/myapp
```

### Strategy 2: Pass as Arguments

```bash
#!/command/with-contenv bashio

LOG_LEVEL=$(bashio::config 'log_level')
PORT=$(bashio::addon.port 8080)

exec /usr/bin/myapp \
  --log-level="${LOG_LEVEL}" \
  --port="${PORT}" \
  --data-dir="/data/myapp"
```

### Strategy 3: Generate .env File

```bash
#!/command/with-contenv bashio
# File: init-config/up

cat > /data/myapp/.env <<EOF
LOG_LEVEL=$(bashio::config 'log_level')
PORT=$(bashio::addon.port 8080)
DATA_DIR=/data/myapp
DATABASE_URL=$(bashio::config 'database_url')
API_KEY=$(bashio::config 'api_key')
EOF

bashio::log.info "Environment file generated"
```

**Load in run script:**

```bash
#!/command/with-contenv bashio

# Load environment
set -a
source /data/myapp/.env
set +a

exec /usr/bin/myapp
```

## Volume and Path Mapping

### Home Assistant Add-on Paths

```
/data         # Persistent add-on data (always available)
/config       # Home Assistant config (if mapped)
/share        # Shared directory (if mapped)
/ssl          # SSL certificates (if mapped)
/backup       # Backup location (if mapped)
/media        # Media directory (if mapped)
```

### Mapping in config.yaml

```yaml
map:
  - type: addon_config      # Maps to /data
    read_only: false
  - type: config            # Maps to /config
    read_only: true
  - type: share             # Maps to /share
    read_only: false
  - type: ssl               # Maps to /ssl
    read_only: true
```

### Using Paths in Configuration

```bash
# Always prefer /data for add-on files
DATA_DIR="/data/myapp"

# Use /share for cross-add-on sharing
EXPORT_DIR="/share/myapp-exports"

# Use /config only for reading HA config
HA_CONFIG="/config/configuration.yaml"
```

## Secret Handling

### Pattern 1: Home Assistant Secrets

**User's configuration:**

```yaml
# Add-on options
api_key: !secret myapp_api_key
database_password: !secret myapp_db_pass
```

**User's secrets.yaml:**

```yaml
myapp_api_key: "super-secret-key-12345"
myapp_db_pass: "database-password-67890"
```

**Read in script:**

```bash
#!/command/with-contenv bashio

API_KEY=$(bashio::config 'api_key')
DB_PASS=$(bashio::config 'database_password')

if [ -z "${API_KEY}" ]; then
  bashio::log.error "API key is required"
  exit 1
fi

# Use secrets
export MYAPP_API_KEY="${API_KEY}"
export MYAPP_DB_PASS="${DB_PASS}"

exec /usr/bin/myapp
```

### Pattern 2: Generate on First Run

```bash
#!/command/with-contenv bashio

SECRET_FILE="/data/secret.key"

if [ ! -f "${SECRET_FILE}" ]; then
  bashio::log.info "Generating secret key..."

  # Generate random secret
  openssl rand -hex 32 > "${SECRET_FILE}"
  chmod 600 "${SECRET_FILE}"

  bashio::log.info "Secret key generated"
fi

SECRET=$(cat "${SECRET_FILE}")
export MYAPP_SECRET="${SECRET}"

exec /usr/bin/myapp
```

### Pattern 3: External Secret Fetch

```bash
#!/command/with-contenv bashio

# Check if secret is in config
SECRET=$(bashio::config 'secret' '')

if [ -z "${SECRET}" ]; then
  # Try to fetch from external source
  if bashio::config.has_value 'secret_url'; then
    SECRET_URL=$(bashio::config 'secret_url')
    SECRET=$(curl -s "${SECRET_URL}")
  fi
fi

if [ -z "${SECRET}" ]; then
  bashio::log.error "Secret is required"
  exit 1
fi

export MYAPP_SECRET="${SECRET}"
exec /usr/bin/myapp
```

## Configuration Validation

Always validate generated configuration before starting the application.

### Strategy 1: Application Built-in Validation

```bash
#!/command/with-contenv bashio
# File: init-config/up

# Generate configuration
gomplate \
  -f /defaults/app-config.yaml.gotmpl \
  -o /data/app-config.yaml

# Validate using application
if ! /usr/bin/myapp validate-config /data/app-config.yaml; then
  bashio::log.error "Invalid configuration generated"
  cat /data/app-config.yaml  # Show for debugging
  exit 1
fi

bashio::log.info "Configuration validated"
exit 0
```

### Strategy 2: YAML/JSON Validation

```bash
#!/command/with-contenv bashio

# Generate YAML
gomplate \
  -f /defaults/app-config.yaml.gotmpl \
  -o /data/app-config.yaml

# Validate YAML syntax
if ! yq eval /data/app-config.yaml >/dev/null 2>&1; then
  bashio::log.error "Generated invalid YAML"
  cat /data/app-config.yaml
  exit 1
fi

bashio::log.info "YAML syntax valid"
```

```bash
# For JSON
if ! jq . /data/app-config.json >/dev/null 2>&1; then
  bashio::log.error "Generated invalid JSON"
  cat /data/app-config.json
  exit 1
fi
```

### Strategy 3: Schema Validation

```bash
#!/command/with-contenv bashio

# Generate config
gomplate \
  -f /defaults/app-config.yaml.gotmpl \
  -o /data/app-config.yaml

# Validate against JSON schema
if ! ajv validate \
    -s /defaults/config-schema.json \
    -d /data/app-config.yaml; then
  bashio::log.error "Configuration doesn't match schema"
  exit 1
fi

bashio::log.info "Configuration validated against schema"
```

## Dynamic Configuration Updates

### Strategy 1: Restart Required (Simplest)

Document in DOCS.md that configuration changes require add-on restart.

```markdown
## Configuration Changes

After changing add-on options, restart the add-on for changes to take effect.
```

### Strategy 2: Signal-Based Reload

If application supports SIGHUP or similar reload signal:

```bash
#!/command/with-contenv bashio
# File: config-watcher (separate service)

exec 2>&1

OPTIONS_FILE="/data/options.json"
LAST_MODIFIED=$(stat -c %Y "${OPTIONS_FILE}")

while true; do
  sleep 10

  CURRENT_MODIFIED=$(stat -c %Y "${OPTIONS_FILE}")

  if [ "${CURRENT_MODIFIED}" != "${LAST_MODIFIED}" ]; then
    bashio::log.info "Configuration changed, reloading..."

    # Regenerate config
    /etc/s6-overlay/scripts/generate-config.sh

    # Send reload signal
    pkill -SIGHUP myapp

    LAST_MODIFIED="${CURRENT_MODIFIED}"
  fi
done
```

### Strategy 3: API-Based Reload

If application has reload API endpoint:

```bash
#!/command/with-contenv bashio
# File: config-watcher

exec 2>&1

OPTIONS_FILE="/data/options.json"
LAST_MODIFIED=$(stat -c %Y "${OPTIONS_FILE}")

while true; do
  sleep 10

  CURRENT_MODIFIED=$(stat -c %Y "${OPTIONS_FILE}")

  if [ "${CURRENT_MODIFIED}" != "${LAST_MODIFIED}" ]; then
    bashio::log.info "Configuration changed, reloading..."

    # Regenerate config
    /etc/s6-overlay/scripts/generate-config.sh

    # Call reload API
    curl -X POST http://localhost:8080/api/reload

    LAST_MODIFIED="${CURRENT_MODIFIED}"
  fi
done
```

## Complete Example: Grafana Loki

Full configuration mapping for Grafana Loki.

**config.yaml:**

```yaml
port: 3100  # Main port (not in options)

options:
  log_level: "info"
  retention_period: "744h"
  grpc_port: 9095

schema:
  log_level: list(debug|info|warn|error)
  retention_period: str
  grpc_port: port
```

**Template: `rootfs/defaults/loki-config.yaml.gotmpl`:**

```yaml
auth_enabled: false

server:
  http_listen_port: {{ getenv "LOKI_HTTP_PORT" "3100" }}
  grpc_listen_port: {{ getenv "LOKI_GRPC_PORT" "9095" }}
  log_level: {{ getenv "LOKI_LOG_LEVEL" "info" }}

common:
  path_prefix: /data/loki
  storage:
    filesystem:
      chunks_directory: /data/loki/chunks
      rules_directory: /data/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: {{ getenv "LOKI_RETENTION" "744h" }}
```

**Generation script: `rootfs/etc/s6-overlay/s6-rc.d/init-config/up`:**

```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Generating Loki configuration..."

# Create directories
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

bashio::log.info "Configuration generated successfully"
exit 0
```

This comprehensive guide covers all aspects of configuration mapping and templating for wrapped Docker images.
