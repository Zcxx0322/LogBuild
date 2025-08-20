---
title: Uptime-Kuma
date: 2025-08-19 14:36:13
tags:
categories: Uptime-Kuma
index_img: /img/updatekuma.jpg
---

# 1. 简介

Uptime Kuma 是一款开源、免费且易于使用的自托管监控工具。Uptime Kuma 兼容多种平台，包括 Linux、Windows 10 (x64) 和 Windows Server。

Uptime Kuma 的仪表板简洁高效，功能强大，让监控正常运行时间变得前所未有的简单。

# 2. Windows（docker）

## 2.1. 环境准备

- Windows10以上操作系统
- [Docker Desktop](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module&_gl=1*1irokkm*_gcl_au*MTk2NTU1MjQ0NC4xNzU1NTc1NzU4*_ga*NTM4MzAyMTMyLjE3NTE0Mjg3ODg.*_ga_XJWPQMJYHQ*czE3NTU1ODM4OTAkbzEwJGcxJHQxNzU1NTg1OTUzJGo1MCRsMCRoMA..)

- Uptime Kuma ：1.23.16

## 2.2. 开启windows的Hyper-V虚拟化技术

*控制面板--->程序和功能--->启用或关闭Windows功能--->Hyper-V--->勾选Hyper-V工具和Hyper-V管理平台--->*

![kuma1.png](/img/kuma1.png)

## 2.3. 安装Docker Desktop

## 2.4. 拉取Uptime Kuma镜像

![kuma2.png](/img/kuma2.png)

## 2.5. 运行Uptime Kuma

在终端运行

```cmd
# 创建数据卷
docker volume create uptime-kuma

# 启动容器
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma --network host louislam/uptime-kuma:1.23.16
```

## 2.6. 使用

```url
http://127.0.0.1:3001
```

# 3. Windows（npm）

## 3.1. 环境准备

- Windows 10 (x64), Windows Server 2012 R2 (x64) 或更高
- [Git](https://git-scm.com/downloads/win)
- [Node.js](https://nodejs.org/en/download/current/) 14 / 16 / 18 / 20.4
- [npm](https://docs.npmjs.com/cli/) >= 7
- [pm2](https://pm2.keymetrics.io/)
- Uptime Kuma ：1.23.16

## 3.2. Node.js 20.19.4

下载链接：https://nodejs.org/dist/v20.19.4/node-v20.19.4-x64.msi

## 3.3. Uptime Kuma

```cmd
# npm换源
npm config set registry https://registry.npmmirror.com

# 拉取仓库
git clone https://github.com/louislam/uptime-kuma.git

# 如果存在网络问题，可用加速地址，加速节点参考https://ghproxy.link/
git clone https://ghfast.top/github.com/louislam/uptime-kuma.git

# 安装
cd uptime-kuma
git checkout 1.23.16
npm run setup

# 如果npm run setup这一步遇到下载前端文件慢的问题，可以修改extra目录下download-dist.js内的const url，保存后再重新执行npm run setup
https://ghfast.top/github.com/louislam/uptime-kuma/releases/download/1.23.16/dist.tar.gz
```

## 3.4. PM2

PM2 起到的主要作用是进程管理和守护服务

```bash
# 安装pm2
npm install pm2 -g
pm2 install pm2-logrotate

# 启动进程
pm2 start server/server.js --name uptime-kuma

# 实时监控 CPU/内存等资源
pm2 monit

# 开机启动
pm2 save && pm2 startup
```

## 3.5. 使用

```bash
http://127.0.0.1:3001
```

# 4. CentOS7（npm）

## 4.1. 环境准备

- CentOS Linux release 7.9.2009 (Core)   内核版本：3.10.0-1160.119.1.el7.x86_64
- [Git](https://git-scm.com/downloads/win)
- [Node.js](https://nodejs.org/en/download/current/) 18 / 20.4
- [npm](https://docs.npmjs.com/cli/) >= 7
- [pm2](https://pm2.keymetrics.io/)
- Uptime Kuma = 2.0.0-beta.2

## 4.2. Node.js

由于CentOS7默认的glibc版本较低，而Uptime Kuma需要的Node.js版本较高，需要的glibc版本也高，所以这里选择以glibc 2.17 构建的 Node 20

```bash
# 下载
cd /opt
wget -c https://unofficial-builds.nodejs.org/download/release/v20.12.2/node-v20.12.2-linux-x64-glibc-217.tar.xz

# 安装Node.js
cd /usr/local
tar -xvf /opt/node-v20.12.2-linux-x64-glibc-217.tar.xz
mv node-v20.12.2-linux-x64-glibc-217 node-v20.12.2

# 添加环境变量
cat >> /etc/profile << 'EOF'
export NODE_HOME=/usr/local/node-v20.12.2
export PATH=$PATH:$NODE_HOME/bin
EOF

# 使环境变量生效
source /etc/profile

# 更换npm下载源
npm config set registry https://registry.npmmirror.com
```

## 4.3. Uptime Kuma

{% note warning %}

- 由于安装脚本默认会将git分支切换回main，所以修改package.json文件。
- 考虑到下载链接是外网地址，所以将download-dist.js文件中原有的 dist.tar.gz 下载链接修改为国内加速源。

{% endnote %}

```bash
# 拉取仓库
git clone https://github.com/louislam/uptime-kuma.git

# 如果存在网络问题，可用加速地址
git clone https://ghfast.top/github.com/louislam/uptime-kuma.git
cd uptime-kuma

# 切换至我们需要的版本分支
git checkout release-2.0.0-beta.2

# 修改package.json文件，避免安装脚本自动切换分支
vim package.json
-----------------------------------------
"scripts": {
  "setup": "npm ci --omit dev && npm run download-dist"
}
-----------------------------------------
# 配置dist.tar.gz 下载链接为国内加速源
vim extra/download-dist.js

https://ghfast.top/github.com/louislam/uptime-kuma/releases/download/2.0.0-beta.2/dist.tar.gz

#执行安装脚本
npm run setup
```

## 4.4. PM2

PM2 起到的主要作用是进程管理和守护服务

```bash
npm install pm2 -g
pm2 install pm2-logrotate

# 启动进程
pm2 start server/server.js --name uptime-kuma

# 实时监控 CPU/内存等资源
pm2 monit

# 开机启动
pm2 save && pm2 startup
```

## 4.5. 使用

```bash
http://127.0.0.1:3001


```

# 5. PM2 命令清单

这里帮你整理一份常用的 **PM2 命令清单**，适用于管理 Uptime Kuma 或其他 Node.js 应用：

------

### **1. 安装和基础操作**

```bash
# 全局安装 PM2
npm install pm2 -g

# 启动应用（如 server.js 或 index.js）
pm2 start server.js --name uptime-kuma

# 查看正在运行的进程列表
pm2 list
pm2 status
```

### **2. 管理进程**

```bash
# 停止指定应用
pm2 stop uptime-kuma

# 重启指定应用
pm2 restart uptime-kuma

# 删除指定应用
pm2 delete uptime-kuma

# 停止/重启/删除所有应用
pm2 stop all
pm2 restart all
pm2 delete all
```

### **3. 日志管理**

```bash
# 查看应用日志（实时输出）
pm2 logs uptime-kuma

# 查看错误日志
pm2 logs uptime-kuma --err

# 查看最近 100 行日志
pm2 logs uptime-kuma --lines 100
```

### **4. 自动重启与开机自启**

```bash
# 保存当前进程列表，开机自动恢复
pm2 save

# 生成开机启动脚本（不同系统可能不同）
pm2 startup

# 删除开机启动设置
pm2 unstartup
```

### **5. 监控资源**

```bash
# 实时监控 CPU/内存等资源
pm2 monit
```

------

