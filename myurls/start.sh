#/bin/sh

sed -i "s#https://s.ops.ci#https://${MYURLS_DOMAIN}#g" /app/public/index.html

/app/myurls -domain ${MYURLS_DOMAIN} -conn ${REDIS_URL}:${REDIS_PORT} -passwd ${REDIS_PASSWORD} -ttl ${MYURLS_TTL}
