#!/bin/bash
# Custom entrypoint wrapper for Squidcup CS2 server
# Ensures pre.sh is copied to the volume mount before the base entrypoint runs
set -e

CS2_DIR="/home/steam/cs2-dedicated"
SCRIPTS_SRC="/opt/squidcup-scripts"

# Base container entrypoint location (joedwards32/cs2 uses /home/steam/entry.sh)
BASE_ENTRYPOINT="/home/steam/entry.sh"

echo "[Squidcup] Initializing Squidcup server container..."

# Copy our pre.sh to the cs2-dedicated directory (which may be volume-mounted)
# This ensures our hook runs even when using persistent volumes
if [ -f "$SCRIPTS_SRC/pre.sh" ]; then
    echo "[Squidcup] Installing pre.sh hook to $CS2_DIR/"
    cp "$SCRIPTS_SRC/pre.sh" "$CS2_DIR/pre.sh"
    chmod +x "$CS2_DIR/pre.sh"
fi

# Optionally start update checker in background if enabled
if [ "${ENABLE_UPDATE_CHECK:-0}" = "1" ]; then
    echo "[Squidcup] Starting background update checker..."
    "$SCRIPTS_SRC/update-check.sh" &
fi

echo "[Squidcup] Handing off to base container entrypoint..."

# Execute the original entrypoint from the base image
exec "$BASE_ENTRYPOINT" "$@"
