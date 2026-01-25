#!/bin/bash
# CS2 Update Checker
# Checks SteamCMD for available updates and restarts the server if found
# Run this as a background process or via cron

CS2_DIR="/home/steam/cs2-dedicated"
STEAMCMD="/home/steam/steamcmd/steamcmd.sh"
APP_ID="730"  # CS2 dedicated server app ID
CHECK_INTERVAL="${UPDATE_CHECK_INTERVAL:-300}"  # Default: 5 minutes

echo "[UpdateCheck] Starting CS2 update checker (interval: ${CHECK_INTERVAL}s)"

check_for_update() {
    # Query Steam for latest build ID
    LATEST=$($STEAMCMD +login anonymous +app_info_update 1 +app_info_print $APP_ID +quit 2>/dev/null | \
             grep -A10 '"public"' | grep '"buildid"' | head -1 | tr -dc '0-9')
    
    # Get current installed build ID from manifest
    MANIFEST_FILE="$CS2_DIR/steamapps/appmanifest_${APP_ID}.acf"
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo "[UpdateCheck] Manifest not found: $MANIFEST_FILE"
        return 1
    fi
    
    CURRENT=$(grep '"buildid"' "$MANIFEST_FILE" | head -1 | tr -dc '0-9')
    
    if [ -z "$LATEST" ]; then
        echo "[UpdateCheck] Could not fetch latest version from Steam"
        return 1
    fi
    
    if [ -z "$CURRENT" ]; then
        echo "[UpdateCheck] Could not read current version from manifest"
        return 1
    fi
    
    echo "[UpdateCheck] Current: $CURRENT, Latest: $LATEST"
    
    if [ "$LATEST" != "$CURRENT" ]; then
        echo "[UpdateCheck] New CS2 update available: $CURRENT -> $LATEST"
        return 0
    fi
    
    return 1
}

# Main loop
while true; do
    if check_for_update; then
        echo "[UpdateCheck] Triggering server restart for update..."
        # Kill the CS2 server process - container should restart automatically
        # if configured with restart policy
        pkill -f "cs2" || true
        echo "[UpdateCheck] Server process terminated, waiting for restart..."
        sleep 60  # Wait for restart before checking again
    fi
    sleep "$CHECK_INTERVAL"
done
