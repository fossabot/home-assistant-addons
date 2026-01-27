# Romm - ROM Collection Manager

Self-hosted ROM collection manager and emulator launcher for Home Assistant.

## About

Romm (ROM Manager) is a self-hosted web-based ROM collection manager and emulator launcher. It allows you to scan, organize, and manage game collections across 400+ platforms with automatic metadata fetching from multiple sources and in-browser gameplay.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the Romm add-on
3. Configure the add-on (see Configuration section below)
4. Start the add-on
5. Access via `http://YOUR_HA_IP:5999` (replace YOUR_HA_IP with your Home Assistant IP address)

## Network Access

This add-on exposes a web interface on **port 5999** (fixed). The interface is accessible from your local network.

**Security Recommendations:**
- Do NOT expose this port directly to the internet
- Use a reverse proxy with authentication if external access is needed (Traefik, nginx Proxy Manager)
- Consider using Home Assistant authentication proxy add-ons (Authelia, etc.)
- Ensure your Home Assistant instance is on a trusted network
- Use firewall rules or VLAN isolation to restrict access

## Configuration

See the [documentation](DOCS.md) for detailed configuration instructions.

### Required Settings

- Database host, user, and password (MariaDB/MySQL)
- Auth secret key (generate with `openssl rand -hex 32`)

### Optional Settings

- Metadata provider API keys (ScreenScraper, RetroAchievements, SteamGridDB, IGDB)
- Custom library path (default: /share/roms)

## Support

- [Documentation](DOCS.md)
- [Romm Official Docs](https://docs.romm.app/)
- [Issue Tracker](https://github.com/bluemaex/home-assistant-addons/issues)
