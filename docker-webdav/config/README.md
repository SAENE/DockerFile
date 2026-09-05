# Apache WebDAV 配置目录

此目录整体挂载为容器的 `/config`。本文件以及 `webdav.conf.sample` 会在每次
容器启动时从镜像刷新；实际运行配置 `httpd.conf` 和 `webdav.conf` 只会在缺失
时创建，之后不会被镜像覆盖。

## 文件和目录

| 路径 | 用途 | 持久化规则 |
|---|---|---|
| `httpd.conf` | 加载全部 Apache 模块，配置监听、进程、日志及全局安全参数 | 仅缺失时创建 |
| `webdav.conf` | 配置 `/data`、认证、DAV 锁、目录列表、上传及响应头 | 仅缺失时创建 |
| `webdav.conf.sample` | 带注释且语法有效的 WebDAV 参考配置，不被 Apache 加载 | 每次启动刷新 |
| `conf.d/*.conf` | 用户附加配置，在 `webdav.conf` 之后加载 | 用户维护 |
| `auth/users.htpasswd` | bcrypt Basic Auth 用户库 | 启动脚本按环境变量创建或更新 |
| `locks/DavLock.*` | WebDAV LOCK 状态 | Apache 运行时维护 |

`/data` 不在本目录中，它是 WebDAV 客户端看到的文件根目录。

## 加载顺序和职责

```text
httpd.conf
├── webdav.conf
└── conf.d/*.conf
```

`httpd.conf` 中的 `LoadModule` 必须先执行，随后才能解析 `webdav.conf` 使用的
`Dav`、`AuthType`、`Header`、`RequestReadTimeout` 等指令。因此：

- 所有模块统一在 `httpd.conf` 加载；
- `webdav.conf` 不包含 `LoadModule`，只保留 WebDAV 配置主体；
- `conf.d` 适合独立追加项；认证、授权和 `/data` 核心规则建议直接改
  `webdav.conf`。

## `httpd.conf` 关键内容

- 容器内部固定监听 `80`；宿主机端口应通过 Compose 端口映射调整；
- Apache 主进程负责绑定端口，工作进程以 `abc:abc` 运行；`abc` 的数字 UID/GID
  由 `PUID` 和 `PGID` 决定；
- DAV、Basic Auth、请求超时、响应头、目录索引和健康检查所需模块都在这里加载；
- 日志写到 stdout/stderr，使用 `docker logs` 查看；
- `<Directory "/"> Require all denied` 默认拒绝所有文件系统路径，随后由
  `webdav.conf` 仅开放需要的目录；
- 文件末尾包含 `webdav.conf`，再包含 `conf.d/*.conf`。

不要单独删除模块。若模块仍被某条指令使用，Apache 语法检查会失败。

## `webdav.conf` 关键内容

- `RequestReadTimeout ... body=0`：保留请求头防慢速攻击限制，不限制大文件请求体
  的读取时间；
- `DirectoryIndex disabled` 与 `Options Indexes`：普通浏览器访问目录时显示文件
  列表，不寻找 `index.html`；
- `DavLockDB "/config/locks/DavLock"`：把 DAV 锁状态保存在持久化配置卷；
- `Alias "/.webdav-health" ...`：公开的容器健康检查，只返回 `ok`，不开放数据；
- `DocumentRoot "/data"`：URL `/` 对应 `/data`；
- `Dav On`：启用 WebDAV；
- `AllowOverride None`：不加载 `.htaccess`；
- `LimitRequestBody 0`：Apache 不限制上传大小；前置代理仍有自己的限制；
- `AuthUserFile "/config/auth/users.htpasswd"`：Basic Auth 用户库；
- `Header always set ...`：发送 `nosniff` 和 `no-referrer` 响应头。

`WEBDAV_AUTH=basic` 使用 `Require valid-user`；`WEBDAV_AUTH=none` 会让启动脚本
定义 `WEBDAV_NO_AUTH`，从而改用 `Require all granted`。后者允许匿名读写，只能
用于可信网络或已完成认证的反向代理后端。

## 常见修改

关闭普通浏览器目录列表，把 `Options Indexes` 改成：

```apache
Options None
```

只读模式需要替换两个认证分支原来的授权行：

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

不要保留原来的 `Require valid-user` 后再并列追加限制，否则认证成功的用户可能
仍然可以执行写入方法。

限制单次上传为 10 GiB：

```apache
LimitRequestBody 10737418240
```

登录后还要限制来源地址时，用下面内容替换 Basic Auth 分支中的
`Require valid-user`：

```apache
<RequireAll>
    Require valid-user
    Require ip 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
</RequireAll>
```

若同时需要只读，再在同一个 `<RequireAll>` 内加入：

```apache
Require method GET HEAD OPTIONS PROPFIND
```

## 修改、检查和恢复

直接修改活动文件，不要修改每次启动会刷新的 `.sample`：

```text
/config/httpd.conf
/config/webdav.conf
```

完整配置语法检查：

```bash
docker exec apache-webdav \
  apache2 -t -f /config/httpd.conf
```

检查通过后应用：

```bash
docker restart apache-webdav
```

恢复前先备份，然后复制参考配置：

```bash
docker exec apache-webdav \
  cp /config/webdav.conf /config/webdav.conf.bak

docker exec apache-webdav \
  cp /config/webdav.conf.sample /config/webdav.conf
```

恢复镜像内不带注释的完整默认配置：

```bash
docker exec apache-webdav \
  cp /defaults/httpd.conf /config/httpd.conf

docker exec apache-webdav \
  cp /defaults/webdav.conf /config/webdav.conf
```

旧版本的持久化配置不会自动迁移。若旧 `webdav.conf` 里仍有 `LoadModule`，要采用
当前结构时必须同时把这些行移到 `httpd.conf`；不能只替换其中一个文件。
