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

![image-20250819145343663](E:\workspace\LogBuild\source\img\kuma1.png)

## 2.3. 安装Docker Desktop

## 2.4. 拉取Uptime Kuma镜像

![image-20250819151149568](E:\workspace\LogBuild\source\img\kuma2.png)

## 2.5. 运行Uptime Kuma

在终端运行

```cmd
# 创建数据卷
docker volume create uptime-kuma

# 启动容器
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma --network host louislam/uptime-kuma:1.23.16
```

## 2.6. 访问

```url
http://127.0.0.1:3001/dashboard
```

# 3. Windows（npm）

## 3.1. 环境准备

- Windows 10 (x64), Windows Server 2012 R2 (x64) 或更高
- [Git](https://git-scm.com/downloads/win)
- [Node.js](https://nodejs.org/en/download/current/) 14 / 16 / 18 / 20.4
- [npm](https://docs.npmjs.com/cli/) >= 7
- [pm2](https://pm2.keymetrics.io/)
- Uptime Kuma ：1.23.16

## 3.2. 安装Node.js 20.19.4

下载链接：https://nodejs.org/dist/v20.19.4/node-v20.19.4-x64.msi

## 3.3. 安装Uptime Kuma

```cmd
# 更新npm
npm install npm -g

# 拉取仓库
git clone https://github.com/louislam/uptime-kuma.git

# 如果存在网络问题，可用加速地址
git clone https://ghfast.top/github.com/louislam/uptime-kuma.git

# 安装
cd uptime-kuma
git checkout 1.23.16
npm run setup

# 如果npm run setup这一步遇到下载前端文件慢的问题，可以修改extra目录下download-dist.js内的const url，保存后再重新执行npm run setup
https://ghfast.top/github.com/louislam/uptime-kuma/releases/download/1.23.16/dist.tar.gz

# 安装pm2
npm install pm2 -g 
pm2 install pm2-logrotate

# 启动
pm2 start server/server.js --name uptime-kuma

# 如果你想查看当前控制台输出
pm2 monit

# 开机启动
pm2 save && pm2 startup
```
