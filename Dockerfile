# syntax=docker/dockerfile:1
ARG JAVA_VERSION=25
FROM eclipse-temurin:${JAVA_VERSION} AS temurin

FROM debian:trixie-slim

LABEL org.opencontainers.image.licenses="MIT"

ENV JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/java/openjdk/bin:$PATH \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC \
    USER=container \
    HOME=/home/container

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash ca-certificates fontconfig iproute2 libasound2t64 libstdc++6 \
        libx11-6 libxext6 libxi6 libxrender1 libxtst6 tzdata zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --user-group --create-home --home-dir /home/container container

# Follow the standard Temurin JDK tag while keeping OS packages on Debian.
COPY --from=temurin /opt/java/openjdk /opt/java/openjdk
COPY --chmod=755 java/entrypoint.sh /entrypoint.sh

USER container
WORKDIR /home/container
ENTRYPOINT ["/entrypoint.sh"]
