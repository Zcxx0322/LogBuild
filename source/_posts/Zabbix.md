---
title: Zabbix
date: 2025-11-08 16:46:40
tags: Zabbix
categories: Zabbix
---

# Zabbix安装配置

## 1. 架构概览
- OS: Rocky Linux 9
- Web Server: Nginx
- Database: PostgreSQL
- Zabbix Component: Server, Frontend, Agent 2

## 2. 安装 Zabbix 仓库

### 2.1. 安装 Zabbix 7.0 仓库
```bash
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-7.0-5.el9.noarch.rpm
```

### 2.2. 清理并重建缓存
```bash
dnf clean all
```

## 3. 安装 PostgreSQL

### 3.1. 安装 PostgreSQL Server
```bash
dnf module install postgresql:16 -y 
dnf install postgresql-server postgresql-contrib -y
```

### 3.2. 初始化并启动数据库
```bash
# 初始化数据库
postgresql-setup --initdb

# 启动并设置开机自启
systemctl enable --now postgresql
```

### 3.3. 创建 Zabbix 用户和数据库
我们需要切换到 postgres 系统用户来操作数据库。
```bash
# 切换到 postgres 用户并进入数据库命令行
sudo -u postgres psql
```
在 postgres=# 提示符下执行以下 SQL：
```SQL
-- 创建用户 (请将 your_password 替换为强密码)
CREATE USER zabbix WITH PASSWORD 'your_password';

-- 创建数据库
CREATE DATABASE zabbix OWNER zabbix;

-- 退出
\q
```

### 3.4. 配置PostgreSQL 认证方式
```bash
vi /var/lib/pgsql/data/pg_hba.conf
```
修改 IPv4 和 IPv6 连接方式 找到类似下面的行，将 ident (或 peer) 改为 scram-sha-256 (如果你安装的是较旧版本则用 md5)。
```bash
-------------------------------------------------------------------------------
修改前：
# IPv4 local connections:
host    all             all             127.0.0.1/32            ident
# IPv6 local connections:
host    all             all             ::1/128                 ident

修改后：
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
-------------------------------------------------------------------------------
```
重启 PostgreSQL 使配置生效
```bash
systemctl restart postgresql
```


## 4. 安装 Zabbix 组件
这里我们安装 PostgreSQL 版本的 Server 和 Web 前端，以及 Nginx 配置和 Agent 2。
```bash
dnf install zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2 -y
```

## 5. 导入初始数据
将 Zabbix 的基础架构导入到 PostgreSQL 中。系统会提示你输入刚才创建的 zabbix 数据库用户的密码。
```bash
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
```

## 6. 配置 Zabbix Server
编辑 Server 配置文件，配置数据库密码。
```bash
vi /etc/zabbix/zabbix_server.conf

......
DBName=zabbix
DBUser=zabbix
DBPassword=your_password <-- 这里填你在第二步设置的密码
```
(保存并退出: :wq)

## 7. 配置 Nginx
取消注释并修改端口 去掉 listen 和 server_name 前面的 #。你可以直接使用 80 端口，或者设置为域名。
```bash
vi /etc/nginx/conf.d/zabbix.conf

server {
        listen          80;
        server_name     example.com; # 如果没有域名，可以填 IP 或保持默认
        
        # ... 其他配置保持不变 ...
}
```
(保存并退出: :wq)

注意： 确保 /etc/nginx/nginx.conf 中没有其他的 server 块占用了 80 端口（Rocky Linux 默认的 nginx.conf 有时会包含一个 default server，如果冲突可能需要注释掉 /etc/nginx/nginx.conf 里的 server 块）。

## 8. 配置防火墙
开放 Web 端口 (80/443) 和 Zabbix Server/Agent 通信端口 (10050/10051)。
```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --reload
```

## 9. 启动所有服务
启动 Zabbix Server, Agent 2, Nginx 和 PHP-FPM，并设置开机自启。
```bash
systemctl restart zabbix-server zabbix-agent2 nginx php-fpm
systemctl enable zabbix-server zabbix-agent2 nginx php-fpm
```
检查 Agent 2 状态确保它正常运行：
```bash
systemctl status zabbix-agent2
```
## 10. 安装中文语言包

### 10.1. 安装系统语言包
```bash
dnf install glibc-langpack-zh -y
```

### 10.2. 重启 PHP-FPM 服务
```bash
systemctl restart php-fpm
```

## 11. Web 前端初始化
--------------------
- 打开浏览器访问：http://<服务器IP>
- Check of pre-requisites: 确保所有项为 OK。
- Configure DB connection:
- Database type: PostgreSQL
- Password: 输入 your_password
- 设置服务器名称 (如 "Zabbix PG Server")，时区选 Asia/Shanghai。
- 完成安装。
--------------------
默认登录信息：
- 用户：Admin
- 密码：zabbix
--------------------

