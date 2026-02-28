基于Linuxserver/docker-baseimage-alpine-nginx编写，编译Ngin，去除了PHP

nginx编译参数（参考[alpine](https://git.alpinelinux.org/aports/tree/main/nginx?h=3.18-stable)官方编译）：

```Linux
./configure --prefix=/var/lib/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --pid-path=/run/nginx/nginx.pid --lock-path=/run/nginx/nginx.lock --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --with-perl_modules_path=/usr/lib/perl5/vendor_perl --user=nginx --group=nginx --with-threads --with-file-aio --without-pcre2 --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --add-module=/buildfile/model/ngx_http_substitutions_filter_module --add-dynamic-module=/buildfile/model/ngx_devel_kit  --add-dynamic-module=/buildfile/model/traffic-accounting-nginx-module  --add-dynamic-module=/buildfile/model/array-var-nginx-module  --add-dynamic-module=/buildfile/model/nginx-auth-jwt  --add-dynamic-module=/buildfile/model/ngx_brotli  --add-dynamic-module=/buildfile/model/ngx_cache_purge  --add-dynamic-module=/buildfile/model/nginx_cookie_flag_module  --add-dynamic-module=/buildfile/model/nginx-dav-ext-module  --add-dynamic-module=/buildfile/model/echo-nginx-module  --add-dynamic-module=/buildfile/model/encrypted-session-nginx-module  --add-dynamic-module=/buildfile/model/ngx-fancyindex  --add-dynamic-module=/buildfile/model/ngx_http_geoip2_module  --add-dynamic-module=/buildfile/model/headers-more-nginx-module  --add-dynamic-module=/buildfile/model/nginx-keyval  --add-dynamic-module=/buildfile/model/nginx-log-zmq  --add-dynamic-module=/buildfile/model/lua-nginx-module  --add-dynamic-module=/buildfile/model/lua-upstream-nginx-module  --add-dynamic-module=/buildfile/model/nchan  --add-dynamic-module=/buildfile/model/redis2-nginx-module  --add-dynamic-module=/buildfile/model/set-misc-nginx-module  --add-dynamic-module=/buildfile/model/nginx-http-shibboleth  --add-dynamic-module=/buildfile/model/ngx_http_untar_module  --add-dynamic-module=/buildfile/model/nginx-upload-module   --add-dynamic-module=/buildfile/model/nginx-upstream-fair  --add-dynamic-module=/buildfile/model/ngx_upstream_jdomain  --add-dynamic-module=/buildfile/model/nginx-vod-module  --add-dynamic-module=/buildfile/model/nginx-module-vts  --add-dynamic-module=/buildfile/model/mod_zip  --add-dynamic-module=/buildfile/model/nginx-rtmp-module --add-dynamic-module=/buildfile/model/naxsi/naxsi_src --add-dynamic-module=/buildfile/model/nginx-upload-progress-module
```

关闭了GCC编译时 警告为错误参数，原因是编译 nginx-upload-progress-module 报错

```Linux
make[1]: Entering directory '/buildfile/nginx-1.24.0'
cc -c -fPIC -I/usr/include/luajit-2.1  -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g  -DNDK_SET_VAR -Wno-deprecated-declarations -DNDK_SET_VAR -DNDK_SET_VAR -DNDK_SET_VAR -DNDK_UPSTREAM_LIST -I src/core -I src/event -I src/event/modules -I src/os/unix -I src/http/modules/perl -I /buildfile/model/ngx_devel_kit/objs -I objs/addon/ndk -I /buildfile/model/ngx_devel_kit/src -I /buildfile/model/ngx_devel_kit/objs -I objs/addon/ndk -I /buildfile/model/traffic-accounting-nginx-module -I /usr/include -I /buildfile/model/nginx-log-zmq/src -I /usr/include/luajit-2.1 -I /buildfile/model/lua-nginx-module/src/api -I /buildfile/model/nchan/src -I /usr/include/libxml2 -I /buildfile/model/nginx-rtmp-module -I /usr/include/libxml2 -I objs -I src/http -I src/http/modules -I src/http/v2 -I /buildfile/model/ngx_devel_kit/src -I src/mail -I src/stream \
        -o objs/addon/nginx-upload-progress-module/ngx_http_uploadprogress_module.o \
        /buildfile/model/nginx-upload-progress-module/ngx_http_uploadprogress_module.c
In file included from src/core/ngx_core.h:61,
                 from /buildfile/model/nginx-upload-progress-module/ngx_http_uploadprogress_module.c:8:
/buildfile/model/nginx-upload-progress-module/ngx_http_uploadprogress_module.c: In function 'ngx_http_reportuploads_handler':
src/os/unix/ngx_alloc.h:19:27: error: pointer 'id' may be used after 'free' [-Werror=use-after-free]
   19 | #define ngx_free          free
/buildfile/model/nginx-upload-progress-module/ngx_http_uploadprogress_module.c:985:13: note: in expansion of macro 'ngx_free'
  985 |             ngx_free(id);
      |             ^~~~~~~~
src/os/unix/ngx_alloc.h:19:27: note: call to 'free' here
   19 | #define ngx_free          free
/buildfile/model/nginx-upload-progress-module/ngx_http_uploadprogress_module.c:975:9: note: in expansion of macro 'ngx_free'
  975 |         ngx_free(id);
      |         ^~~~~~~~
cc1: all warnings being treated as errors
make[1]: *** [objs/Makefile:5317: objs/addon/nginx-upload-progress-module/ngx_http_uploadprogress_module.o] Error 1
```

如需编译，请使用
```Linux
DOCKER_BUILDKIT=1 docker build . --network=host
```