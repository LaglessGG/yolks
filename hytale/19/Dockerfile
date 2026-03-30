FROM --platform=$TARGETOS/$TARGETARCH eclipse-temurin:19-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive

LABEL author="Alex Chatham" maintainer="info@blstmo.com" \
      org.opencontainers.image.source="https://github.com/LaglessGG/yolks" \
      org.opencontainers.image.licenses=MIT

# Install additional packages and create container user
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl unzip jq lsof ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -d /home/container -m container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./../entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]

