FROM        --platform=$TARGETOS/$TARGETARCH alpine:latest

LABEL       author="Alex Chatham" maintainer="info@blstmo.com"

LABEL       org.opencontainers.image.source="https://github.com/LaglessGG/yolks"
LABEL       org.opencontainers.image.licenses=MIT

RUN         apk add --update --no-cache ca-certificates tzdata tini \
            && adduser -D -h /home/container container \
            && rm -rf /usr/bin/fallocate

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/sbin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]