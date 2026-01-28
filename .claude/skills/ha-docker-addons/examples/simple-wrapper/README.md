# Simple Wrapper Example

Minimal example of wrapping a Docker image as a Home Assistant add-on.

This example shows the core structure without complexity.

## Structure

```
simple-wrapper/
├── Dockerfile              # Multi-stage build
├── config.yaml             # Add-on configuration
├── build.yaml              # Build configuration
└── rootfs/
    ├── etc/s6-overlay/s6-rc.d/
    │   ├── init-config/    # Generate config (oneshot)
    │   ├── myapp/          # Run application (longrun)
    │   └── user/contents.d/myapp
    └── defaults/
        └── app-config.yaml.gotmpl
```

## Key Files

### Dockerfile
- Stage 1: Extract from upstream image
- Stage 2: Build on HA base
- Copy only needed binaries
- Install runtime dependencies

### config.yaml
- Main port at root level (not in options)
- Options for user configuration
- Schema validation

### S6 Services
- init-config: Generate configuration (oneshot)
- myapp: Run application (longrun)
- Dependencies: base → init-config → myapp

## Usage

1. Copy this structure
2. Replace "myapp" with your application name
3. Update Dockerfile with correct upstream image
4. Modify config generation for your app
5. Test locally

See parent SKILL.md for detailed instructions.
