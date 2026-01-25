# Squidcup CS2 Server Container
# Extends joedwards32/cs2 with Squidcup plugin, CounterStrikeSharp, and Metamod

# ============================================================================
# Build Stage: Compile plugin and fetch dependencies
# ============================================================================
FROM joedwards32/cs2 AS builder

USER root

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK 8.0 for building the plugin
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy the plugin source code
COPY Squidcup_Plugin/ ./Squidcup_Plugin/

# Copy metamod fetch script
COPY scripts/fetch-metamod.sh ./

# Build the plugin
WORKDIR /build/Squidcup_Plugin
RUN dotnet restore
RUN dotnet publish -c Release -o /build/output/addons/counterstrikesharp/plugins/Squidcup

# Copy config files
RUN cp -r cfg /build/output/

# Get CounterStrikeSharp version from csproj and download runtime
RUN CSSHARP_VERSION=$(grep -Po '<PackageReference Include="CounterStrikeSharp.API" Version="\K\d+(\.\d+)*' Squidcup.csproj) && \
    echo "Downloading CounterStrikeSharp v${CSSHARP_VERSION}..." && \
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/roflmuffin/CounterStrikeSharp/releases/tags/v${CSSHARP_VERSION}" | \
        grep -o '"browser_download_url": "[^"]*counterstrikesharp-with-runtime-linux-[^"]*\.zip"' | \
        head -1 | cut -d'"' -f4) && \
    echo "Download URL: ${DOWNLOAD_URL}" && \
    wget -q -O /tmp/cssharp.zip "${DOWNLOAD_URL}" && \
    unzip -o /tmp/cssharp.zip -d /build/output/ && \
    rm /tmp/cssharp.zip

# Re-publish plugin over CSSharp (ensures our plugin is in the correct location)
RUN dotnet publish -c Release -o /build/output/addons/counterstrikesharp/plugins/Squidcup

# Download and install Metamod (latest version)
WORKDIR /build
RUN chmod +x fetch-metamod.sh && ./fetch-metamod.sh /build/output

# ============================================================================
# Final Stage: Production image
# ============================================================================
FROM joedwards32/cs2

LABEL maintainer="Squidcup Team"
LABEL description="CS2 Dedicated Server with Squidcup plugin, CounterStrikeSharp, and Metamod"

# Copy built plugins and Metamod to staging location
# These will be installed to the game directory at runtime by pre.sh
COPY --from=builder /build/output/ /opt/squidcup-staging/

# Copy runtime scripts
COPY scripts/pre.sh /opt/squidcup-scripts/pre.sh
COPY scripts/update-check.sh /opt/squidcup-scripts/update-check.sh
COPY scripts/entrypoint.sh /opt/squidcup-scripts/entrypoint.sh

# Make scripts executable
USER root
RUN chmod +x /opt/squidcup-scripts/*.sh

# Set ownership so steam user can access
RUN chown -R steam:steam /opt/squidcup-staging /opt/squidcup-scripts

USER steam

# Environment variable to optionally enable update checker
ENV ENABLE_UPDATE_CHECK=0

# Use our custom entrypoint wrapper
ENTRYPOINT ["/opt/squidcup-scripts/entrypoint.sh"]
