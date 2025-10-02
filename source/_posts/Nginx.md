---
title: Nginx
date: 2025-09-01 11:03:35
tags: Nginx
categories: Nginx
---

> 本文整理了一份完整的 Nginx 学习与实践指南，涵盖从 **在CentOS7 上安装方法**、**基础配置**、**反向代理**、**负载均衡**、**HTTPS 部署**、**性能优化**、**安全加固**、**日志监控** 到 **高可用与容器化** 的全流程内容。适合需要快速上手 Nginx 的初学者，也适合在生产环境中使用 Nginx 的运维和开发人员参考。

# 一. 简介

Nginx（“engine x”）是一款 HTTP Web 服务器、反向代理、内容缓存、负载均衡器、TCP/UDP 代理服务器和邮件代理服务器。最初由 Igor Sysoev 编写，并根据 2-clause BSD 许可证发布。F5 公司提供企业发行版、商业支持和培训。

# 二. 安装Nginx

## 1. CentOS7安装Nginx

Nginx 安装方式对比（CentOS 7）

|     安装方式     | 特点                       |                          优点                          |                    缺点                     |                       适用场景                        |
| :--------------: | -------------------------- | :----------------------------------------------------: | :-----------------------------------------: | :---------------------------------------------------: |
|  **官方源安装**  | 使用 Nginx 官方 YUM 仓库   | 版本更新快- 安全修复及时- 配置路径标准化（/etc/nginx） |              需要额外添加 repo              |       线上生产环境，需要 **长期维护、稳定更新**       |
| **EPEL 源安装**  | 使用 epel-release 提供的包 |                 安装简单- 系统兼容性好                 |           版本较旧- bug 修复较慢            |          快速部署，**对版本要求不高**的场景           |
| **源码编译安装** | 手动下载源码并编译         |           可自定义编译参数和模块- 性能可优化           |        安装复杂- 升级需手动重新编译         | 高级用户，需要 **特殊模块（如第三方模块、优化参数）** |
| **Docker 安装**  | 通过容器运行 Nginx         |       隔离性好- 升级/回滚方便- 配合 K8s 容器编排       | 依赖 Docker 环境- 数据卷/配置管理需额外考虑 |      微服务、**容器化环境**，需要快速部署和迁移       |

### 1.1. EPEL + Nginx 官方仓库安装

CentOS 7 默认仓库里 Nginx 版本较老，建议用官方源。

#### 1.1.1. 安装依赖

```bash
sudo yum install -y epel-release
sudo yum install -y yum-utils
```

#### 1.1.2. 添加Nginx 官方仓库

```bash
sudo tee /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/7/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
```

####  1.1.3. 安装 Nginx

```bash
sudo yum install -y nginx
```

####  1.1.4. 启动并开机自启

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 2.2. EPEL 源安装

#### 2.2.1. 安装 EPEL

```bash
sudo yum install -y epel-release
```

#### 2.2.2. 安装 nginx

```bash
sudo yum install -y nginx
```

#### 2.2.3. 启动服务

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2.3. 源码编译安装

适合需要自定义模块的场景。

#### 2.3.1. 安装编译工具和依赖

```bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y gcc pcre-devel zlib-devel make openssl-devel wget
```

#### 2.3.2. 下载源码（以稳定版 1.24.0 为例）

```bash
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar -zxvf nginx-1.24.0.tar.gz
cd nginx-1.24.0
```

#### 2.3.3. 配置编译参数（可加模块）

```bash
./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_gzip_static_module
make
sudo make install
```

#### 2.3.4. 启动

```bash
/usr/local/nginx/sbin/nginx
```

#### 2.3.5. 添加 systemd 管理

```bash
sudo tee /etc/systemd/system/nginx.service <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=network.target

[Service]
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PIDFile=/usr/local/nginx/logs/nginx.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 2.4. 通过 Docker 安装 Nginx

如果你有 Docker 环境，可以直接用容器跑。

#### 2.4.1. 安装 Docker（若未安装）

```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
```

#### 2.4.2. 拉取并运行 Nginx

```bash
sudo docker run --name nginx -p 80:80 -d nginx
```

# 三. Nginx教程

## 1. Nginx 基础配置

Nginx 的配置文件一般位于：

- 主配置文件：`/etc/nginx/nginx.conf`
- 子配置文件：`/etc/nginx/conf.d/*.conf`

### 1.1. Nginx 配置文件结构

一个完整的 Nginx 配置由 **三大块** 组成：

1. **全局块**（定义进程数、运行用户等）
2. **events 块**（事件处理，worker 连接数等）
3. **http 块**（最核心部分，定义虚拟主机、反向代理、负载均衡等）

```nginx
# 全局块
user  nginx;
worker_processes auto;

# events 块
events {
    worker_connections 1024;
}

# http 块
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # 日志
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # server 块（虚拟主机）
    server {
        listen 80;
        server_name example.com;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }
    }
}
```

### 1.2. server 块（虚拟主机）

Nginx 可以通过 **虚拟主机** 配置多个站点：

#### 1.2.1. 基于域名的虚拟主机

```nginx
server {
    listen 80;
    server_name www.site1.com;
    root /var/www/site1;
}

server {
    listen 80;
    server_name www.site2.com;
    root /var/www/site2;
}
```

当访问 `www.site1.com` 时，会返回 `/var/www/site1` 目录内容；访问 `www.site2.com` 时，会返回 `/var/www/site2`。

#### 1.2.2. 基于端口的虚拟主机

```nginx
server {
    listen 8080;
    server_name localhost;
    root /var/www/site8080;
}
```

访问 `http://IP:8080/` 时，返回 `/var/www/site8080` 内容。

### 1.3. location 块（路径匹配）

`location` 用来匹配 URL 路径，并指定处理方式。

常见写法：

```nginx
# 精确匹配
location = /abc {
    return 200 "this is /abc";
}

# 前缀匹配
location /images/ {
    root /data;
}

# 正则匹配
location ~ \.php$ {
    root /var/www/html;
    fastcgi_pass 127.0.0.1:9000;
}
```

匹配优先级：

`=` 精确匹配 > 前缀匹配（最长优先） > 正则匹配

### 1.4. 配置静态网站

最常见的用法：直接托管静态文件（HTML、JS、CSS、图片）。

```nginx
server {
    listen 80;
    server_name www.example.com;

    root /var/www/html;
    index index.html index.htm;
}
```

将文件放到 `/var/www/html/` 目录下即可访问。
例如：`/var/www/html/index.html` → `http://www.example.com/index.html`

## 2. 反向代理与动静分离

### 2.1. 基本反向代理

示例：将请求转发给运行在 127.0.0.1:5000 的应用服务。

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

说明：

- `proxy_pass` 指定后端服务地址
- `proxy_set_header` 用来传递客户端的真实 IP 和 Host，避免后端获取不到正确信息

### 2.2. 代理多个路径

如果前端和后端服务分开，可以通过不同路径代理不同后端。

```nginx
server {
    listen 80;
    server_name www.example.com;

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
    }

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

说明：

- `/api/` 请求会转发到后端 8000 端口
- `/` 静态资源直接由 Nginx 提供

### 2.3. 动静分离

动静分离的常见写法：静态资源由 Nginx 提供，动态请求交给后端。

```nginx
server {
    listen 80;
    server_name www.example.com;

    # 静态资源
    location /static/ {
        root /var/www/html;
    }

    # 动态请求
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2.4. 针对不同后端的配置示例

#### 2.4.1. Node.js

```nginx
server {
    listen 80;
    server_name node.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
```

#### 2.4.2. Flask (Gunicorn)

```nginx
server {
    listen 80;
    server_name flask.example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 2.4.3. PHP (PHP-FPM)

```nginx
server {
    listen 80;
    server_name php.example.com;
    root /var/www/phpapp;

    location / {
        index index.php index.html;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

## 3. 负载均衡

当单个后端服务无法满足高并发需求时，可以通过 Nginx 的 **upstream 模块** 配置多台后端，实现负载均衡。

### 3.1. 基本配置

```nginx
upstream backend {
    server 192.168.1.10;
    server 192.168.1.11;
}

server {
    listen 80;
    server_name lb.example.com;

    location / {
        proxy_pass http://backend;
    }
}
```

说明：

- 定义 `upstream backend`，包含多个后端节点
- 在 `proxy_pass` 中直接引用 `http://backend`

默认策略为 **轮询（Round Robin）**。

### 3.2. 负载均衡策略

#### 3.2.1. 轮询（默认）

请求按顺序分发到后端服务器。

```nginx
upstream backend {
    server 192.168.1.10;
    server 192.168.1.11;
}
```

#### 3.2.2. 最少连接数（least_conn）

将请求分配给当前连接数最少的后端。

```nginx
upstream backend {
    least_conn;
    server 192.168.1.10;
    server 192.168.1.11;
}
```

#### 3.2.3. IP 哈希（ip_hash）

同一个客户端 IP 会固定访问同一台后端，常用于有会话需求的场景。

```nginx
upstream backend {
    ip_hash;
    server 192.168.1.10;
    server 192.168.1.11;
}
```

#### 3.2.4. 权重（weight）

为不同服务器设置权重，性能好的服务器可以承担更多请求。

```nginx
upstream backend {
    server 192.168.1.10 weight=3;
    server 192.168.1.11 weight=1;
}
```

### 3.3. 健康检查（被动）

Nginx 默认支持被动健康检查：当后端返回错误时，会自动将其标记为不可用，直到恢复正常。

```nginx
upstream backend {
    server 192.168.1.10 max_fails=3 fail_timeout=30s;
    server 192.168.1.11;
}
```

## 4. HTTPS 配置

随着安全要求的提升，HTTPS 已经成为网站的标配。Nginx 提供了完善的 SSL/TLS 支持，可以轻松为网站启用 HTTPS。

### 4.1. 基本 HTTPS 配置

假设证书和私钥文件已经准备好（例如 `example.crt` 和 `example.key`）。

```nginx
server {
    listen 443 ssl;
    server_name www.example.com;

    ssl_certificate     /etc/nginx/ssl/example.crt;
    ssl_certificate_key /etc/nginx/ssl/example.key;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

说明：

- `listen 443 ssl` 表示启用 443 端口并开启 SSL
- `ssl_certificate` 指定公钥证书
- `ssl_certificate_key` 指定私钥

### 4.2. HTTP 自动跳转 HTTPS

通常需要将所有 HTTP 请求自动跳转到 HTTPS。

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://$host$request_uri;
}
```

### 4.3. 使用 Let’s Encrypt 免费证书

安装 Certbot 获取免费 SSL 证书：

```bash
sudo yum install -y epel-release
sudo yum install -y certbot python2-certbot-nginx
sudo certbot --nginx -d www.example.com
```

执行成功后，Certbot 会自动修改 Nginx 配置并续期证书。

### 4.4. TLS 安全优化

为了避免使用不安全的协议和加密套件，可以在配置中进行限制。

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

说明：

- 只启用 `TLSv1.2` 和 `TLSv1.3`
- 禁用弱加密算法
- 开启 session 缓存，提高性能

### 4.5. HTTP/2 支持

开启 HTTP/2 可以提升 HTTPS 网站性能（需要 OpenSSL 支持）。

```nginx
server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate     /etc/nginx/ssl/example.crt;
    ssl_certificate_key /etc/nginx/ssl/example.key;

    location / {
        root /usr/share/nginx/html;
    }
}
```

## 5. 性能优化

Nginx 默认配置在中小规模场景下可以正常工作，但在高并发或大流量场景下，需要进行性能优化以提升吞吐量和响应速度。

### 5.1. worker 配置

Nginx 的核心是事件驱动模型，`worker_processes` 和 `worker_connections` 是性能优化的关键。

```nginx
worker_processes auto;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}
```

说明：

- `worker_processes auto`：自动根据 CPU 核心数分配进程数
- `worker_connections`：每个 worker 最大连接数，通常设置为 1024 或更高
- `use epoll`：Linux 下推荐使用 epoll 模型
- `multi_accept on`：允许 worker 一次接受多个新连接

### 5.2. TCP 优化

Nginx 提供了几个 TCP 优化选项，提高大文件传输和连接效率。

```nginx
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
}
```

说明：

- `sendfile on`：启用零拷贝，提高文件传输效率
- `tcp_nopush on`：尽量一次性发送 HTTP 响应头，减少包数量
- `tcp_nodelay on`：立即发送小数据包，适合交互式应用

### 5.3. Gzip 压缩

启用 gzip 压缩可减少传输数据量，提升访问速度。

```nginx
http {
    gzip on;
    gzip_min_length 1k;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/javascript application/xml application/xml+rss image/svg+xml;
    gzip_vary on;
}
```

说明：

- `gzip_min_length`：最小压缩大小（1KB以上才压缩）
- `gzip_comp_level`：压缩等级（1-9，推荐 4-6）
- `gzip_types`：指定要压缩的 MIME 类型

### 5.4. 静态资源缓存

通过 `expires` 或 `cache-control` 指令为静态文件设置缓存策略。

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 30d;
    add_header Cache-Control "public";
}
```

说明：

- `expires 30d`：静态资源缓存 30 天
- `Cache-Control public`：允许浏览器和代理缓存

### 5.5. 反向代理缓存

Nginx 也可以缓存后端响应，减轻应用服务器压力。

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m inactive=60m;
proxy_cache_key $scheme$proxy_host$request_uri;

server {
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_cache my_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
    }
}
```

说明：

- `proxy_cache_path`：定义缓存路径和缓存区大小
- `proxy_cache`：指定使用的缓存区
- `proxy_cache_valid`：缓存不同响应码的时间

### 5.6. 文件描述符限制

需要提高系统的文件描述符数，否则高并发时可能出现 `too many open files` 错误。

编辑 `/etc/security/limits.conf`：

```ASCIIDOC
* soft nofile 65535
* hard nofile 65535
```

在 Nginx 配置中增加：

```nginx
worker_rlimit_nofile 65535;
```

## 6. 安全加固

Nginx 除了作为高性能 Web 服务器外，也可以在前端起到安全防护作用。通过合理的配置，可以减少攻击面、限制非法访问、缓解 DDoS/CC 攻击。

### 6.1. 禁止目录遍历

默认情况下，如果某目录没有 `index.html` 文件，可能会暴露文件列表。可以通过以下方式禁止目录遍历：

```nginx
location / {
    autoindex off;
}
```

### 6.2. 隐藏版本号

Nginx 默认会在错误页面或响应头中显示版本号，可能会暴露漏洞信息。可以关闭：

```nginx
http {
    server_tokens off;
}
```

### 6.3. 限制请求方法

只允许特定的 HTTP 方法（如 GET、POST），拒绝其他请求方法：

```nginx
location / {
    if ($request_method !~ ^(GET|POST)$) {
        return 405;
    }
}
```

### 6.4. 请求速率限制（防止 CC 攻击）

限制单个 IP 的请求速率，防止恶意刷请求：

```nginx
http {
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;

    server {
        location /api/ {
            limit_req zone=req_limit burst=20 nodelay;
            proxy_pass http://127.0.0.1:8000;
        }
    }
}
```

说明：

- `rate=10r/s`：每秒允许 10 个请求

- `burst=20`：允许短时间内突发 20 个请求

- `nodelay`：超出部分立即拒绝

  

### 6.5. 连接数限制

限制单个 IP 的并发连接数，防止恶意占用连接：

```nginx
http {
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    server {
        location / {
            limit_conn addr 10;
        }
    }
}
```

说明：

- `limit_conn_zone` 定义一个共享内存存储 IP 状态
- `limit_conn addr 10` 表示单个 IP 最多 10 个并发连接

### 6.6. 防盗链（Referer 检查）

避免图片、视频等资源被其他网站盗用：

```nginx
location ~* \.(jpg|jpeg|png|gif|mp4)$ {
    valid_referers none blocked *.example.com;
    if ($invalid_referer) {
        return 403;
    }
}
```

说明：

- `valid_referers` 定义合法来源
- `$invalid_referer` 判断非法来源并返回 403

### 6.7. IP 访问控制

只允许特定 IP 访问管理路径，其他全部拒绝：

```nginx
location /admin {
    allow 192.168.1.0/24;
    deny all;
}
```

### 6.8. 防止上传大文件

限制请求体大小，避免恶意上传超大文件导致服务资源耗尽：

```nginx
http {
    client_max_body_size 10m;
}
```

## 7. 日志与监控

Nginx 提供了 **访问日志（access log）** 和 **错误日志（error log）**，是排查问题、分析流量和做安全审计的重要手段。配合第三方工具，可以实现实时监控与可视化分析。

### 7.1. 访问日志

访问日志记录了每个请求的详细信息，包括 IP、时间、请求方法、状态码等。

```nginx
http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
}
```

说明：

- `log_format` 定义日志格式（`main` 是名称）
- `access_log` 指定日志文件和格式

日志示例：

```accesslog
192.168.1.100 - - [29/Aug/2025:12:31:21 +0800] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0" "-"
```

### 7.2. 错误日志

错误日志记录了 Nginx 在运行时遇到的问题，如配置错误、后端不可达等。

```nginx
error_log /var/log/nginx/error.log warn;
```

说明：

- 日志级别：`debug`、`info`、`notice`、`warn`、`error`、`crit`
- 建议生产环境使用 `warn` 或 `error`，避免日志过多

### 7.3. 按站点分日志

可以为不同的虚拟主机单独配置日志文件，方便分析。

```nginx
server {
    listen 80;
    server_name site1.example.com;

    access_log /var/log/nginx/site1_access.log main;
    error_log  /var/log/nginx/site1_error.log warn;

    location / {
        root /var/www/site1;
    }
}
```

### 7.4. 禁用日志

如果不想记录某些静态资源请求日志，可以关闭日志：

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    access_log off;
    log_not_found off;
}
```

### 7.5. 日志切割

Nginx 不会自动切割日志，通常通过 `logrotate` 管理。

配置文件路径：`/etc/logrotate.d/nginx`

```CONF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 nginx adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

### 7.6. 实时日志分析（GoAccess）

GoAccess 是一个命令行实时日志分析工具。

安装：

```bash
sudo yum install -y goaccess
```

使用：

```bash
goaccess /var/log/nginx/access.log -o /var/www/html/report.html --log-format=COMBINED --real-time-html
```

浏览器访问 `http://server_ip/report.html` 即可看到可视化报表。

### 7.7. 集成 ELK（ElasticSearch + Logstash + Kibana）

- **Logstash** 采集和解析 Nginx 日志
- **ElasticSearch** 存储和索引日志数据
- **Kibana** 可视化展示请求趋势、状态码、地理位置等

示例 Logstash 配置：

```nginx
input {
    file {
        path => "/var/log/nginx/access.log"
        start_position => "beginning"
    }
}

filter {
    grok {
        match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
}

output {
    elasticsearch { hosts => ["localhost:9200"] }
    stdout { codec => rubydebug }
}
```

## 8. 高可用与容器化

在生产环境中，单台 Nginx 容易成为瓶颈或单点故障。为了解决这些问题，可以通过 **高可用架构**（Keepalived + Nginx）和 **容器化部署**（Docker、Kubernetes）来提升服务的稳定性和扩展性。

### 8.1. Nginx + Keepalived 高可用

#### 8.1.1. 原理

- **Keepalived** 使用 VRRP 协议，为多台服务器分配一个虚拟 IP（VIP）
- 主节点宕机后，备用节点会自动接管 VIP
- 客户端始终通过 VIP 访问，保证服务连续性

#### 8.1.2. 配置示例（主节点）

安装 Keepalived：

```bash
sudo yum install -y keepalived
```

编辑 `/etc/keepalived/keepalived.conf`：

```CONF
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        192.168.1.100
    }
}
```

#### 8.1.3. 配置示例（备节点）

```CONF
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        192.168.1.100
    }
}
```

说明：

- `priority` 值越大优先级越高，主节点设置为 100，备节点设置为 90
- `virtual_ipaddress` 为对外提供的虚拟 IP

启动并开机自启：

```bash
systemctl enable keepalived
systemctl start keepalived
```

### 8.2. Nginx 在 Kubernetes 中部署

#### 8.2.1. Deployment 配置

```
nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

#### 8.2.2. Service 暴露

```
nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

说明：

- `replicas: 3` 表示运行 3 个副本，实现负载均衡
- `Service` 将 Nginx 对外暴露在 `30080` 端口

------

# 四. 常见问题排查

在使用 Nginx 的过程中，经常会遇到各种错误或异常。以下总结了常见问题及排查方法。

## 1. 配置语法错误

修改配置后执行：

```bash
nginx -t
```

输出示例：

```terminal
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

如果有错误，会显示出错的文件和行号。修复后再执行：

```bash
systemctl reload nginx
```

------

## 2. 80 或 443 端口被占用

现象：Nginx 启动时报错 `bind() to 0.0.0.0:80 failed (98: Address already in use)`。

排查：

```bash
netstat -tulnp | grep 80
```

解决：

- 停止占用端口的服务
- 或修改 Nginx 配置文件 `listen` 为其他端口

------

## 3. 502 Bad Gateway

常见原因：

- 后端服务未启动或异常退出
- Nginx 配置了错误的后端地址
- PHP-FPM 未运行或监听错误

排查：

- 查看 Nginx 错误日志 `/var/log/nginx/error.log`
- 确认后端服务是否正常运行
- 检查 `proxy_pass` 或 `fastcgi_pass` 配置

------

## 4. 504 Gateway Timeout

常见原因：

- 后端服务响应过慢
- Nginx 超时设置过低

解决方法：

```
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

可在 `server` 或 `location` 中增加以上配置。

------

## 5. SSL 证书错误

现象：浏览器提示 `SSL certificate problem` 或 `NET::ERR_CERT_DATE_INVALID`。

排查：

- 检查证书和私钥路径是否正确
- 检查证书是否过期

```bash
openssl x509 -in /etc/nginx/ssl/example.crt -noout -dates
```

解决方法：

- 重新申请证书（如使用 Let’s Encrypt 续签）
- 确认 `ssl_certificate` 与 `ssl_certificate_key` 配对正确

------

## 6. 高并发下出现 `too many open files`

现象：Nginx 报错 `EMFILE: Too many open files`。

解决方法：

1. 修改系统限制 `/etc/security/limits.conf`：

   ```
   * soft nofile 65535
   * hard nofile 65535
   ```

2. 在 Nginx 配置文件中加入：

   ```
   worker_rlimit_nofile 65535;
   ```

3. 重启 Nginx

------

## 7. 日志过大

现象：`/var/log/nginx/access.log` 或 `error.log` 文件体积过大，占满磁盘。

解决方法：

- 配置 `logrotate` 定期切割日志
- 对静态资源路径关闭日志

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    access_log off;
    log_not_found off;
}
```

------

## 8. 防火墙或 SELinux 阻止访问

CentOS7 默认启用防火墙和 SELinux，可能导致端口无法访问。

### 8.1. 检查防火墙

```bash
firewall-cmd --list-all
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --reload
```

### 8.2. 检查 SELinux

```bash
sestatus
```

如果 SELinux 启用，可以临时关闭：
```bash
setenforce 0
```