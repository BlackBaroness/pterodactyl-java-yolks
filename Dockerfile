# syntax=docker/dockerfile:1
ARG JAVA_VERSION=25
FROM eclipse-temurin:${JAVA_VERSION}

LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        lsof curl ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 \
        tzdata iproute2 libstdc++6 libasound2t64 libxi6 libxrender1 libxtst6 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --home-dir /home/container container

COPY --chmod=755 java/entrypoint.sh /entrypoint.sh

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
CMD ["/bin/bash", "/entrypoint.sh"]
