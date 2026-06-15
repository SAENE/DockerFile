FROM alpine:3.22.1
LABEL authors="saene <yqyq2323@gmail.com>"

ENV VERSION="20250315.0"

RUN set -xe && \
    apk add --no-cache iptables ip6tables  curl && \
    curl -fsSLO --compressed "https://github.com/MikeWang000000/udp2raw/releases/download/20250315.0-fakehttp/udp2raw_binaries.tar.gz" && \
    tar -zxvf udp2raw_binaries.tar.gz && \
    cp udp2raw_binaries/udp2raw_amd64 /usr/udp2raw && \
    rm -r udp2raw_* && \
    mv /usr/udp2raw / &&\
    apk del curl 

COPY server.conf /config.conf 
# EXPOSE 900

CMD ["/udp2raw", "--conf-file", "config.conf"]
