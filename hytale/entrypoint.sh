#!/bin/bash

# Hytale Server Entrypoint

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

# Set default values
SERVER_PORT=${SERVER_PORT:-"5520"}
MAXIMUM_RAM=${MAXIMUM_RAM:-"90"}
JVM_FLAGS=${JVM_FLAGS:-""}
CDN_URL=${CDN_URL:-"https://ht-cdn.lagless.gg"}
HYTALE_PATCHLINE=${HYTALE_PATCHLINE:-"release"}
USE_AOT_CACHE=${USE_AOT_CACHE:-"0"}
HYTALE_ALLOW_OP=${HYTALE_ALLOW_OP:-"0"}
HYTALE_AUTH_MODE=${HYTALE_AUTH_MODE:-"authenticated"}
HYTALE_ACCEPT_EARLY_PLUGINS=${HYTALE_ACCEPT_EARLY_PLUGINS:-"0"}
DISABLE_SENTRY=${DISABLE_SENTRY:-"0"}

# Create Server directory if it doesn't exist
mkdir -p Server

# Function to download and verify file
download_file() {
    local filename=$1
    local expected_sha256=$2
    local target_path=$3
    
    # Check if file exists and matches SHA256
    if [ -f "$target_path" ]; then
        CURRENT_SHA256=$(sha256sum "$target_path" | awk '{print $1}')
        if [ "$CURRENT_SHA256" = "$expected_sha256" ]; then
            echo "$filename is up to date (SHA256 match)"
            return 0
        fi
        echo "$filename outdated, downloading..."
    else
        echo "$filename not found, downloading..."
    fi
    
    # Download file with progress bar
    echo "Downloading $filename..."
    if ! curl -# -L -f "$CDN_URL/download/latest/$filename" -o "${target_path}.tmp"; then
        echo "ERROR: Failed to download $filename"
        rm -f "${target_path}.tmp"
        return 1
    fi
    
    # Verify SHA256
    echo "Verifying $filename..."
    DOWNLOADED_SHA256=$(sha256sum "${target_path}.tmp" | awk '{print $1}')
    if [ "$DOWNLOADED_SHA256" != "$expected_sha256" ]; then
        echo "ERROR: SHA256 mismatch for $filename!"
        echo "Expected: $expected_sha256"
        echo "Got: $DOWNLOADED_SHA256"
        rm -f "${target_path}.tmp"
        return 1
    fi
    
    echo "$filename verified successfully"
    mv "${target_path}.tmp" "$target_path"
    return 0
}

# Download manifest and server files
echo "Fetching manifest from CDN..."

if ! curl -sSL -f "$CDN_URL/manifest.json" -o manifest.json; then
    echo "ERROR: Failed to fetch manifest from CDN"
    exit 1
fi

# Extract latest version info
LATEST_VERSION=$(jq -r '.latest_version' manifest.json)

if [ -z "$LATEST_VERSION" ]; then
    echo "ERROR: Failed to parse manifest"
    exit 1
fi

echo "Latest version: $LATEST_VERSION"
echo ""

# Download all required files
echo "Downloading server files..."

# Download HytaleServer.jar
JAR_SHA256=$(jq -r '.versions[] | select(.version == "'$LATEST_VERSION'") | .files[] | select(.filename == "HytaleServer.jar") | .sha256' manifest.json)
if ! download_file "HytaleServer.jar" "$JAR_SHA256" "Server/HytaleServer.jar"; then
    echo "ERROR: Failed to download HytaleServer.jar"
    exit 1
fi
echo ""

# Download HytaleServer.aot (optional, for USE_AOT_CACHE)
AOT_SHA256=$(jq -r '.versions[] | select(.version == "'$LATEST_VERSION'") | .files[] | select(.filename == "HytaleServer.aot") | .sha256' manifest.json)
if [ -n "$AOT_SHA256" ] && [ "$AOT_SHA256" != "null" ]; then
    download_file "HytaleServer.aot" "$AOT_SHA256" "Server/HytaleServer.aot"
    echo ""
fi

# Download Assets.zip
ASSETS_SHA256=$(jq -r '.versions[] | select(.version == "'$LATEST_VERSION'") | .files[] | select(.filename == "Assets.zip") | .sha256' manifest.json)
if ! download_file "Assets.zip" "$ASSETS_SHA256" "Assets.zip"; then
    echo "ERROR: Failed to download Assets.zip"
    exit 1
fi
echo ""

# Clean up manifest
rm -f manifest.json

# Verify server jar exists
if [ ! -f "Server/HytaleServer.jar" ]; then
    echo "ERROR: Server JAR not found after download"
    exit 1
fi

echo "All files downloaded successfully"
echo ""

# Calculate memory
SERVER_MEMORY_REAL=$((SERVER_MEMORY * MAXIMUM_RAM / 100))

# Build startup command
STARTUP_CMD="java"

# Add AOT cache if enabled and file exists
if [ "$USE_AOT_CACHE" = "1" ] && [ -f "Server/HytaleServer.aot" ]; then
    STARTUP_CMD+=" -XX:AOTCache=Server/HytaleServer.aot"
fi

# Add memory settings
STARTUP_CMD+=" -Xms128M -Xmx${SERVER_MEMORY_REAL}M"

# Add custom JVM flags
[ -n "$JVM_FLAGS" ] && STARTUP_CMD+=" $JVM_FLAGS"

# Add jar
STARTUP_CMD+=" -jar Server/HytaleServer.jar"

# Add server arguments
[ "$HYTALE_ALLOW_OP" = "1" ] && STARTUP_CMD+=" --allow-op"
[ "$HYTALE_ACCEPT_EARLY_PLUGINS" = "1" ] && STARTUP_CMD+=" --accept-early-plugins"
[ "$DISABLE_SENTRY" = "1" ] && STARTUP_CMD+=" --disable-sentry"

# Add required arguments
STARTUP_CMD+=" --auth-mode $HYTALE_AUTH_MODE"
STARTUP_CMD+=" --assets Assets.zip"
STARTUP_CMD+=" --bind 0.0.0.0:$SERVER_PORT"

echo "Starting Hytale Server v$LATEST_VERSION"
echo "$STARTUP_CMD"
echo ""


exec $STARTUP_CMD

