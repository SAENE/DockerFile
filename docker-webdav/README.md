# Apache WebDAV（LinuxServer 风格）

这是一个基于 `ghcr.io/linuxserver/baseimage-ubuntu:noble` 的 Apache WebDAV
镜像。它使用 s6-overlay 管理进程，并遵循 LinuxServer 常见的运行方式：

- `PUID`、`PGID` 控制 Apache 工作进程和文件所有者；
- `TZ` 控制容器时区；
- `/config` 统一保存 Apache 配置、认证文件和 DAV 锁状态；
- `/data` 是唯一的 WebDAV 数据目录；
- `UMASK` 控制新建文件和目录的默认权限；
- 首次启动生成配置，之后可直接编辑持久化配置。

这不是 LinuxServer.io 官方镜像，只是使用其基础镜像和目录约定。

## 挂载结构

```text
/config/
├── README.md                   # 配置目录内的使用说明
├── httpd.conf                  # Apache 模块、进程、监听、日志和通用配置
├── webdav.conf                 # DAV、认证、锁和数据目录配置主体
├── webdav.conf.sample          # 带完整注释的镜像参考配置
├── auth/
│   └── users.htpasswd          # bcrypt Basic Auth 用户库
├── conf.d/
│   └── *.conf                  # 自定义追加配置
└── locks/
    └── DavLock.*               # WebDAV 锁数据库

/data/                          # 客户端看到的 WebDAV 根目录
```

## 快速启动

```bash
cd apache-webdav
cp .env.example .env
mkdir -p data
```

修改 `.env`，至少填写 `WEBDAV_PASSWORD`，然后运行：

```bash
docker compose up -d --build
```

默认地址是 `http://127.0.0.1:8080/`。首次启动后，宿主机会出现 `config/`
和 `data/` 两个目录。

## Compose 示例

```yaml
services:
  webdav:
    image: local/apache-webdav:latest
    container_name: apache-webdav
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Tokyo
      - UMASK=022
      - WEBDAV_AUTH=basic
      - WEBDAV_USERNAME=webdav
      - WEBDAV_PASSWORD=替换为强密码
      - WEBDAV_CHOWN=false
    volumes:
      - ./config:/config
      - ./data:/data
    ports:
      - 8080:80
    restart: unless-stopped
```

`PUID` 和 `PGID` 建议填写实际管理文件的宿主机用户：

```bash
id -u
id -g
```

## 环境变量

下表中的默认值是仓库所附 `compose.yaml` 的默认值。直接使用 `docker run` 且不传
`PUID`、`PGID` 或 `TZ` 时，则沿用 LinuxServer 基础镜像的默认值。

| 环境变量 | Compose 默认值 | 具体行为 |
|---|---:|---|
| `PUID` | `1000` | 启动前把容器用户 `abc` 改成这个 UID；Apache 工作进程和新建文件使用该 UID |
| `PGID` | `1000` | 启动前把容器组 `abc` 改成这个 GID；Apache 工作进程和新建文件使用该 GID |
| `TZ` | `Asia/Tokyo` | 设置容器时区，影响日志时间等；使用 IANA 名称，例如 `Asia/Shanghai` |
| `UMASK` | `022` | Apache 启动前设置的 umask；例如 `022` 通常得到文件 `644`、目录 `755`，`002` 通常得到文件 `664`、目录 `775` |
| `WEBDAV_PORT` | `8080` | 仅供 Compose 使用，把宿主机此端口映射到容器固定的 `80` 端口 |
| `WEBDAV_AUTH` | `basic` | `basic` 使用 Apache Basic Auth；`none` 完全关闭 `/data` 的认证 |
| `WEBDAV_USERNAME` | `webdav` | Basic Auth 用户名，不能为空且不能包含冒号 |
| `WEBDAV_PASSWORD` | 空 | `basic` 模式首次启动且用户库不存在时必填；非空时每次启动都会创建或更新指定用户 |
| `WEBDAV_USERNAME_FILE` | 未设置 | 从指定文件第一行读取用户名，用于 Docker secrets；不能同时设置 `WEBDAV_USERNAME` |
| `WEBDAV_PASSWORD_FILE` | 未设置 | 从指定文件第一行读取密码，用于 Docker secrets；不能同时设置 `WEBDAV_PASSWORD` |
| `WEBDAV_CHOWN` | `false` | 默认不改动 `/data`；设为 `true` 时，每次启动递归修正其所有权。无论此值如何，`/config` 都会修正 |

环境变量负责容器启动行为，不会重写已经存在的 `httpd.conf` 或 `webdav.conf`。
`WEBDAV_CHOWN` 默认关闭，以免大数据目录在每次启动时被递归扫描。启动前必须自行
保证 `PUID:PGID` 对 `/data` 有读写权限。例如使用当前宿主机用户管理文件时：

```bash
mkdir -p data
sudo chown -R "$(id -u):$(id -g)" data
```

如果使用其他 `PUID`、`PGID`，请把命令中的 UID/GID 换成对应数值。也可以在首次
启动时临时设置 `WEBDAV_CHOWN=true` 完成递归修正，之后再改回 `false`。使用空的
Docker named volume 时尤其要注意其初始所有权，否则 Apache 可以启动，但上传、
建目录等写操作会因权限不足而失败。

## 认证文件

密码会以 bcrypt 哈希保存在：

```text
/config/auth/users.htpasswd
```

只要该文件已经存在，后续启动可以不再传入 `WEBDAV_PASSWORD`。也可以直接编辑
或替换它，从而维护多个用户：

```bash
docker exec -u abc -it apache-webdav \
  htpasswd -B /config/auth/users.htpasswd another-user
```

生产环境建议使用 Docker secret 或只读 secret 文件：

```yaml
environment:
  WEBDAV_PASSWORD_FILE: /run/secrets/webdav_password
volumes:
  - ./webdav-password:/run/secrets/webdav_password:ro
```

使用 `WEBDAV_USERNAME_FILE` 时不要同时设置 `WEBDAV_USERNAME`；密码变量同理。

如果认证由前置 Nginx 完成，可以设置 `WEBDAV_AUTH=none`。此模式下务必确保容器
的 80 端口只在可信 Docker 网络或内网可达，不能直接暴露到公网。

## 配置文件的生成和持久化

配置分为“活动文件”和“镜像参考文件”。启动脚本对它们的处理方式不同：

| 路径 | 启动时的处理 | 是否被 Apache 加载 |
|---|---|---:|
| `/config/httpd.conf` | 仅在不存在时从 `/defaults/httpd.conf` 创建，之后永不自动覆盖 | 是 |
| `/config/webdav.conf` | 仅在不存在时从 `/defaults/webdav.conf` 创建，之后永不自动覆盖 | 是 |
| `/config/webdav.conf.sample` | 每次启动从镜像刷新，用户修改会被覆盖 | 否 |
| `/config/README.md` | 每次启动从镜像刷新 | 否 |
| `/config/auth/users.htpasswd` | 由认证环境变量创建或更新 | 认证时读取 |
| `/config/locks/DavLock.*` | Apache 在运行期间维护 | 运行时读写 |

因此重建或升级镜像不会覆盖两个活动配置。要修改服务，应编辑
`/config/httpd.conf` 或 `/config/webdav.conf`，不要编辑 `.sample` 文件。

## Apache 配置加载顺序

加载关系固定如下：

```text
/config/httpd.conf
├── Include "/config/webdav.conf"
└── IncludeOptional "/config/conf.d/*.conf"
```

Apache 从上到下解析配置：

1. `httpd.conf` 先加载所有模块并设置服务器级参数；
2. `webdav.conf` 定义 WebDAV 数据目录、认证、锁和请求策略；
3. `conf.d/*.conf` 按文件名顺序最后加载，用于用户追加配置。

`webdav.conf` 使用的模块必须在它被包含之前加载，所以所有 `LoadModule` 都集中
放在 `httpd.conf`。不要再把 `LoadModule` 写进 `webdav.conf` 或 `.sample`。

## `httpd.conf` 详解

`httpd.conf` 只负责 Apache 本身和模块加载，不放具体的 WebDAV 目录规则。

### 基础运行参数

| 指令 | 当前值 | 作用 |
|---|---|---|
| `ServerRoot` | `/etc/apache2` | Apache 安装目录，不是 WebDAV 数据目录 |
| `DefaultRuntimeDir` | `/run/apache2` | PID 等临时运行文件的位置，不需要持久化 |
| `PidFile` | `/run/apache2/apache2.pid` | Apache 主进程 PID 文件 |
| `Listen` | `80` | 容器内部监听端口；通常只改 Compose 的 `WEBDAV_PORT`，不要改这里 |
| `User` / `Group` | `abc` | 请求工作进程使用的用户和组；基础镜像会按 `PUID`、`PGID` 修改其数字 ID |
| `Timeout` | `3600` | Apache 等待部分网络操作完成的最长时间，适合较慢的大文件操作 |
| `KeepAlive` | `On` | 允许一个 TCP 连接处理多个请求 |
| `MaxKeepAliveRequests` | `1000` | 单连接最多处理的请求数 |
| `KeepAliveTimeout` | `5` | 空闲 keep-alive 连接等待秒数 |

日志直接发送到容器标准输出和标准错误，因此使用下面的命令查看：

```bash
docker logs -f apache-webdav
```

`ServerTokens Prod`、`ServerSignature Off` 和 `TraceEnable Off` 用于减少版本信息
暴露并禁用 TRACE。`EnableMMAP Off` 与 `EnableSendfile Off` 可以避免部分 Docker
卷、网络存储或 FUSE 文件系统上的缓存一致性问题。

根目录先使用下面的规则默认拒绝访问，之后只由 `webdav.conf` 精确开放 `/data`
和健康检查目录：

```apache
<Directory "/">
    AllowOverride None
    Require all denied
</Directory>
```

### 已加载模块

| 模块 | 被哪些配置使用 |
|---|---|
| `mpm_event` | Apache 事件型工作进程模型 |
| `authn_core`、`authz_core`、`authz_host` | 认证与授权基础，以及 `Require all`、`Require ip` |
| `authn_file`、`authz_user`、`auth_basic` | 从 `users.htpasswd` 执行 Basic Auth 和 `Require valid-user` |
| `dav`、`dav_fs` | WebDAV 方法、文件系统后端和锁数据库 |
| `reqtimeout` | `RequestReadTimeout` |
| `headers` | `Header always set` 安全响应头 |
| `autoindex` | 浏览器目录列表及 `IndexOptions` |
| `dir` | `DirectoryIndex disabled` |
| `alias` | `/.webdav-health` 健康检查映射 |
| `mime` | `/etc/mime.types` 文件类型映射 |

删除某个模块前，必须同时删除依赖该模块的指令，否则 `apache2 -t` 会报告未知
指令并阻止服务启动。

## `webdav.conf` 详解

此文件是 WebDAV 配置主体，不包含任何 `LoadModule`。

### 全局 WebDAV 参数

| 指令 | 当前值 | 作用 |
|---|---|---|
| `RequestReadTimeout` | `header=20-40,MinRate=500 body=0` | 限制过慢的请求头；`body=0` 不对大文件请求体设置读取超时 |
| `DirectoryIndex` | `disabled` | 不寻找 `index.html`，访问目录时配合 `Options Indexes` 显示目录列表 |
| `DavLockDB` | `/config/locks/DavLock` | 保存 WebDAV LOCK 状态；属于服务状态，所以放在 `/config` 而非 `/data` |
| `DocumentRoot` | `/data` | URL 根路径 `/` 对应的文件目录 |

s6 启动就绪探针和 Docker HEALTHCHECK 使用公开的 `/.webdav-health`。该地址只
映射到镜像内一个内容为 `ok` 的静态文件，不会绕过 `/data` 的认证。

## 健康检查

健康检查不是 WebDAV 协议本身的必需项，但镜像保留了两种用途不同的检查：

- s6 在 Apache 启动时轮询 `/.webdav-health`，成功一次后即停止，用于确认服务
  已经可以接受 HTTP 请求；
- Docker 每 30 秒请求一次同一地址，用于在 `docker ps` 中显示 `healthy` 或
  `unhealthy`，并供 Compose、监控或其他编排工具读取。

s6 的内联检查由 execline 解析，不是 shell 命令，因此不能使用 `>/dev/null`。
当前命令使用 curl 自己的 `-o /dev/null` 参数，不会再把重定向符误认为 URL，也
不会把响应正文 `ok` 写进容器日志。

如果只是不需要 Docker 的持续健康状态，可以在 Compose 服务中加入：

```yaml
healthcheck:
  disable: true
```

这不会关闭 s6 启动阶段的一次性就绪确认，也不影响 WebDAV 功能。若连端点也要
删除，则需要同时修改 s6 服务脚本、Dockerfile 的 `HEALTHCHECK` 以及
`webdav.conf` 中的 `Alias`，不建议只删除其中一处。

### `/data` 目录规则

| 指令 | 作用 |
|---|---|
| `Dav On` | 为 `/data` 启用 WebDAV 方法 |
| `AllowOverride None` | 禁用 `.htaccess`，所有规则统一由 `/config` 管理 |
| `Options Indexes` | 允许普通浏览器 GET 请求查看目录列表 |
| `IndexOptions ...` | 设置目录列表为表格、自然版本排序和 UTF-8 |
| `LimitRequestBody 0` | Apache 端不限制上传请求体大小；前置代理仍需单独放宽限制 |
| `AuthType Basic` | 使用 HTTP Basic Auth |
| `AuthBasicProvider file` | 从文件型用户库校验密码 |
| `AuthUserFile` | 指向 `/config/auth/users.htpasswd` |
| `Require valid-user` | 用户库中任意验证成功的用户均可访问 |
| `Header always set ...` | 添加 `nosniff` 和 `no-referrer` 响应头 |

认证模式由启动参数决定：

- `WEBDAV_AUTH=basic`：Apache 不定义 `WEBDAV_NO_AUTH`，加载
  `<IfDefine !WEBDAV_NO_AUTH>` 中的 Basic Auth 配置；
- `WEBDAV_AUTH=none`：启动脚本添加 `-DWEBDAV_NO_AUTH`，加载
  `<IfDefine WEBDAV_NO_AUTH>` 中的 `Require all granted`。

`WEBDAV_AUTH=none` 是完全匿名读写，不只是关闭登录提示。只能在可信内网或已经
完成认证的反向代理后使用。

## 常见配置修改

### 禁止浏览器列出目录

在 `webdav.conf` 的 `<Directory "/data">` 中把：

```apache
Options Indexes
```

改成：

```apache
Options None
```

WebDAV 客户端仍可使用 `PROPFIND`，但普通浏览器 GET 目录会收到禁止访问响应。

### 改为只读 WebDAV

只读限制必须替换两个认证分支原有的授权指令，不能在现有
`Require valid-user` 后面简单追加另一个 `Require`。将相关部分改为：

```apache
<IfDefine WEBDAV_NO_AUTH>
    Require method GET HEAD OPTIONS PROPFIND
</IfDefine>

<IfDefine !WEBDAV_NO_AUTH>
    AuthType Basic
    AuthName "WebDAV"
    AuthBasicProvider file
    AuthUserFile "/config/auth/users.htpasswd"

    <RequireAll>
        Require valid-user
        Require method GET HEAD OPTIONS PROPFIND
    </RequireAll>
</IfDefine>
```

这会拒绝 `PUT`、`DELETE`、`MKCOL`、`COPY`、`MOVE`、`LOCK`、`UNLOCK` 等写入
方法。`basic` 模式下读取仍需登录；`none` 模式下允许匿名读取。

不要使用“保留 `Require valid-user`，再追加 `<LimitExcept>`”的写法。Apache 的
授权指令存在组合与合并规则，这种写法可能让已经通过认证的用户继续获得写权限。

### 限制单次上传大小

`LimitRequestBody` 的单位是字节。例如限制为 10 GiB：

```apache
LimitRequestBody 10737418240
```

使用 Nginx、CDN 或其他反向代理时，还必须同步调整代理端的请求体限制和超时。

### 同时要求登录和内网来源

在 `<IfDefine !WEBDAV_NO_AUTH>` 中用下面的块替换原来的
`Require valid-user`，不要保留两份并列的 `Require`：

```apache
<RequireAll>
    Require valid-user
    Require ip 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
</RequireAll>
```

如果还同时启用了只读模式，则在同一个 `<RequireAll>` 中再加入：

```apache
Require method GET HEAD OPTIONS PROPFIND
```

如果 Apache 前面还有反向代理，`Require ip` 默认看到的可能是代理容器地址；这时
需要正确配置可信代理和客户端 IP 传递，不能直接照抄白名单。

### 添加独立的附加配置

服务器级附加项可以新建到 `/config/conf.d/*.conf`，例如：

```apache
# /config/conf.d/local.conf
LogLevel info
```

这些文件最后加载。涉及认证、授权、DAV 开关或现有 `<Directory "/data">` 的
核心规则时，建议直接修改 `webdav.conf`，避免 Apache 配置段合并规则带来意外。

## `.sample`、恢复默认值与升级

`webdav.conf.sample` 是带完整注释且语法有效的参考文件，约定类似 LinuxServer
Nginx 的 `.sample` 文件：它不参与运行，并会在每次容器启动时刷新。可用它恢复
WebDAV 配置，但应先备份活动文件：

```bash
docker exec apache-webdav \
  cp /config/webdav.conf /config/webdav.conf.bak

docker exec apache-webdav \
  cp /config/webdav.conf.sample /config/webdav.conf
```

要恢复不带说明注释的镜像默认配置，或恢复 `httpd.conf`：

```bash
docker exec apache-webdav \
  cp /defaults/webdav.conf /config/webdav.conf

docker exec apache-webdav \
  cp /defaults/httpd.conf /config/httpd.conf
```

镜像升级后可比较新版默认值与持久化配置：

```bash
docker exec apache-webdav diff -u \
  /defaults/httpd.conf /config/httpd.conf

docker exec apache-webdav diff -u \
  /defaults/webdav.conf /config/webdav.conf
```

活动文件永不自动迁移。若旧配置仍把 WebDAV 模块写在 `webdav.conf`，它可以继续
成套运行；要采用当前拆分方式，必须同时把相关 `LoadModule` 移入 `httpd.conf`
并从 `webdav.conf` 删除。不要只用新版 sample 覆盖旧 `webdav.conf`，否则旧版
`httpd.conf` 可能没有加载 DAV、认证等必要模块。

## 检查和应用配置

修改后先检查完整配置：

```bash
docker exec apache-webdav \
  apache2 -t -f /config/httpd.conf
```

查看最终加载的模块：

```bash
docker exec apache-webdav \
  apache2 -M -f /config/httpd.conf
```

确认输出包含 `Syntax OK` 后重启：

```bash
docker restart apache-webdav
```

容器每次启动也会自动执行同样的语法检查；配置错误时 Apache 服务不会启动，
详细原因可通过 `docker logs apache-webdav` 查看。

相关 Apache 官方文档：

- [Apache 核心指令](https://httpd.apache.org/docs/current/mod/core.html)
- [`mod_dav` 和 WebDAV 配置](https://httpd.apache.org/docs/current/mod/mod_dav.html)
- [`mod_dav_fs` 与 `DavLockDB`](https://httpd.apache.org/docs/current/mod/mod_dav_fs.html)
- [`mod_reqtimeout` 与 `RequestReadTimeout`](https://httpd.apache.org/docs/current/mod/mod_reqtimeout.html)
- [认证与授权](https://httpd.apache.org/docs/current/howto/auth.html)
- [配置段的合并顺序](https://httpd.apache.org/docs/current/sections.html)

## WebDAV 验证

```bash
curl -u 'webdav:你的密码' -i -X OPTIONS http://127.0.0.1:8080/

curl -u 'webdav:你的密码' -i -X PROPFIND \
  -H 'Depth: 0' http://127.0.0.1:8080/

curl -u 'webdav:你的密码' -i -X MKCOL \
  http://127.0.0.1:8080/test/

curl -u 'webdav:你的密码' -T ./README.md \
  http://127.0.0.1:8080/test/README.md
```

镜像启用了完整的 `mod_dav`/`mod_dav_fs`，支持 `PROPFIND`、`MKCOL`、
`COPY`、`MOVE`、`LOCK` 和 `UNLOCK`。请求体大小不设上限，慢速大文件上传也不会
触发 Apache 的请求体读取超时。

## Nginx 反向代理

Basic Auth 不能保护明文 HTTP 上的密码，公网使用时应在前置 Nginx 上终止
HTTPS。当前仓库已经提供：

- `nginx-migrated/site-confs/templates/webdav-proxy.conf.template`
- `nginx-migrated/include/proxy/webdav.conf`

Apache WebDAV 默认位于后端根路径。最稳妥的做法是让公开 URL 也位于域名根
路径，并在 Nginx 模板中把 `__UPSTREAM_PREFIX__` 留空。若公开路径和后端路径
不同，PROPFIND 响应中的 `<href>` 可能仍是后端路径，部分客户端会解析失败。

认证只保留一层：

- Apache 认证：`WEBDAV_AUTH=basic`，Nginx 不再启用另一套 Basic Auth；
- Nginx 认证：`WEBDAV_AUTH=none`，Apache 端口只连接到可信内部网络。
