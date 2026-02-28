# FundMonitor Docker

本仓库提供 [FundMonitor](https://github.com/MIX-LJ/FundMonitor) 项目的 Docker 容器封装，方便快速部署和运行。

---

## 🚀 快速启动
```cli
docker run -d \
  --name fundmonitor \
  -p 5000:5000 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -v /你的宿主机路径/config:/config \
  fundmonitor:latest
```

## 文件树
```Tree
./
├── Dockerfile
└── root/
    └── etc/
        └── s6-overlay/
            └── s6-rc.d/
                ├── fundmonitor/
                │   ├── run
                │   └── type
                └── user/
                    └── contents.d/
                        └── fundmonitor
```