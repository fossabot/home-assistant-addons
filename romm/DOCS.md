# Romm - ROM Manager Documentation

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [ROM Library Setup](#rom-library-setup)
4. [Metadata Providers](#metadata-providers)
5. [First Run Setup](#first-run-setup)
6. [Usage](#usage)
7. [Backup & Restore](#backup--restore)
8. [Troubleshooting](#troubleshooting)
9. [Architecture](#architecture)
10. [FAQ](#faq)

---

## Installation

### Prerequisites

- Home Assistant OS, Supervised, or Container installation
- Minimum 2GB RAM available
- 10GB+ free storage space (more for larger ROM collections)

### Installation Steps

1. **Add Repository** (if using custom repository)
   - Navigate to **Settings** → **Add-ons** → **Add-on Store**
   - Click the menu (⋮) → **Repositories**
   - Add the repository URL

2. **Install Add-on**
   - Find "Romm - ROM Manager" in the store
   - Click **Install**
   - Wait for installation to complete (may take several minutes)

3. **Start Add-on**
   - Go to the **Configuration** tab to set options (optional)
   - Click **Start**
   - Enable "Start on boot" and "Watchdog" for automatic startup

4. **Access Web Interface**
   - Click **Open Web UI** button
   - Or access from Home Assistant sidebar panel "Romm"

---

## Configuration

### Basic Configuration

The add-on works out-of-the-box with minimal configuration. All settings are optional but enhance functionality.

### Metadata Provider Configuration

#### IGDB (Recommended)

IGDB provides comprehensive game metadata including descriptions, release dates, and artwork.

**Setup:**
1. Create a Twitch account at https://www.twitch.tv
2. Register as a Twitch developer at https://dev.twitch.tv
3. Create a new application:
   - Name: "Romm Home Assistant"
   - OAuth Redirect URL: `http://localhost`
   - Category: "Application Integration"
4. Copy the **Client ID** and **Client Secret**
5. Add to add-on configuration:
   ```yaml
   igdb_client_id: "your_client_id_here"
   igdb_client_secret: "your_client_secret_here"
   ```

#### Screenscraper

Screenscraper offers extensive metadata in multiple languages with high-quality media.

**Setup:**
1. Register at https://www.screenscraper.fr
2. Verify your email address
3. Add to add-on configuration:
   ```yaml
   screenscraper_user: "your_username"
   screenscraper_password: "your_password"
   ```

**Note:** Free accounts have daily limits. Consider donating for unlimited access.

#### SteamGridDB

Provides high-quality game artwork, covers, and backgrounds.

**Setup:**
1. Create account at https://www.steamgriddb.com
2. Go to **Preferences** → **API**
3. Generate an API key
4. Add to add-on configuration:
   ```yaml
   steamgriddb_api_key: "your_api_key_here"
   ```

#### RetroAchievements

Enables achievement tracking for supported platforms.

**Setup:**
1. Register at https://retroachievements.org
2. Go to **Settings** → **Keys**
3. Generate a Web API Key
4. Add to add-on configuration:
   ```yaml
   retroachievements_api_key: "your_api_key_here"
   ```

#### MobyGames

Classic game database with extensive historical information.

**Setup:**
1. Create account at https://www.mobygames.com
2. Request API access (may take a few days)
3. Once approved, get your API key from account settings
4. Add to add-on configuration:
   ```yaml
   mobygames_api_key: "your_api_key_here"
   ```

### Advanced Configuration

#### Scheduled Scanning

Automatically rescan your library on a schedule:

```yaml
enable_scheduled_rescan: true
scheduled_rescan_cron: "0 3 * * *"  # 3 AM daily
```

**Cron Format:** `minute hour day month weekday`
- `0 3 * * *` - Daily at 3 AM
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly on Sunday at midnight

#### Scan Timeout

Maximum time (in seconds) for library scanning operations:

```yaml
scan_timeout: 14400  # 4 hours (default)
```

Increase for very large libraries or slow metadata providers.

#### Logging

Set log verbosity for troubleshooting:

```yaml
log_level: "INFO"  # DEBUG | INFO | WARNING | ERROR
```

---

## ROM Library Setup

### Directory Structure

ROMs must be placed in `/share/romm/library/roms/` organized by platform:

```
/share/romm/library/
└── roms/
    ├── n64/
    │   ├── Super Mario 64.z64
    │   └── The Legend of Zelda - Ocarina of Time.z64
    ├── ps1/
    │   ├── Final Fantasy VII/
    │   │   ├── disc1.bin
    │   │   ├── disc1.cue
    │   │   ├── disc2.bin
    │   │   └── disc2.cue
    │   └── Metal Gear Solid.chd
    ├── snes/
    │   ├── Super Mario World.sfc
    │   └── Super Metroid.sfc
    └── gba/
        ├── Pokemon FireRed.gba
        └── The Legend of Zelda - The Minish Cap.gba
```

### Platform Names

Use standard platform abbreviations for folder names:

| Platform | Folder Name | Example Extensions |
|----------|-------------|-------------------|
| Nintendo 64 | `n64` | `.z64`, `.n64`, `.v64` |
| PlayStation | `ps1` | `.bin`/`.cue`, `.chd`, `.pbp` |
| PlayStation 2 | `ps2` | `.iso`, `.chd` |
| Super Nintendo | `snes` | `.sfc`, `.smc` |
| Game Boy Advance | `gba` | `.gba` |
| GameCube | `gc` | `.iso`, `.gcm`, `.rvz` |
| Nintendo DS | `nds` | `.nds` |
| Sega Genesis | `genesis` | `.md`, `.bin` |
| Dreamcast | `dreamcast` | `.cdi`, `.gdi`, `.chd` |

For a complete list, refer to [Romm's platform documentation](https://github.com/rommapp/romm/wiki/Platforms).

### Multi-Disc Games

For games with multiple discs, create a folder containing all disc files:

```
/share/romm/library/roms/ps1/Final Fantasy VII/
├── disc1.bin
├── disc1.cue
├── disc2.bin
├── disc2.cue
├── disc3.bin
└── disc3.cue
```

### Accessing ROMs

**Option 1: SSH / Terminal**
```bash
mkdir -p /share/romm/library/roms/n64
cp /path/to/your/roms/*.z64 /share/romm/library/roms/n64/
```

**Option 2: Samba Share**
1. Install "Samba share" add-on
2. Access `\\homeassistant.local\share`
3. Navigate to `romm\library\roms`
4. Copy ROMs into appropriate platform folders

**Option 3: File Editor Add-on**
Use File Editor add-on to create directories and upload files directly through the web interface.

---

## First Run Setup

1. **Access Web Interface**
   - Click "Open Web UI" or use sidebar panel

2. **Create Admin Account**
   - First user is automatically admin
   - Choose a strong password

3. **Configure Metadata (Optional)**
   - Skip for now and configure in add-on settings later
   - Or enter API credentials directly in Romm settings

4. **Scan Library**
   - Click "Scan Library" button
   - Wait for initial scan to complete
   - Metadata will be fetched for identified games

---

## Usage

### Scanning for Games

1. Navigate to **Library** in Romm
2. Click **Scan** button
3. Wait for scan to complete
4. Games will appear with fetched metadata

### Playing Games

1. Click on a game in your library
2. Click **Play** button
3. Game loads in browser-based emulator (EmulatorJS)
4. Use keyboard or connect a gamepad

**Default Controls:**
- Arrow Keys: D-Pad
- Z: A Button
- X: B Button
- Enter: Start
- Shift: Select

### Managing Metadata

**Edit Game Information:**
1. Click on a game
2. Click **Edit** icon
3. Modify title, description, platform, etc.
4. Save changes

**Re-fetch Metadata:**
1. Click on a game
2. Click **Refresh Metadata**
3. Select provider
4. Choose matching game from results

### User Management

**Add Users (Admin only):**
1. Go to **Settings** → **Users**
2. Click **Add User**
3. Enter username and password
4. Assign permissions

### Save States & Saves

- Save states are automatically stored in `/data/assets`
- Create save states using emulator menu (F2 by default)
- Load states from game details page

---

## Backup & Restore

### What to Backup

1. **Database:** `/addon_configs/[addon_slug]/data/mysql/`
2. **Assets:** `/addon_configs/[addon_slug]/data/assets/`
3. **Resources:** `/addon_configs/[addon_slug]/data/resources/` (optional, can be re-downloaded)
4. **Configuration:** Add-on configuration settings

### Manual Backup

**Using Terminal/SSH:**
```bash
# Stop the add-on first
cd /addon_configs/[addon_slug]/data
tar -czf romm-backup-$(date +%Y%m%d).tar.gz mysql assets resources
```

**Restore:**
```bash
# Stop the add-on
cd /addon_configs/[addon_slug]/data
tar -xzf romm-backup-YYYYMMDD.tar.gz
# Start the add-on
```

### Automated Backup

Consider using Home Assistant's backup features or third-party add-ons like:
- **Home Assistant Google Drive Backup**
- **Samba Backup**

---

## Troubleshooting

### Add-on Won't Start

**Check Logs:**
- Go to add-on page → **Log** tab
- Look for error messages

**Common Issues:**
1. **Insufficient memory** - Ensure at least 2GB RAM available
2. **Port conflict** - Port 8080 already in use
3. **Database initialization failure** - Check `/data/mysql/error.log`

**Solution:** Restart add-on, check system resources, review logs.

### Games Not Appearing

**Verify:**
1. ROMs are in correct directory structure
2. Platform folders use correct names
3. File extensions are supported

**Fix:**
```bash
# Check directory structure
ls -la /share/romm/library/roms/

# Ensure permissions
chmod -R 755 /share/romm/library/
```

### Metadata Not Fetching

**Check:**
1. Metadata provider credentials are correct
2. API keys are valid and active
3. Internet connectivity from add-on

**Test IGDB:**
- Verify Client ID and Secret are correct
- Check Twitch application status
- Ensure no API rate limits hit

**Test Screenscraper:**
- Verify account is active
- Check daily request limits (free accounts)

### Slow Performance

**Optimization:**
1. **Reduce workers:** Modify Romm service to use fewer workers
2. **Increase timeout:** Adjust `scan_timeout` in configuration
3. **Disable scheduled scans:** Set `enable_scheduled_rescan: false`
4. **Cache cleanup:** Delete `/data/redis/dump.rdb` to clear cache

### Web Interface Not Loading

**Check:**
1. Add-on is running (green status)
2. Port 8080 is accessible
3. Ingress is enabled

**Solution:**
```bash
# Check if Romm is listening
netstat -tuln | grep 8080

# Test local access
curl http://localhost:8080
```

### Database Errors

**Symptoms:**
- Error messages about database connection
- Failed to start MariaDB

**Fix:**
1. Stop add-on
2. Check `/data/mysql/error.log`
3. If corrupted, restore from backup or reinitialize:
   ```bash
   mv /data/mysql /data/mysql.backup
   # Restart add-on to reinitialize
   ```

---

## Architecture

### Components

The add-on runs three main services managed by S6-Overlay:

1. **MariaDB** - Database for game library and metadata
   - Runs on `127.0.0.1:3306`
   - Data stored in `/data/mysql`

2. **Redis** - Caching layer for performance
   - Runs on `127.0.0.1:6379`
   - Data stored in `/data/redis`

3. **Romm** - Web application (FastAPI + Gunicorn)
   - Runs on `0.0.0.0:8080`
   - Frontend built with Vue.js
   - Backend: Python FastAPI

### Storage Layout

```
/data/
├── mysql/          # MariaDB database files
├── redis/          # Redis cache
├── resources/      # Downloaded metadata and artwork
├── assets/         # User uploads, saves, states
└── config/         # Application configuration

/share/romm/
└── library/        # User's ROM collection
    └── roms/       # ROMs organized by platform
```

### Service Startup Order

1. **Init Scripts** (`cont-init.d`):
   - `00-banner.sh` - Display startup banner
   - `01-init-db.sh` - Initialize MariaDB, create database
   - `02-config.sh` - Prepare directories and configuration

2. **Services** (`services.d`):
   - `mariadb` - Start database server
   - `redis` - Start cache server
   - `romm` - Start web application (waits for DB and Redis)

### Security

- **Internal Services:** MariaDB and Redis only bind to localhost
- **No External Ports:** Only Romm web interface (8080) is exposed
- **Ingress:** Secured through Home Assistant authentication
- **Auto-Generated Secrets:** Database password and auth keys created on first run

---

## FAQ

### Can I use my existing ROM collection?

Yes! Simply move or copy your ROMs to `/share/romm/library/roms/[platform]/`. Romm will scan and import them.

### Does this work with RetroArch?

Romm uses EmulatorJS for browser-based emulation, not RetroArch. However, you can use your Romm library with RetroArch installed elsewhere.

### How much storage space do I need?

- **Add-on:** ~1-2GB
- **ROMs:** Varies by collection (GB to TB)
- **Metadata/Artwork:** 1-5GB for typical collection
- **Database:** 100MB-1GB depending on library size

### Can multiple users access simultaneously?

Yes! Romm supports multiple concurrent users with individual accounts and permissions.

### Is this legal?

Managing and organizing game backups is legal. However, downloading ROMs for games you don't own is illegal in most jurisdictions. This add-on does not provide or facilitate ROM downloads.

### How do I update the add-on?

Updates appear in the Home Assistant add-on store. Click **Update** when available. Your data and configuration are preserved.

### Can I access this remotely?

Yes, if you have Home Assistant remote access configured (Nabu Casa or reverse proxy). Romm is accessible through Home Assistant's Ingress.

### What platforms are supported?

400+ platforms including:
- Nintendo: NES, SNES, N64, GameCube, Wii, Game Boy, GBA, DS, 3DS, Switch
- PlayStation: PS1, PS2, PS3, PSP, Vita
- Sega: Genesis, Saturn, Dreamcast, Game Gear
- Xbox: Original, 360
- Arcade: MAME, FinalBurn Neo
- And many more!

### How do I uninstall?

1. Stop the add-on
2. Click **Uninstall**
3. Optionally, delete `/share/romm/` to remove ROM library
4. Optionally, delete backup data from `/backup/` if created

---

## Additional Resources

- **Romm Documentation:** https://github.com/rommapp/romm/wiki
- **Romm Discord:** https://discord.gg/P5HG96p9nB
- **Home Assistant Community:** https://community.home-assistant.io/
- **Issue Reporting:** https://github.com/rommapp/romm/issues

---

**Enjoy your retro gaming collection with Romm!** 🎮
