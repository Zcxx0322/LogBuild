---
title: KVM
date: 2025-03-12 11:09:50
tags: KVM
categories: KVM
---
# 1. Archlinux使用KVM

## 1.1. 安装KVM包

安装运行KVM所需的所有软件包

```bash
sudo pacman -Syy

sudo pacman -S qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode
```

## 1.2. 安装ebtbles和iptables

```bash
sudo pacman -S ebtables iptables
```

## 1.3. 启动KVM libvirt服务

```bash
systemctl enable libvirtd.service

systemctl start libvirtd.service

systemctl status libvirtd.service
```

## 1.4. 设置网桥

安装后会生成一个默认网桥配置文件/etc/libvirt/qemu/networks/default.xml，但是默认处于不活跃状态！需要手动启用！

```bash
# 定义网桥
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml

# 启动网桥
sudo virsh net-start default

# 设置网桥开机启动
sudo virsh net-autostart default

# 查看网桥状态 
brctl show
```

# 2. 常用命令

```bash
# 进入root
su

# 创建虚拟磁盘
qemu-img create -f qcow2 /var/lib/libvirt/images/vm1 10G

# 创建虚拟机
virt-install \
--name vm1 \
--ram 4096 \
--disk path=/var/lib/libvirt/images/vm1.img,size=10 \
--vcpus 4 \
--cpu host-model,topology.sockets=1,topology.cores=4,topology.threads=1 \
--os-variant centos7 \
--network bridge=virbr0 \
--console pty,target_type=serial \
--cdrom=/var/lib/libvirt/images/CentOS-7-x86_64-Minimal-2009.iso \
--graphics vnc,password=geek,port=-1,listen=0.0.0.0

# 列出已创建的虚拟机
virsh list --all

# 启动虚拟机
virsh start vm1

# 开机启动虚拟机
virsh autostart vm1

# 关闭虚拟机
virsh destroy vm1

# 导出虚拟机配置
virsh dumpxml vm1 > vm1.xml

# 从xml文件定义虚拟机
virsh define vm1.xml

# 取消定义虚拟机
virsh undefine vm1.xml

# 如果创建了虚拟机而忘记记录IP，可以用这条命令连接虚拟机
virt-viewer -c qemu:///system vm1
```












