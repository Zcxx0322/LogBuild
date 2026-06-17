---
title: JumpServer
date: 2026-06-17 10:20:56
tags: JumpServer
categories: JumpServer
---

# JumpServer部署文档

## 1. 部署信息

软件版本：JumpServer CE v4.10.16
部署目录：`/opt/jumpserver-ce-v4.10.16-x86_64`
默认数据目录：`/data/jumpserver`
访问地址：`http://192.168.66.12`
默认账号：admin
默认密码：ChangeMe

说明：文档中的 `192.168.66.12` 请根据实际服务器 IP 修改。

---

## 2. 下载安装包

```bash
cd /opt && wget -c https://cdn0-download-offline-installer.fit2cloud.com/jumpserver/jumpserver-ce-v4.10.16-x86_64.tar.gz
```

解压安装包：

```bash
tar -xf jumpserver-ce-v4.10.16-x86_64.tar.gz
```

进入安装目录：

```bash
cd /opt/jumpserver-ce-v4.10.16-x86_64
```

---

## 3. 初始化配置文件

复制示例配置文件：

```bash
cp config-example.txt config.txt
```

生成随机密钥并写入配置文件：

```bash
SECRET_KEY=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 50)
BOOTSTRAP_TOKEN=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
DB_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
REDIS_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)

set_config() {
  key="$1"
  value="$2"
  file="config.txt"

  if grep -qE "^${key}=" "$file"; then
    sed -i "s#^${key}=.*#${key}=${value}#g" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

set_config SECRET_KEY "$SECRET_KEY"
set_config BOOTSTRAP_TOKEN "$BOOTSTRAP_TOKEN"
set_config DOMAINS "192.168.66.12"
set_config HTTP_PORT "80"
set_config SSH_PORT "2222"
set_config DB_ENGINE "postgresql"
set_config DB_HOST "postgres"
set_config DB_PORT "5432"
set_config DB_USER "root"
set_config DB_PASSWORD "$DB_PASSWORD"
set_config DB_NAME "jumpserver"
set_config REDIS_HOST "redis"
set_config REDIS_PORT "6379"
set_config REDIS_PASSWORD "$REDIS_PASSWORD"
```

注意：
如果服务器 IP 不是 `192.168.66.12`，需要修改以下配置：

```bash
set_config DOMAINS "实际服务器IP"
```

---

## 4. 检查配置文件

执行以下命令检查关键配置是否已正确写入：

```bash
grep -nE "^(SECRET_KEY|BOOTSTRAP_TOKEN|DOMAINS|HTTP_PORT|SSH_PORT|DB_ENGINE|DB_HOST|DB_PORT|DB_USER|DB_PASSWORD|DB_NAME|REDIS_HOST|REDIS_PORT|REDIS_PASSWORD)=" config.txt
```

确认输出中包含以下配置项：

```bash
SECRET_KEY=
BOOTSTRAP_TOKEN=
DOMAINS=192.168.66.12
HTTP_PORT=80
SSH_PORT=2222
DB_ENGINE=postgresql
DB_HOST=postgres
DB_PORT=5432
DB_USER=root
DB_PASSWORD=
DB_NAME=jumpserver
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
```

---

## 5. 授权安装脚本

```bash
chmod +x jmsctl.sh
```

---

## 6. 执行安装

```bash
./jmsctl.sh install
```

安装过程中按以下方式选择：

```text
Do you want to support IPv6? [y/N]: N
Do you need custom persistent store, will use the default directory /data/jumpserver? [y/N]: N
Persistent storage directory [default: /data/jumpserver] :回车
Do you want to use external PostgreSQL (version ≥ 16 required)? [y/N]: N
Please enter Redis Engine [redis/sentinel] (default: redis):回车
Do you want to use external Redis? [y/N]: N
Do you need to customize the JumpServer external port? [y/N]: y
JumpServer web port [default: 80] :回车
Please enter language [zh/en/ja/es/ko/ru/vi] (default: zh):回车
Please enter timezone [default: Asia/Shanghai] :回车
```

参数说明：

| 配置项           | 选择 | 说明                            |
| ---------------- | ---- | ------------------------------- |
| IPv6             | N    | 不启用 IPv6                     |
| 自定义持久化目录 | N    | 使用默认目录 `/data/jumpserver` |
| 外部 PostgreSQL  | N    | 使用安装包内置 PostgreSQL       |
| Redis Engine     | 回车 | 使用默认 `redis`                |
| 外部 Redis       | N    | 使用安装包内置 Redis            |
| 自定义外部端口   | y    | 配置 Web 访问端口               |
| Web 端口         | 回车 | 使用默认 `80`                   |
| 语言             | 回车 | 默认中文 `zh`                   |
| 时区             | 回车 | 默认 `Asia/Shanghai`            |

---

## 7. 启动 JumpServer

安装完成后启动服务：

```bash
./jmsctl.sh start
```

---

## 8. 检查容器重启策略

检查 `jms_core` 容器的重启策略：

```bash
docker inspect jms_core --format '{{.HostConfig.RestartPolicy.Name}}'
```

正常情况下应返回类似：

```bash
always
```

或：

```bash
unless-stopped
```

---

## 9. 访问 JumpServer

浏览器访问：

```text
http://192.168.66.12
```

默认登录信息：

```text
用户名：admin
密码：ChangeMe
```

首次登录后建议立即修改默认密码。

---

## 10. 常用管理命令

进入安装目录：

```bash
cd /opt/jumpserver-ce-v4.10.16-x86_64
```

启动服务：

```bash
./jmsctl.sh start
```

停止服务：

```bash
./jmsctl.sh stop
```

重启服务：

```bash
./jmsctl.sh restart
```

查看服务状态：

```bash
./jmsctl.sh status
```

查看日志：

```bash
./jmsctl.sh logs
```

---

## 11. 注意事项

1. `DOMAINS` 必须配置为实际访问 JumpServer 的 IP 或域名。
2. 如果服务器已被其他服务占用 80 端口，需要调整 `HTTP_PORT`。
3. 默认 SSH 端口配置为 `2222`，需要确保防火墙放行。
4. 默认数据目录为 `/data/jumpserver`，建议确认该目录磁盘空间充足。
5. 首次登录后应立即修改默认管理员密码。
6. 生产环境建议定期备份 `/data/jumpserver` 目录。
