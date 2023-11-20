# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="MAENE version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="MAENE"
LABEL org.opencontainers.image.title=php82
ENV MIRROR=https://mirrors.tuna.tsinghua.edu.cn/alpine

# 环境变量
ENV TZ=Asia/Shanghai
ENV PUID=1000
ENV PGID=1000


# install packages
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    git \
    logrotate \
    nano \
    imagemagick \
    openssl \
    php82 \
    php82-ctype \
    php82-curl \
    php82-fileinfo \
    php82-fpm \
    php82-iconv \
    php82-json \
    php82-mbstring \
    php82-openssl \
    php82-snmp \
    php82-phar \
    php82-session \
    php82-simplexml \
    php82-xml \
    php82-xmlwriter \
    php82-zip \
    memcached \
    php82-bcmath \
    php82-bz2 \
    php82-dom \
    php82-exif \
    php82-brotli \
    php82-ftp \
    php82-pecl-zstd \
    php82-gd \
    php82-gmp \
    php82-imap \
    php82-intl \
    php82-ldap \
    php82-mysqli \
    php82-mysqlnd \
    php82-opcache \
    php82-pdo_mysql \
    php82-pdo_odbc \
    php82-pdo_pgsql \
    php82-pdo_sqlite \
    php82-pear \
    php82-pecl-apcu \
    php82-pecl-memcached \
    php82-pecl-redis \
    php82-pgsql \
    php82-posix \
    php82-soap \
    php82-sockets \
    php82-sodium \
    php82-sqlite3 \
    php82-tokenizer \
    php82-xmlreader \
    php82-xsl \
    php82-fileinfo \
    php82-pecl-imagick \
    php82-zlib && \
  echo "**** guarantee correct php version is symlinked ****" && \
  if [ "$(readlink /usr/bin/php)" != "php82" ]; then \
    rm -rf /usr/bin/php && \
    ln -s /usr/bin/php82 /usr/bin/php; \
  fi && \
  echo "**** configure php ****" && \
  sed -i "s#;error_log = log/php82/error.log.*#error_log = /config/log/php/error.log#g" \
    /etc/php82/php-fpm.conf && \
  sed -i "s#user = nobody.*#user = abc#g" \
    /etc/php82/php-fpm.d/www.conf && \
  sed -i "s#group = nobody.*#group = abc#g" \
    /etc/php82/php-fpm.d/www.conf && \
  echo "**** install php composer ****" && \
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')" && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" && \
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
      >&2 echo 'ERROR: Invalid installer checksum' && \
      rm composer-setup.php && \
      exit 1; \
  fi && \
  php composer-setup.php --install-dir=/usr/bin && \
  rm composer-setup.php && \
  ln -s /usr/bin/composer.phar /usr/bin/composer && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" \
    /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/periodic/daily/logrotate

# add local files
COPY root/ /

# ports and volumes
EXPOSE 9000

VOLUME /config