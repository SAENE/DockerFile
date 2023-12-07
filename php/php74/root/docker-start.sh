#!/bin/bash
# 创建php文件
printf "date.timezone = %s\\n" "${TZ:-UTC}" >/etc/php82/conf.d/30_timezone.ini
if [[ ! -f /config/php ]]; then
    mkdir /config/php
fi

if [[ ! -f /config/log ]]; then
    mkdir /config/log
    mkdir /config/log/php
fi
chmod -R 644 /etc/logrotate.d

if [[ ! -f /config/php/www2.conf ]]; then
    printf "; Edit this file to override www.conf and php-fpm.conf directives and restart the container\\n\\n; Pool name\\n[www]\\n\\nlisten = 0.0.0.0:9000\\n\\n" >/config/php/www2.conf
fi

if [[ ! -f /config/php/php-local.ini ]]; then
    printf "; Edit this file to override php.ini directives\\n\\n" >/config/php/php-local.ini
fi
# 软链接
rm -rf /usr/local/etc/php/conf.d/php-local.ini
ln -s /config/php/php-local.ini /usr/local/etc/php/conf.d/php-local.ini
rm -rf /usr/local/etc/php-fpm.d/www2.conf
ln -s /config/php/www2.conf /usr/local/etc/php-fpm.d/www2.conf

# 更改文件权限
PUID=${PUID:-911}
PGID=${PGID:-911}
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

echo '
───────────────────────────────────────
GID/UID
───────────────────────────────────────'
echo "
User UID:    $(id -u abc)
User GID:    $(id -g abc)
───────────────────────────────────────
"

chown -R abc:abc /config
/etc/init.d/cron start
php-fpm -F

tail -f /dev/null
