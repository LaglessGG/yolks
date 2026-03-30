FROM        --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim
LABEL       author="Alex Chatham" maintainer="info@blstmo.com"
LABEL       org.opencontainers.image.source="https://github.com/LaglessGG/yolks"
LABEL       org.opencontainers.image.licenses=MIT
ENV         DEBIAN_FRONTEND=noninteractive

## Configure custom APT mirrors
RUN         echo "deb https://mirrors.accretive-networks.net/debian/ bookworm main contrib non-free" > /etc/apt/sources.list \
            && echo "deb-src https://mirrors.accretive-networks.net/debian/ bookworm main contrib non-free" >> /etc/apt/sources.list \
            && echo "deb https://mirrors.accretive-networks.net/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list \
            && echo "deb-src https://mirrors.accretive-networks.net/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list \
            && echo "deb https://mirrors.accretive-networks.net/debian/ bookworm-updates main contrib non-free" >> /etc/apt/sources.list \
            && echo "deb-src https://mirrors.accretive-networks.net/debian/ bookworm-updates main contrib non-free" >> /etc/apt/sources.list

RUN         apt update && apt upgrade -y \
            && apt -y --no-install-recommends install ca-certificates curl git unzip zip tar jq wget \
            && echo -e "\033[38;5;47m██████╗ ██╗     ███████╗████████╗███╗   ███╗ ██████╗     ██████╗ ██████╗ ███╗   ███╗\n\
██╔══██╗██║     ██╔════╝╚══██╔══╝████╗ ████║██╔═══██╗   ██╔════╝██╔═══██╗████╗ ████║\n\
██████╔╝██║     ███████╗   ██║   ██╔████╔██║██║   ██║   ██║     ██║   ██║██╔████╔██║\n\
██╔══██╗██║     ╚════██║   ██║   ██║╚██╔╝██║██║   ██║   ██║     ██║   ██║██║╚██╔╝██║\n\
██████╔╝███████╗███████║   ██║   ██║ ╚═╝ ██║╚██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║\n\
╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝\033[0m" > /etc/motd
RUN         if [ "$(uname -m)" = "x86_64" ]; then \
                dpkg --add-architecture i386 && \
                apt update && \
                apt -y install lib32gcc-s1 libsdl2-2.0-0:i386; \
            fi