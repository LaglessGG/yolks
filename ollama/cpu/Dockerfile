FROM        --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL       author="LaglessGG"

LABEL       org.opencontainers.image.source="https://github.com/LaglessGG/yolks"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND=noninteractive

RUN         apt update \
            && apt install -y --no-install-recommends ca-certificates curl iproute2 \
            && rm -rf /var/lib/apt/lists/*

# Official installer auto-detects there's no GPU in this build environment and installs the
# CPU-optimized runners only — no extra flags needed to get a CPU-only build.
RUN         curl -fsSL https://ollama.com/install.sh | sh

RUN         useradd -d /home/container -m container

USER        container
ENV         USER=container HOME=/home/container OLLAMA_MODELS=/home/container/ollama-models
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh

# Wings always runs this as the node's configured non-root uid/gid (not necessarily the
# "container" user's build-time uid above), so this just needs to be world-readable — it's
# invoked as `bash /entrypoint.sh`, not executed directly, so no +x is required either.
USER        root
RUN         chmod 644 /entrypoint.sh
USER        container

CMD         [ "/bin/bash", "/entrypoint.sh" ]
