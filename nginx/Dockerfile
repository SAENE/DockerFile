# syntax=docker/dockerfile:1

FROM alpine:3.18 as rootfs-stage

# environment
ENV ROOTFS=/root-out
ENV REL=v3.18
ENV ARCH=x86_64
ENV MIRROR=https://mirrors.tuna.tsinghua.edu.cn/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils

# install packages
RUN \
  apk add --no-cache \
    bash \
    xz

# build rootfs
RUN \
  mkdir -p "$ROOTFS/etc/apk" && \
  { \
    echo "$MIRROR/$REL/main"; \
    echo "$MIRROR/$REL/community"; \
  } > "$ROOTFS/etc/apk/repositories" && \
  apk --root "$ROOTFS" --no-cache --keys-dir /etc/apk/keys add --arch $ARCH --initdb ${PACKAGES//,/ } && \
  sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow

# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.6.2"
ARG S6_OVERLAY_ARCH="x86_64"

# add s6 overlay
ADD https://mirror.ghproxy.com/https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://mirror.ghproxy.com/https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# add s6 optional symlinks
ADD https://mirror.ghproxy.com/https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://mirror.ghproxy.com/https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

# Runtime stage
FROM scratch
COPY --from=rootfs-stage /root-out/ /
ARG BUILD_DATE
ARG VERSION
ARG MODS_VERSION="v3"
ARG PKG_INST_VERSION="v1"
LABEL build_version="MAENE version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="MAENE"

ADD --chmod=744 "https://mirror.ghproxy.com/https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/docker-mods.${MODS_VERSION}" "/docker-mods"
ADD --chmod=744 "https://mirror.ghproxy.com/https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/package-install.${PKG_INST_VERSION}" "/etc/s6-overlay/s6-rc.d/init-mods-package-install/run"

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
  HOME="/root" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-mods \
  VIRTUAL_ENV=/lsiopy \
  PATH="/lsiopy/bin:$PATH"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    alpine-release \
    bash \
    ca-certificates \
    coreutils \
    curl \
    jq \
    netcat-openbsd \
    procps-ng \
    shadow \
    tzdata && \
  echo "**** create abc user and make our folders ****" && \
  groupmod -g 1000 users && \
  useradd -u 1000 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p \
    /app \
    /config \
    /defaults \
    /lsiopy && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

#nginx install
ARG BUILD_DATE
ARG VERSION
ARG NGINX_VERSION
ENV TZ=Asia/Shanghai
ENV PUID=1000
ENV PGID=1000
ENV MIRROR=https://mirrors.tuna.tsinghua.edu.cn/alpine
LABEL org.opencontainers.image.title=Nginx
LABEL build_version="MAENE version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="MAENE"

# install packages
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    apache2-utils \
    nginx \
    git \
    logrotate \
    nano \
    openssl

COPY buildfile/ /buildfile

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    gcc \
    make \
    g++ \
    zlib-dev \
    gd-dev \
    linux-headers \
    libmaxminddb-dev \
    brotli-dev \
    zeromq-dev \
    hiredis-dev \
    pcre \
    luajit-dev \
    zlib-dev \
    libxml2-dev \
    geoip-dev \
    perl-dev \
    pcre-dev \
    pcre2-dev \
    openssl-dev \
    jansson-dev \
    musl-dev \
    libxslt-dev && \
  echo "**** build nginx ****" && \
  NGINX_VERSION=1.24.0 && \
  echo "**** download nginx ****" && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O /buildfile/nginx-${NGINX_VERSION}.tar.gz && \
  tar -zxvf /buildfile/nginx-${NGINX_VERSION}.tar.gz -C /buildfile/ && \
  git clone -b v0.3.2 https://mirror.ghproxy.com/https://github.com/vision5/ngx_devel_kit /buildfile/model/ngx_devel_kit && \
  git clone -b v2.0 https://mirror.ghproxy.com/https://github.com/Lax/traffic-accounting-nginx-module /buildfile/model/traffic-accounting-nginx-module && \
  git clone -b v0.06 https://mirror.ghproxy.com/https://github.com/openresty/array-var-nginx-module /buildfile/model/array-var-nginx-module && \
  git clone -b 0.2.1 https://mirror.ghproxy.com/https://github.com/kjdev/nginx-auth-jwt /buildfile/model/nginx-auth-jwt && \
  git clone -b v1.0.0rc https://mirror.ghproxy.com/https://github.com/google/ngx_brotli /buildfile/model/ngx_brotli && \
  git clone -b 2.5.3 https://mirror.ghproxy.com/https://github.com/nginx-modules/ngx_cache_purge /buildfile/model/ngx_cache_purge && \
  git clone -b v1.1.0 https://mirror.ghproxy.com/https://github.com/AirisX/nginx_cookie_flag_module /buildfile/model/nginx_cookie_flag_module && \
  git clone -b v3.0.0 https://mirror.ghproxy.com/https://github.com/arut/nginx-dav-ext-module /buildfile/model/nginx-dav-ext-module && \
  git clone -b v0.63 https://mirror.ghproxy.com/https://github.com/openresty/echo-nginx-module /buildfile/model/echo-nginx-module && \
  git clone -b v0.09 https://mirror.ghproxy.com/https://github.com/openresty/encrypted-session-nginx-module /buildfile/model/encrypted-session-nginx-module && \
  git clone -b v0.5.2 https://mirror.ghproxy.com/https://github.com/aperezdc/ngx-fancyindex /buildfile/model/ngx-fancyindex && \
  git clone -b 3.4 https://mirror.ghproxy.com/https://github.com/leev/ngx_http_geoip2_module /buildfile/model/ngx_http_geoip2_module && \
  git clone -b v0.34 https://mirror.ghproxy.com/https://github.com/openresty/headers-more-nginx-module /buildfile/model/headers-more-nginx-module && \
  git clone -b 0.1.0 https://mirror.ghproxy.com/https://github.com/kjdev/nginx-keyval /buildfile/model/nginx-keyval && \
  git clone -b v1.0.0 https://mirror.ghproxy.com/https://github.com/danifbento/nginx-log-zmq /buildfile/model/nginx-log-zmq && \
  git clone -b v0.10.24 https://mirror.ghproxy.com/https://github.com/openresty/lua-nginx-module  /buildfile/model/lua-nginx-module && \
  git clone -b v0.07 https://mirror.ghproxy.com/https://github.com/openresty/lua-upstream-nginx-module /buildfile/model/lua-upstream-nginx-module && \
  git clone -b 1.3 https://mirror.ghproxy.com/https://github.com/nbs-system/naxsi /buildfile/model/naxsi && \
  git clone -b v1.3.6 https://mirror.ghproxy.com/https://github.com/slact/nchan /buildfile/model/nchan && \
  git clone -b v0.15 https://mirror.ghproxy.com/https://github.com/openresty/redis2-nginx-module /buildfile/model/redis2-nginx-module && \
  git clone -b v0.33 https://mirror.ghproxy.com/https://github.com/openresty/set-misc-nginx-module /buildfile/model/set-misc-nginx-module && \
  git clone -b v2.0.1 https://mirror.ghproxy.com/https://github.com/nginx-shib/nginx-http-shibboleth /buildfile/model/nginx-http-shibboleth && \
  git clone -b v1.1 https://mirror.ghproxy.com/https://github.com/ajax16384/ngx_http_untar_module /buildfile/model/ngx_http_untar_module && \
  git clone -b 2.3.0 https://mirror.ghproxy.com/https://github.com/fdintino/nginx-upload-module /buildfile/model/nginx-upload-module && \
  git clone https://mirror.ghproxy.com/https://github.com/masterzen/nginx-upload-progress-module /buildfile/model/nginx-upload-progress-module && \
  git clone -b 0.1.3 https://mirror.ghproxy.com/https://github.com/itoffshore/nginx-upstream-fair /buildfile/model/nginx-upstream-fair && \
  git clone -b 1.4.0 https://mirror.ghproxy.com/https://github.com/nicholaschiasson/ngx_upstream_jdomain /buildfile/model/ngx_upstream_jdomain && \
  git clone -b 1.31 https://mirror.ghproxy.com/https://github.com/kaltura/nginx-vod-module /buildfile/model/nginx-vod-module && \
  git clone -b v0.2.1 https://mirror.ghproxy.com/https://github.com/vozlt/nginx-module-vts /buildfile/model/nginx-module-vts && \
  git clone -b 1.3.0 https://mirror.ghproxy.com/https://github.com/evanmiller/mod_zip /buildfile/model/mod_zip && \
  git clone -b v1.2.2 https://mirror.ghproxy.com/https://github.com/arut/nginx-rtmp-module /buildfile/model/nginx-rtmp-module && \
  git clone -b v0.6.4 https://mirror.ghproxy.com/https://github.com/yaoweibin/ngx_http_substitutions_filter_module /buildfile/model/ngx_http_substitutions_filter_module && \
  echo "**** git apply patch ****" && \
  cd /buildfile/model/lua-nginx-module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/lua-nginx-module~disable-http2-in-body-read.patch /buildfile/patch/lua-nginx-module~fix-handling-new-list-elements.patch /buildfile/patch/lua-nginx-module~fix-shdict-number.patch && \
  cd /buildfile/model/naxsi && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/naxsi~assert.patch /buildfile/patch/naxsi~ff-header.patch /buildfile/patch/naxsi~compat.patch && \
  wget https://github.com/arut/nginx-dav-ext-module/pull/56.patch -O /buildfile/patch/nginx-dav-ext-module~pr-56.patch && \
  wget https://github.com/arut/nginx-dav-ext-module/commit/bbf93f75ca58657fb0f8376b0898f854f13cef91.patch -O /buildfile/patch/nginx-dav-ext-module~pr-62.patch && \
  cd /buildfile/model/nginx-dav-ext-module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx-dav-ext-module~pr-56.patch /buildfile/patch/nginx-dav-ext-module~pr-62.patch && \
  cd /buildfile/model/traffic-accounting-nginx-module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/traffic-accounting-nginx-module~disable-stream-module.patch /buildfile/patch/traffic-accounting-nginx-module~fix-memory-leak.patch && \
  cd /buildfile/model/nginx_cookie_flag_module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx_cookie_flag_module~fix-mem-allocations.patch && \
  wget https://github.com/masterzen/nginx-upload-progress-module/compare/master...msva:nginx-upload-progress-module:master.diff -O /buildfile/patch/nginx-upload-progress-module:master.patch && \
  cd /buildfile/model/nginx-upload-progress-module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx-upload-progress-module:master.patch &&\
  cd /buildfile/model/nginx-http-shibboleth && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx-http-shibboleth~update-handling-multiple-headers.patch /buildfile/patch/nginx-http-shibboleth~fix-crash-uninitialized-pointer.patch && \
  cd /buildfile/model/ngx-fancyindex && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/ngx-fancyindex~fix-404-on-fs-root.patch /buildfile/patch/ngx-fancyindex~fix-missing-saturday.patch && \
  cd /buildfile/model/nchan && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nchan~dont-fail-redis-cluster-before-consensus.patch /buildfile/patch/nchan~fix-redis-race-condition.patch && \
  cd /buildfile/model/nginx-upload-module && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx-upload-module~fixes.patch && \
  cd /buildfile/model/nginx-module-vts && \
  git apply --reject --ignore-space-change --ignore-whitespace /buildfile/patch/nginx-module-vts~fixes.patch && \
  export LUAJIT_LIB="$(pkgconf --variable=libdir luajit)" && \
	export LUAJIT_INC="$(pkgconf --variable=includedir luajit)" && \
  export NGX_HTTP_KEYVAL_ZONE_REDIS=1 && \
  echo "**** start build nginx ****" && \
  cd /buildfile/nginx-${NGINX_VERSION} && /buildfile/nginx-${NGINX_VERSION}/configure --prefix=/var/lib/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --pid-path=/run/nginx/nginx.pid --lock-path=/run/nginx/nginx.lock --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --with-perl_modules_path=/usr/lib/perl5/vendor_perl --user=nginx --group=nginx --with-threads --with-file-aio --without-pcre2 --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --add-module=/buildfile/model/ngx_http_substitutions_filter_module --add-dynamic-module=/buildfile/model/ngx_devel_kit  --add-dynamic-module=/buildfile/model/traffic-accounting-nginx-module  --add-dynamic-module=/buildfile/model/array-var-nginx-module  --add-dynamic-module=/buildfile/model/nginx-auth-jwt  --add-dynamic-module=/buildfile/model/ngx_brotli  --add-dynamic-module=/buildfile/model/ngx_cache_purge  --add-dynamic-module=/buildfile/model/nginx_cookie_flag_module  --add-dynamic-module=/buildfile/model/nginx-dav-ext-module  --add-dynamic-module=/buildfile/model/echo-nginx-module  --add-dynamic-module=/buildfile/model/encrypted-session-nginx-module  --add-dynamic-module=/buildfile/model/ngx-fancyindex  --add-dynamic-module=/buildfile/model/ngx_http_geoip2_module  --add-dynamic-module=/buildfile/model/headers-more-nginx-module  --add-dynamic-module=/buildfile/model/nginx-keyval  --add-dynamic-module=/buildfile/model/nginx-log-zmq  --add-dynamic-module=/buildfile/model/lua-nginx-module  --add-dynamic-module=/buildfile/model/lua-upstream-nginx-module  --add-dynamic-module=/buildfile/model/nchan  --add-dynamic-module=/buildfile/model/redis2-nginx-module  --add-dynamic-module=/buildfile/model/set-misc-nginx-module  --add-dynamic-module=/buildfile/model/nginx-http-shibboleth  --add-dynamic-module=/buildfile/model/ngx_http_untar_module  --add-dynamic-module=/buildfile/model/nginx-upload-module   --add-dynamic-module=/buildfile/model/nginx-upstream-fair  --add-dynamic-module=/buildfile/model/ngx_upstream_jdomain  --add-dynamic-module=/buildfile/model/nginx-vod-module  --add-dynamic-module=/buildfile/model/nginx-module-vts  --add-dynamic-module=/buildfile/model/mod_zip  --add-dynamic-module=/buildfile/model/nginx-rtmp-module --add-dynamic-module=/buildfile/model/naxsi/naxsi_src --add-dynamic-module=/buildfile/model/nginx-upload-progress-module && \
  sed -i '3s/-Werror//g' /buildfile/nginx-${NGINX_VERSION}/objs/Makefile && \
  make && \
  make install && \
  apk del \
    gcc \
    make \
    g++ \
    zlib-dev \
    gd-dev \
    linux-headers \
    libmaxminddb-dev \
    brotli-dev \
    zeromq-dev \
    hiredis-dev \
    zlib-dev \
    libxml2-dev \
    geoip-dev \
    luajit-dev \
    perl-dev \
    pcre-dev \
    pcre2-dev \
    openssl-dev \
    jansson-dev \
    musl-dev \
    libxslt-dev && \
    rm -r /buildfile && \
  apk add --no-cache \
    nginx-mod-http-brotli \
    nginx-mod-http-dav-ext \
    nginx-mod-http-echo \
    nginx-mod-http-fancyindex \
    nginx-mod-http-geoip \
    nginx-mod-http-geoip2 \
    nginx-mod-http-headers-more \
    nginx-mod-http-image-filter \
    nginx-mod-http-perl \
    nginx-mod-http-redis2 \
    nginx-mod-http-set-misc \
    nginx-mod-http-upload-progress \
    nginx-mod-http-xslt-filter \
    nginx-mod-mail \
    nginx-mod-rtmp \
    nginx-mod-stream \
    nginx-mod-stream-geoip \
    nginx-mod-stream-geoip2 \
    nginx-vim && \
  echo "**** configure nginx ****" && \
  echo 'fastcgi_param  HTTP_PROXY         ""; # https://httpoxy.org/' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  PATH_INFO          $fastcgi_path_info; # http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name; # https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/#connecting-nginx-to-php-fpm' >> \
    /etc/nginx/fastcgi_params && \
  echo 'fastcgi_param  SERVER_NAME        $host; # Send HTTP_HOST as SERVER_NAME. If HTTP_HOST is blank, send the value of server_name from nginx (default is `_`)' >> \
    /etc/nginx/fastcgi_params && \
  rm -f /etc/nginx/conf.d/stream.conf && \
  rm -f /etc/nginx/http.d/default.conf && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" \
    /etc/logrotate.conf && \
  sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
    /etc/periodic/daily/logrotate

# add local files
COPY root/ /

ENTRYPOINT ["/init"]

EXPOSE 80 443

VOLUME /config


