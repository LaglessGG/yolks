#!/bin/bash
cd /home/container

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# set this variable, dotnet needs it even without it it reports to `dotnet --info` it can not start any aplication without this
export DOTNET_ROOT=/usr/share/

# Log prefix for consistency with other yolks
if [ -z "${LOG_PREFIX}" ]; then
    LOG_PREFIX="\033[1m\033[33mcontainer@pterodactyl~\033[0m"
fi

# Quick ownership/permission check similar to other yolks
# If files are not owned by the running user, attempt to fix; otherwise warn.
NOT_OWNED_COUNT=$(find /home/container -mindepth 1 -maxdepth 3 ! -user "$(id -u)" 2>/dev/null | wc -l | tr -d ' ')
if [ "$NOT_OWNED_COUNT" != "0" ]; then
    echo -e "${LOG_PREFIX} Detected files not owned by current user. Attempting to fix ownership..."
    if chown -R $(id -u):$(id -g) /home/container 2>/dev/null; then
        echo -e "${LOG_PREFIX} Ownership corrected for /home/container"
    else
        echo -e "${LOG_PREFIX} Could not change ownership (insufficient permissions). Ensure the mount is writable and not root-owned."
    fi
fi

# Ensure common script files are executable
find /home/container -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null

# print the dotnet version on startup
printf "${LOG_PREFIX} dotnet --version\n"
dotnet --version

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
