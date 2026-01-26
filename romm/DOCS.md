# Romm - ROM Collection Manager

Romm (ROM Manager) is a self-hosted web-based
ROM collection manager and emulator launcher.

## Network Configuration

### Port Settings

**Port** (default: 5999)
- The network port for accessing the ROMM web interface
- Change if port 5999 conflicts with other services
- Valid range: 1024-65535
- After changing, restart the add-on

### Security Recommendations

ROMM does not include built-in authentication beyond the application's user management system. For production use:

1. **Internal Network Only**: Only expose on trusted internal networks
2. **Reverse Proxy**: Use Traefik, nginx Proxy Manager, or similar with authentication layer
3. **Authentication Proxy**: Consider Authelia, Keycloak, or similar for SSO
4. **HTTPS**: Use valid SSL certificates via reverse proxy
5. **Firewall**: Restrict access using firewall rules or VLAN isolation
6. **Strong Passwords**: Use strong passwords for ROMM user accounts

### Reverse Proxy Example (Traefik)

If using Traefik as a reverse proxy with authentication:

```yaml
http:
  routers:
    romm:
      rule: "Host(`romm.yourdomain.com`)"
      service: romm
      middlewares:
        - authelia  # Or your authentication middleware
      tls:
        certResolver: letsencrypt
  services:
    romm:
      loadBalancer:
        servers:
          - url: "http://YOUR_HA_IP:5999"
```

### Reverse Proxy Example (nginx Proxy Manager)

1. Create a new Proxy Host
2. Set Domain Name: `romm.yourdomain.com`
3. Set Scheme: `http`
4. Set Forward Hostname/IP: `YOUR_HA_IP`
5. Set Forward Port: `5999`
6. Enable SSL (recommended)
7. Enable "Force SSL"
8. Optionally add Access List for authentication

## Features

- Scan and organize ROM collections across 400+ platforms
- Automatic metadata fetching from IGDB, ScreenScraper, RetroAchievements, and more
- Custom artwork from SteamGridDB
- In-browser gameplay via EmulatorJS and RuffleRS
- Multi-disk games, DLCs, mods, and patches support
- User management with permission-based access control

## Prerequisites

### MariaDB Database

Romm requires a MariaDB/MySQL database. You must have access to a
MariaDB instance before installing this add-on.

Options:

1. Install a MariaDB add-on from the Home Assistant Add-on Store
2. Use an external MariaDB server on your network
3. Use a cloud-hosted MySQL database

**Required database setup:**

```sql
CREATE DATABASE romm;
CREATE USER 'romm-user'@'%' IDENTIFIED BY 'your-secure-password';
GRANT ALL PRIVILEGES ON romm.* TO 'romm-user'@'%';
FLUSH PRIVILEGES;
```

## Configuration

### Required Settings

- **Database Host**: Hostname or IP address of your MariaDB server
- **Database Password**: Password for the database user
- **Auth Secret Key**: Generate with `openssl rand -hex 32`

### Library Path

By default, Romm looks for ROMs in `/share/roms`. Organize your ROMs like:

```
/share/roms/
├── Nintendo 64/
│   ├── Super Mario 64.z64
│   └── Legend of Zelda, The - Ocarina of Time.z64
├── PlayStation/
│   ├── Final Fantasy VII (Disc 1).bin
│   ├── Final Fantasy VII (Disc 1).cue
│   └── ...
└── Game Boy Advance/
    └── Pokemon Emerald.gba
```

### Metadata Providers (Optional but Recommended)

Configure API keys for metadata providers to get rich game information:

- **ScreenScraper**: Register at <https://www.screenscraper.fr/>
- **RetroAchievements**: Get key at <https://retroachievements.org/>
- **SteamGridDB**: Get key at <https://www.steamgriddb.com/>
- **IGDB**: Register at <https://api-docs.igdb.com/>

Without IGDB credentials, some metadata features may not work properly.

## First Run Setup

1. Install and configure the add-on
2. Set required options:
   - Database connection (host, port, name, user, password)
   - Auth secret key (generate with: `openssl rand -hex 32`)
   - Library path (default: `/share/roms`)
3. Optional: Configure metadata provider API keys
4. Optional: Change port if 5999 conflicts (default: 5999)
5. Start the add-on
6. Open Web UI: `http://YOUR_HA_IP:5999` (or click "Open Web UI" button in add-on interface)
7. Complete setup wizard:
   - Create admin username and password
   - Configure library scan settings
8. Start scanning your ROM library

## Support

For Romm-specific issues, consult:

- Official documentation: <https://docs.romm.app/>
- GitHub repository: <https://github.com/rommapp/romm>

For add-on issues, report at: <https://github.com/rigerc/home-assistant-addons/issues>
