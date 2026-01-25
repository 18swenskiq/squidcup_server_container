# Squidcup CS2 Server Container

Docker container for hosting a Squidcup-enabled CS2 dedicated server.

## What's Included

- **Base Image**: [joedwards32/cs2](https://github.com/joedwards32/CS2) - CS2 dedicated server with automatic updates
- **Squidcup Plugin**: Built from the included submodule with all dependencies
- **CounterStrikeSharp**: Runtime automatically downloaded (version matched to plugin)
- **Metamod:Source**: Latest version automatically fetched during build

## Quick Start

### Using Docker Compose (Recommended)

```yaml
version: "3.8"
services:
  cs2-server:
    build: .
    # Or use pre-built image when available:
    # image: your-registry/squidcup-server:latest
    container_name: squidcup-cs2
    restart: unless-stopped
    environment:
      - SRCDS_TOKEN=your_srcds_token_here
      - CS2_SERVERNAME=Squidcup Server
      - CS2_PORT=27015
      - CS2_RCON_PORT=27015
      - CS2_MAXPLAYERS=10
      - CS2_GAMETYPE=0
      - CS2_GAMEMODE=1
      # Optional: Enable background update checker
      - ENABLE_UPDATE_CHECK=0
    volumes:
      - "/apps/cs2:/home/steam/cs2-dedicated"
    ports:
      - "27015:27015/tcp"
      - "27015:27015/udp"
      - "27020:27020/udp"
```

### Using Docker CLI

```bash
docker build -t squidcup-server .

docker run -d \
  --name squidcup-cs2 \
  -e SRCDS_TOKEN="your_token" \
  -v /apps/cs2:/home/steam/cs2-dedicated \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  squidcup-server
```

## Environment Variables

All environment variables from the [base image](https://github.com/joedwards32/CS2#environment-variables) are supported, plus:

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_UPDATE_CHECK` | `0` | Set to `1` to enable background CS2 update checking |
| `UPDATE_CHECK_INTERVAL` | `300` | Seconds between update checks (when enabled) |

## How It Works

1. **Build Time**: The Dockerfile compiles Squidcup from source, downloads CounterStrikeSharp and Metamod, and stages them at `/opt/squidcup-staging/`

2. **Runtime**: On container start:
   - Our entrypoint copies `pre.sh` to your volume mount
   - The base image downloads/updates CS2 game files
   - `pre.sh` copies plugins from staging to `game/csgo/`
   - `pre.sh` modifies `gameinfo.gi` to load Metamod
   - Server starts with all plugins ready

## Volume Mounts

When using persistent volumes (recommended), the container automatically:
- Installs the `pre.sh` hook script to your volume
- Copies plugin files on each start (ensuring updates are applied)
- Only modifies `gameinfo.gi` if Metamod isn't already configured

## Building

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/your-repo/squidcup_server_container.git

# Build the container
docker build -t squidcup-server .
```

## Updating the Plugin

1. Update the `Squidcup_Plugin` submodule
2. Rebuild the container
3. Restart your server (new plugin files will be installed automatically)

## Notes

- The public IP of the server must be added to the Squidcup database before it works with Squidcup
- First startup may take a while as CS2 game files are downloaded (~35GB)
- Subsequent starts are much faster (only updates are downloaded)


TODO:
- Modify plugin to not store DB credentials in file, but instead call a route (which will verify based on source IP)
- When starting new game in squidcup, cancel any existing ones