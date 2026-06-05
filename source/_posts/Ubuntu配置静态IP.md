---
title: Ubuntu配置静态IP
date: 2026-06-05 10:39:38
tags:
  - Ubuntu
  - 网络
categories:
  - Ubuntu
---

# 1. Ubuntu24.04配置静态IP

## 1.1. **查看网卡名称**

```bash
ip a
```

可以看到`enp1s0`便是本机的外网网卡名称。

```terminal
root@ubuntu:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:a9:45:06 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.123/24 metric 100 brd 192.168.122.255 scope global dynamic enp1s0
       valid_lft 2436sec preferred_lft 2436sec
    inet6 fe80::5054:ff:fea9:4506/64 scope link 
       valid_lft forever preferred_lft forever
```

## 1.2. **修改网卡配置信息**

默认安装好 `/etc/netplan/` 目录下有自带的一个 `50-cloud-init.yaml` 文件，如果不想动原始文件，直接新建一个 `01-netcfg.yaml` 文件，然后写入下面配置，此方式需要你把 `50-cloud-init.yaml` 文件中的网卡对应的 dhcp4改成 false。

```bash
sudo sed -i 's/dhcp4: true/dhcp4: false/' /etc/netplan/50-cloud-init.yaml

sudo vim /etc/netplan/01-netcfg.yaml

-------------------------------------
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:  #修改为你的实际接口名字
      dhcp4: no
      addresses:
        - 192.168.0.88/24  # 固定的ip地址
      routes:
        - to: default
          via: 192.168.0.1  # 网关(桥接网络的话，需要查看宿主机的网关，nat模式的话，请注意初始网络的网关)
      nameservers:
        addresses:
          - 61.139.2.69 # dns1
          - 114.114.114.114 # dns2
-------------------------------------
```

## 1.3. **网卡生效**

```bash
sudo netplan apply

sudo systemctl restart systemd-networkd

ip a

ping www.baidu.com
```

