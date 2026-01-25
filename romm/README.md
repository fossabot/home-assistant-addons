# Home Assistant Add-on: Romm - ROM Manager

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armv7 Architecture][armv7-shield]

Beautiful, powerful, self-hosted ROM manager for your retro gaming collection.

## About

Romm is a comprehensive ROM manager that allows you to scan, organize, and play your retro game collections through a beautiful web interface. With support for 400+ gaming platforms, automatic metadata fetching, and browser-based emulation, Romm makes managing your retro gaming library effortless.

**Key Features:**
- 🎮 **400+ Platforms** - From Atari 2600 to Nintendo Switch
- 🖼️ **Rich Metadata** - Automatic artwork and game information from IGDB, Screenscraper, SteamGridDB, and more
- 🕹️ **Browser Emulation** - Play games directly in your browser with EmulatorJS and RuffleRS
- 👥 **Multi-User** - User management with individual libraries and sharing capabilities
- 🏆 **Achievements** - RetroAchievements integration for supported platforms
- 📱 **Responsive UI** - Beautiful interface that works on desktop, tablet, and mobile

## Installation

1. Navigate to the **Add-on Store** in your Home Assistant instance
2. Add this repository if not already added
3. Find "Romm - ROM Manager" and click "Install"
4. Start the add-on and check the logs for any errors
5. Click "Open Web UI" or access via the sidebar panel

## Quick Start

1. Place your ROMs in `/share/romm/library/roms/[platform]/`
   - Example: `/share/romm/library/roms/n64/Super Mario 64.z64`
2. Configure metadata providers (optional but recommended)
3. Open the Romm web interface
4. Complete the initial setup wizard
5. Scan your library to import games

## Configuration

The add-on supports optional metadata providers for enhanced game information:

- **IGDB** - Comprehensive game database (requires free Twitch developer account)
- **Screenscraper** - Extensive metadata with multiple languages
- **SteamGridDB** - High-quality game artwork
- **RetroAchievements** - Achievement tracking
- **MobyGames** - Classic game database

See the [full documentation](DOCS.md) for detailed setup instructions.

## Support

For issues and feature requests, please visit:
- [Romm GitHub](https://github.com/rommapp/romm)
- [Home Assistant Community](https://community.home-assistant.io/)

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
