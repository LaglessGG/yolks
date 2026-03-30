FROM --platform=$TARGETOS/$TARGETARCH eclipse-temurin:24-jdk

LABEL author="Alex Chatham" maintainer="info@blstmo.com"

LABEL org.opencontainers.image.source="https://github.com/LaglessGG/yolks"
LABEL org.opencontainers.image.licenses=MIT

RUN apt-get update -y \
    && apt-get install -y curl unzip jq lsof ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 \
    && useradd -d /home/container -m container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./../entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]

