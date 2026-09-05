# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

ARG BUILD_DATE
ARG VERSION=local
ARG DEBIAN_FRONTEND=noninteractive

LABEL build_version="apache-webdav version:- ${VERSION} Build-date:- ${BUILD_DATE}" \
      maintainer="local" \
      org.opencontainers.image.title="Apache WebDAV" \
      org.opencontainers.image.description="Apache WebDAV with LinuxServer-style PUID, PGID, TZ and s6-overlay support"

RUN \
    echo "**** install Apache ****" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apache2 \
        apache2-utils && \
    echo "**** clean up ****" && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /var/log/*

COPY config/httpd.conf /defaults/httpd.conf
COPY config/webdav.conf /defaults/webdav.conf
COPY config/webdav.conf.sample /defaults/webdav.conf.sample
COPY config/README.md /defaults/config-README.md
COPY root/ /

RUN chmod 0755 \
        /etc/s6-overlay/s6-rc.d/init-webdav-config/run \
        /etc/s6-overlay/s6-rc.d/svc-apache-webdav/run

ENV HOME=/config \
    WEBDAV_CHOWN=true \
    UMASK=022

VOLUME ["/config", "/data"]

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["curl", "--fail", "--silent", "--show-error", "--output", "/dev/null", "http://127.0.0.1/.webdav-health"]
