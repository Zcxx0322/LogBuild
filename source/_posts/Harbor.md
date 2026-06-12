---
title: Harbor
date: 2026-06-12 11:33:50
tags: Harbor
categories: Harbor
---

# Ubuntu24.04部署Harbor

## 1. 环境说明

| 项目         | 说明                    |
| ------------ | ----------------------- |
| 操作系统     | Ubuntu 24.04 LTS        |
| Harbor 版本  | v2.14.4                 |
| 部署方式     | Docker + Docker Compose |
| 推荐安装方式 | Offline Installer       |
| 域名示例     | `harbor.test.com`       |
| HTTPS        | 推荐启用                |
| 数据目录     | `/data`                 |

## 2. 部署前准备

### 2.1. 更新系统

```bash
sudo apt upgrade -y
```

### 2.2. 安装基础工具

```bash
sudo apt install -y \
  curl \
  wget \
  vim \
  tar \
  gnupg \
  ca-certificates \
  lsb-release \
  apt-transport-https \
  software-properties-common
```

### 2.3. 配置主机名

```bash
sudo hostnamectl set-hostname harbor
```

## 3. Docker

### 3.1. 安装Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
  
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker

docker --version
docker compose version
```

### 3.2. 配置 Docker 日志限制

生产环境建议配置 Docker 日志轮转，防止日志占满磁盘。

```bash
sudo mkdir -p /etc/docker

sudo vim /etc/docker/daemon.json

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}

sudo systemctl restart docker
```

## 4. Harbor

### 4.1. 下载 Harbor 安装包

```bash
wget -c https://github.com/goharbor/harbor/releases/download/v2.14.4/harbor-offline-installer-v2.14.4.tgz

sudo tar -zxvf harbor-offline-installer-v2.14.4.tgz
```

### 4.2. 配置Harbor

```bash
cd /opt/harbor

sudo cp harbor.yml.tmpl harbor.yml

sed -i '/^[[:space:]]*https:/,/^[[:space:]]*private_key:/ s/^/#/' /opt/harbor/harbor.yml

sudo vim harbor.yml

hostname: harbor.example.com
http:
  port: 80
harbor_admin_password: Harbor@12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  offline_scan: false
  security_check: vuln
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
```

### 4.3. 安装 Harbor

```bash
docker load -i harbor.v2.14.4.tar.gz

sudo ./prepare

sudo ./install.sh --with-trivy

sudo docker compose ps
```

## 5. HarborWeb

### 5.1. 本地域名解析

```bash
vim /etc/hosts

harbor部署服务器ip:harbor.test.com

# 浏览器访问
http://harbor.test.com

# 默认账号
用户名：admin
密码：Harbor@12345
```

### 5.2. Docker登录Harbor

```bash
docker login harbor.test.com

root@harbor:/opt/harbor# docker login harbor.test.com
Username: 
```

### 5.3. 推送镜像到 Harbor

登录 Harbor Web 页面：

```Text
Projects -> New Project -> Projectname：test（项目 -> 新建项目 -> 项目名称：test）
```

推送端随意拉取一个镜像，这里以Nginx为例。

```bash
# 拉取
docker pull nginx:latest

# 打标签
docker tag nginx:latest harbor.test.com/test/nginx:latest

# 推送镜像
docker push harbor.test.com/test/nginx:latest

# 拉取测试镜像
docker pull harbor.test.com/test/nginx:latest
```

