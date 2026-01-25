# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-25

### Added
- Initial release of Romm Home Assistant Add-on
- Embedded MariaDB for game library database
- Embedded Redis for caching and performance
- Romm 3.5.1 application with frontend and backend
- S6-Overlay service management for multi-process container
- Automatic database initialization on first run
- Secure credential generation (database password, auth secret)
- Support for multiple metadata providers:
  - IGDB (via Twitch API)
  - Screenscraper
  - SteamGridDB
  - RetroAchievements
  - MobyGames
- Scheduled library rescanning with cron configuration
- Configurable scan timeout
- Adjustable logging levels (DEBUG, INFO, WARNING, ERROR)
- Home Assistant Ingress support for seamless web UI access
- Direct port access option (8080/tcp)
- Health check monitoring for all services
- Multi-architecture support:
  - amd64 (x86-64)
  - aarch64 (ARM 64-bit)
  - armv7 (ARM 32-bit)
- Comprehensive documentation:
  - README with quick start guide
  - DOCS with detailed configuration and troubleshooting
  - Metadata provider setup instructions
- Persistent storage for:
  - Game library metadata
  - Downloaded resources and artwork
  - User uploads and save states
  - Database and cache

### Security
- Database and Redis bound to localhost only
- Auto-generated secure passwords
- No privileged container access required
- AppArmor enabled by default

### Notes
- First stable release
- Based on Romm 3.5.1
- Requires minimum 2GB RAM
- ROM library path: `/share/romm/library/roms/[platform]/`

---

## Release Process

### Version Numbering
- **Major (X.0.0):** Breaking changes, major Romm version updates
- **Minor (1.X.0):** New features, minor Romm updates, enhancements
- **Patch (1.0.X):** Bug fixes, security patches, documentation updates

### Planned Features (Future Releases)

#### Version 1.1.0
- [ ] External database support (optional)
- [ ] Advanced scanning options configuration
- [ ] Backup automation integration
- [ ] Performance optimizations for large libraries
- [ ] Additional metadata provider integrations

#### Version 1.2.0
- [ ] OIDC/OAuth integration with Home Assistant auth
- [ ] Enhanced monitoring and statistics
- [ ] Romm version update to 3.6.x

#### Version 2.0.0
- [ ] Multi-user setup wizard
- [ ] Hardware acceleration for game streaming
- [ ] Advanced emulator configuration options
- [ ] Plugin system support
