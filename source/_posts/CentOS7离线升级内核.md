---
title: CentOS7离线升级内核 
date: 2025-09-01 11:09:50
tags: CentOS7
categories: CentOS7
---

------

# CentOS7 离线升级内核

- **原内核版本**：3.10.0-1160.el7.x86_64
- **升级后内核版本**：5.4.261-1.el7.elrepo.x86_64

------

## 1. 环境确认

```bash
cat /etc/centos-release
uname -r
arch
```

------

## 2. 准备 RPM 包

在有网络的环境中，下载以下文件（来自 ELRepo archive 镜像），并传输到目标服务器，例如 `/root/` 目录：

- kernel-lt-5.4.261-1.el7.elrepo.x86_64.rpm
- kernel-lt-devel-5.4.261-1.el7.elrepo.x86_64.rpm
- kernel-lt-headers-5.4.261-1.el7.elrepo.x86_64.rpm
- kernel-lt-tools-5.4.261-1.el7.elrepo.x86_64.rpm
- kernel-lt-tools-libs-5.4.261-1.el7.elrepo.x86_64.rpm

下载源：
 https://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/

------

## 3. 移除旧工具（避免冲突）

```bash
yum remove -y kernel-tools kernel-tools-libs
```

------

## 4. 安装新内核及工具

进入存放 rpm 包的目录（假设在 `/root/`）：

```bash
cd /root

yum localinstall -y kernel-lt-5.4.261-1.el7.elrepo.x86_64.rpm \
                    kernel-lt-devel-5.4.261-1.el7.elrepo.x86_64.rpm \
                    kernel-lt-headers-5.4.261-1.el7.elrepo.x86_64.rpm \
                    kernel-lt-tools-5.4.261-1.el7.elrepo.x86_64.rpm \
                    kernel-lt-tools-libs-5.4.261-1.el7.elrepo.x86_64.rpm
```

------

## 5. 更新 GRUB 引导配置

```bash
# 生成 grub 配置文件
grub2-mkconfig -o /boot/grub2/grub.cfg

# 查看可用的内核启动项
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg

# 设置默认启动项（一般新内核是第 0 项）
grub2-set-default 0
```

------

## 6. 重启并验证

```bash
reboot

uname -r
```

**输出示例**

```terminal
5.4.261-1.el7.elrepo.x86_64
```

------

## 7. 回退方案

如果新内核无法正常启动：

1. 在 **开机 GRUB 菜单** 中手动选择旧内核 `3.10.0-1160.el7.x86_64`。

2. 或者在系统中改回旧内核为默认：

   ```bash
   awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
   grub2-set-default 1
   reboot
   ```

   （其中 `1` 表示旧内核在 grub 菜单中的顺序）

------

