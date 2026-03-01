# sing-box-subscribe Docker

本仓库提供 [sing-box-subscribe](https://github.com/Toperlock/sing-box-subscribe) 项目的 Docker 容器封装，方便快速部署和运行。

---

## 🚀 快速启动
```cli
docker run -d \
  --name sing-box-subscribe \
  -p 5000:5000 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -v /你的宿主机路径/config:/config \
  maene/sing-box-subscribe:latest
```

## 文件树
```Tree
./
├── Dockerfile
└── root/
    └── etc/
        └── s6-overlay/
            └── s6-rc.d/
                ├── sing-box-subscribe/
                │   ├── run
                │   └── type
                └── user/
                    └── contents.d/
                        └── sing-box-subscribe
```