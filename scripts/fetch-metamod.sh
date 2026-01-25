#!/bin/bash
# Fetches the latest Metamod:Source build from the official downloads page
set -e

OUTPUT_DIR="${1:-.}"

echo "[Metamod] Detecting latest build number..."

# Fetch the downloads page and extract latest build number
METAMOD_PAGE="https://www.metamodsource.net/downloads.php/?branch=master"
BUILD_NUMBER=$(curl -s "$METAMOD_PAGE" | grep -oP 'mmsource-2\.0\.0-git\K\d+' | head -1)

if [ -z "$BUILD_NUMBER" ]; then
    echo "[Metamod] Error: Could not detect build number from downloads page"
    exit 1
fi

echo "[Metamod] Latest build: $BUILD_NUMBER"

METAMOD_URL="https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git${BUILD_NUMBER}-linux.tar.gz"
echo "[Metamod] Downloading from: $METAMOD_URL"

wget -q -O /tmp/metamod.tar.gz "$METAMOD_URL"
mkdir -p "$OUTPUT_DIR"
tar -xzf /tmp/metamod.tar.gz -C "$OUTPUT_DIR"
rm /tmp/metamod.tar.gz

echo "[Metamod] Successfully installed build $BUILD_NUMBER to $OUTPUT_DIR"
