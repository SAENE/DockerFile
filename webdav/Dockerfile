# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

# set version label
ARG BUILD_DATE
ARG VERSION
ARG NGINX_VERSION
ENV WEBDAV_USERNAME=admin
ENV WEBDAV_PASSWORD=password
ENV TZ=Asia/Shanghai
ENV PUID=1000
ENV PGID=1000
LABEL org.opencontainers.image.title=WebDav
ENV MIRROR=https://mirrors.tuna.tsinghua.edu.cn/alpine
LABEL build_version="MAENE version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="MAENE"

RUN \
    echo "**** install build packages ****" && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories &&\
    apk add --no-cache \
      apache2-utils \
      git \
      logrotate \
      nano \
      nginx \
      openssl &&\
  echo "**** configure nginx ****" && \
  rm -f /etc/nginx/conf.d/stream.conf && \
  rm -f /etc/nginx/http.d/default.conf && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" \
    /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/periodic/daily/logrotate

# add local files
COPY root/ /

# install packages
RUN \
  if [ -z ${NGINX_VERSION+x} ]; then \
    NGINX_VERSION=$(curl -sL "http://mirrors.tuna.tsinghua.edu.cn/alpine/v3.18/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:nginx$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    nginx==${NGINX_VERSION} \
    nginx-mod-http-brotli==${NGINX_VERSION} \
    nginx-mod-http-dav-ext==${NGINX_VERSION} \
    nginx-mod-http-echo==${NGINX_VERSION} \
    nginx-mod-http-fancyindex==${NGINX_VERSION} \
    nginx-mod-http-geoip==${NGINX_VERSION} \
    nginx-mod-http-geoip2==${NGINX_VERSION} \
    nginx-mod-http-headers-more==${NGINX_VERSION} \
    nginx-mod-http-image-filter==${NGINX_VERSION} \
    nginx-mod-http-perl==${NGINX_VERSION} \
    nginx-mod-http-redis2==${NGINX_VERSION} \
    nginx-mod-http-set-misc==${NGINX_VERSION} \
    nginx-mod-http-upload-progress==${NGINX_VERSION} \
    nginx-mod-http-xslt-filter==${NGINX_VERSION} \
    nginx-mod-mail==${NGINX_VERSION} \
    nginx-mod-rtmp==${NGINX_VERSION} \
    nginx-mod-stream==${NGINX_VERSION} \
    nginx-mod-stream-geoip==${NGINX_VERSION} \
    nginx-mod-stream-geoip2==${NGINX_VERSION} \
    nginx-vim==${NGINX_VERSION} 

# ports and volumes
EXPOSE 80 443

VOLUME /config
VOLUME /webdav
