# 🚀 Traffic-Killer: 极简高性能流量压测/消耗工具

[![Docker Support](https://img.shields.io/badge/Docker-Compatible-blue?logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

`Traffic-Killer` 是一个基于 Linux Shell 编写的高效、多线程、高容错性的流量消耗与网络压测工具。针对容器化环境（Docker）进行了深度适配，支持通过环境变量无缝调节性能参数。内置低速假死剔除、熔断保护等生产级守护机制，确保长时运行不卡死、不僵尸。

---

## ✨ 核心特性

*   **🐋 Docker 原生兼容**：全参数支持环境变量传入，完美契合容器化单兵作战或 Kubernetes 大规模集群部署。
*   **⚡ 真实多线程并行**：基于命名管道（FIFO）实现多进程并发控制，充分榨干物理网卡带宽。
*   **⏱️ 精确限速控制**：支持单线程细粒度限速（如 `2m`、`500k`），轻松规避触发机房恶意流量阈值。
*   **🛡️ 智能防假死守护**：内置低速剔除机制（默认 $5\text{ 秒} < 1\text{KB/s}$ 视为超时），配合硬性全局超时，彻底解决物理断网、重度丢包导致的线程“永久假死”。
*   **💥 自动熔断保护**：当连续请求失败达到阈值（如连续 20 次网络阻断）自动熔断退出，防止无意义的 CPU 轮询空转。
*   **📊 双态可视化输出**：
    *   `INFO` 模式：原地单行干净刷新，适合日常挂机。
    *   `DEBUG` 模式：混态瀑布流，独立统计各线程耗时与实时大盘速度。
*   **🧼 跨版本安全清理**：优雅捕获 `INT`、`TERM`、`EXIT` 信号，剥离终端管辖权（`disown`），退出时绝不残留僵尸进程与垃圾文件。

---

## 🛠️ 核心参数说明

本项目所有核心参数均支持通过环境变量（Environment Variables）进行覆盖：

| 环境变量名 | 默认值 | 示例 / 说明 |
| :--- | :--- | :--- |
| `URL` | `https://img.mcloud.139.com/...` | 测试下载的目标大文件链接（必须支持断点/多次下载） |
| `THREADS` | `4` | 并发下载线程数（建议根据 CPU 核心与带宽调整） |
| `SPEED_LIMIT` | `2m` | 单线程速度上限。`2m` = 2MB/s，`500k` = 500KB/s，`0` 为不限速。**总带宽上限 = THREADS × SPEED_LIMIT** |
| `LOG_MODE` | `INFO` | 日志模式。`INFO`（单行刷新总速度）/ `DEBUG`（显示各线程细节） |
| `MAX_CONTINUOUS_FAILURES` | `20` | 触发自动熔断的连续失败次数上限 |

---

## 🐳 Docker 快速部署

### 1. 极速运行（使用默认参数）
```bash
docker run -d \
  --name traffic-killer \
  --restart unless-stopped \
  -v /dev/null:/dev/null \
  your-registry/traffic-killer:latest
```

### 2. 狂暴模式（高并发、不限速）
```Bash
docker run -d \
  --name traffic-killer-max \
  -e THREADS=16 \
  -e SPEED_LIMIT=0 \
  -e LOG_MODE=INFO \
  your-registry/traffic-killer:latest
```

### 3. 查看实时流量大盘
```Bash
docker logs -f traffic-killer
```

## 💻 原生 Linux 运行指南

如果你选择直接在宿主机运行该脚本，请确保系统已安装 bc 计算器。
### 1. 安装依赖
```Bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y curl bc

# CentOS / RHEL
sudo yum install -y curl bc
```

### 2. 赋予权限并启动
```Bash
chmod +x traffic_killer.sh

# 默认启动
./traffic_killer.sh

# 带参数启动
URL="[https://example.com/test.zip](https://example.com/test.zip)" THREADS=8 SPEED_LIMIT=5m ./traffic_killer.sh
```

## 🧩 生产环境 Dockerfile 推荐

为了让该脚本在 Docker 中完美运行，建议使用以下轻量级 Dockerfile 进行镜像构建：
```Dockerfile
FROM alpine:latest

# 安装基础依赖
RUN apk add --no-cache bash curl bc tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app

# 复制脚本并赋予执行权限
COPY traffic_killer.sh .
RUN chmod +x traffic_killer.sh

# 启动脚本
ENTRYPOINT ["/bin/bash", "./traffic_killer.sh"]
```

# ⚠️ 免责声明

    本工具仅用于授权的网络性能测试、带宽压力测试及容器网络高可用验证。

    请勿将本工具用于非法网络攻击或在未授权的托管环境内刷取异常流量。

    因使用本工具导致的机房停机、账号限速、流量扣费或被服务商判定为违规行为，作者不承担任何法律及经济责任。