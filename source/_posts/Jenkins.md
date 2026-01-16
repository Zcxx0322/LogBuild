---
title: Jenkins
date: 2026-01-16 16:26:29
tags: Jenkins
categories: Jenkins
---

# 1. 环境准备与安装
更新系统并安装必要工具
```bash
sudo dnf update -y
sudo dnf install wget vim fontconfig -y
```
(注：Jenkins 的 Web 界面依赖 fontconfig 字体库，否则可能报错)

# 2. 安装Java环境 (必须)
```bash
sudo dnf install java-17-openjdk -y
```
验证安装
```bash
java -version
# 输出应包含 openjdk version "17.x.x"
```

# 3. 添加 Jenkins 源并安装

```bash
# 下载仓库文件
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# 导入 GPG 密钥
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# 安装 Jenkins
sudo dnf install jenkins -y
```

# 4. 启动服务并配置防火墙
```bash
# 重新加载配置
sudo systemctl daemon-reload

# 设置开机自启并立即启动
sudo systemctl enable --now jenkins

# 检查状态
systemctl status jenkins

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```
# 5. 获取初始密码
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```


