# Simple Wrapper Example Documentation

## About

This is a complete working example of wrapping a Docker image as a Home Assistant add-on.

**Note:** This example uses Alpine's busybox as a placeholder. In a real add-on, replace this with your actual application.

## What This Example Demonstrates

1. **Multi-stage Dockerfile**
   - Stage 1: Extract from upstream image
   - Stage 2: Build on Home Assistant base
   - BUILD_VERSION automatically from config.yaml

2. **Proper Port Configuration**
   - Main port uses config's `port` property
   - Accessed via `bashio::addon.port 8080`
   - NOT in options

3. **S6-Overlay Services**
   - `init-config`: Generate configuration (oneshot)
   - `myapp`: Run application (longrun)
   - Proper dependency chain: base → init-config → myapp

4. **Configuration Templating**
   - Gomplate template in `rootfs/defaults/`
   - Environment variables from add-on options
   - Generated to `/data/myapp-config.yaml`

5. **Complete Service Scripts**
   - Use `exec` in run scripts
   - Proper finish script for exit handling
   - Logging via bashio

## Configuration

### Option: `log_level`

Set logging verbosity.

**Options**: debug, info, warn, error  
**Default**: info

### Option: `data_retention`

How long to keep data.

**Format**: Duration string (e.g., "7d", "24h", "30d")  
**Default**: 7d

## File Structure

```
simple-wrapper/
├── Dockerfile                          # Multi-stage build
├── config.yaml                         # Add-on configuration
├── build.yaml                          # Build configuration
├── apparmor.txt                        # Security profile
├── DOCS.md                             # This file
├── README.md                           # Overview
└── rootfs/
    ├── etc/s6-overlay/s6-rc.d/
    │   ├── init-config/
    │   │   ├── type                    # "oneshot"
    │   │   ├── up                      # Generate config script
    │   │   └── dependencies.d/base
    │   ├── myapp/
    │   │   ├── type                    # "longrun"
    │   │   ├── run                     # Main service script
    │   │   ├── finish                  # Exit handler
    │   │   └── dependencies.d/
    │   │       ├── base
    │   │       └── init-config
    │   └── user/contents.d/myapp
    └── defaults/
        └── app-config.yaml.gotmpl      # Configuration template
```

## How It Works

1. **Startup Sequence**
   ```
   S6-overlay starts
     ↓
   base bundle
     ↓
   init-config (oneshot)
     - Reads options from /data/options.json
     - Sets environment variables
     - Generates /data/myapp-config.yaml
     ↓
   myapp (longrun)
     - Verifies config exists
     - Starts application
     - Runs under S6 supervision
   ```

2. **Configuration Flow**
   ```
   User edits options in HA UI
     ↓
   Saved to /data/options.json
     ↓
   init-config reads via bashio
     ↓
   Template processed with gomplate
     ↓
   /data/myapp-config.yaml created
     ↓
   Application starts with config
   ```

3. **Port Access Pattern**
   ```yaml
   # config.yaml
   port: 8080  # At root level
   ```
   
   ```bash
   # In scripts
   PORT=$(bashio::addon.port 8080)  # From config property
   ```

## Adapting for Your Application

1. **Replace upstream image in Dockerfile**
   ```dockerfile
   FROM yourapp/image:${BUILD_VERSION} AS app-source
   ```

2. **Copy correct binaries**
   ```dockerfile
   COPY --from=app-source /usr/bin/yourapp /usr/bin/yourapp
   ```

3. **Update config.yaml**
   - Set correct version
   - Update port
   - Add your options

4. **Modify configuration template**
   - Match your app's config format
   - Add required settings

5. **Update run script**
   - Use your actual binary
   - Pass correct arguments

## Testing Locally

```bash
# Build image
docker build \
  --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:latest" \
  --build-arg BUILD_ARCH="amd64" \
  --build-arg BUILD_VERSION="3.19" \
  -t local/simple-wrapper:test \
  .

# Create test data
mkdir -p /tmp/addon-test
cat > /tmp/addon-test/options.json <<EOF
{
  "log_level": "debug",
  "data_retention": "7d"
}
EOF

# Run container
docker run --rm -it \
  -v /tmp/addon-test:/data \
  -p 8080:8080 \
  local/simple-wrapper:test
```

## Key Patterns Demonstrated

✅ **BUILD_VERSION from config.yaml**  
✅ **Port in config property, not options**  
✅ **S6-overlay oneshot → longrun pattern**  
✅ **Configuration templating with gomplate**  
✅ **Proper exec in run scripts**  
✅ **Error handling in finish scripts**  
✅ **Bashio for reading options**  

Use this as a template for wrapping any Docker image!
