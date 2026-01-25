#!/bin/bash
# Squidcup Server Pre-Start Configuration
# This script runs before the CS2 server starts (joedwards32/cs2 hook)
set -e

CS2_DIR="/home/steam/cs2-dedicated"
CSGO_DIR="$CS2_DIR/game/csgo"
STAGING_DIR="/opt/squidcup-staging"
GAMEINFO_FILE="$CSGO_DIR/gameinfo.gi"

echo "[Squidcup] Running pre-start configuration..."

# Copy staged files (plugins, metamod, cfg) to game directory
if [ -d "$STAGING_DIR" ] && [ "$(ls -A $STAGING_DIR 2>/dev/null)" ]; then
    echo "[Squidcup] Installing Squidcup plugin and Metamod from staging..."
    cp -r "$STAGING_DIR"/* "$CSGO_DIR/"
    echo "[Squidcup] Plugin files installed successfully"
else
    echo "[Squidcup] Warning: Staging directory empty or missing at $STAGING_DIR"
fi

# Modify gameinfo.gi to add Metamod if not already present
if [ -f "$GAMEINFO_FILE" ]; then
    if ! grep -q "csgo/addons/metamod" "$GAMEINFO_FILE"; then
        echo "[Squidcup] Adding Metamod to gameinfo.gi..."
        # Add Metamod line after Game_LowViolence csgo_lv
        sed -i '/Game_LowViolence.*csgo_lv/a\                        Game    csgo/addons/metamod' "$GAMEINFO_FILE"
        echo "[Squidcup] gameinfo.gi updated successfully"
    else
        echo "[Squidcup] Metamod already configured in gameinfo.gi"
    fi
else
    echo "[Squidcup] Warning: gameinfo.gi not found at $GAMEINFO_FILE"
    echo "[Squidcup] This is normal on first run - file will exist after game download"
fi

echo "[Squidcup] Pre-start configuration complete"
