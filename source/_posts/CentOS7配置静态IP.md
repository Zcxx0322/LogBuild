---
title: CentOS7配置静态IP
tags: CentOS7
categories: CentOS7
date: 2024-12-02 11:40:27
---

------

# 1. 环境准备

1. **Oracle VM VirtualBox**
    下载地址：https://www.virtualbox.org/wiki/Downloads
2. **CentOS 7.9**
    下载地址：https://mirrors.aliyun.com/centos/7.9.2009/isos/x86_64/?spm=a2c6h.25603864.0.0.3dccf5adbnhdJY

------

# 2. 调整网络模式

*设置 → 网络 → 网卡1*

- 连接方式：桥接网卡
- 名称：本机上网使用的网卡名称

![image-20241205104936386](/img/network1.png)

------

# 3. 网卡自启配置（可选）

<font color='red'>如果在安装系统界面已经连接了网络，这一步可以跳过！</font>

## 3.1. 检查网卡名称

```bash
nmcli device status
```

## 3.2. 配置网卡为开机自启

假设网卡名称为 `enp0s3`（请根据实际情况替换）

```bash
nmcli connection modify enp0s3 connection.autoconnect yes
```

## 3.3. 验证网卡配置

```bash
nmcli connection show enp0s3 | grep autoconnect
```

**输出示例**

```cmd
connection.autoconnect:                 yes
connection.autoconnect-priority:        0
connection.autoconnect-retries:         -1 (default)
connection.autoconnect-slaves:          -1 (default)
```

------

# 4. 配置静态 IP

## 4.1. 方法一：修改网卡配置文件

### 4.1.1. 查看宿主机 IP

```bash
ipconfig
```

![image-20241205113859194](/img/network3.png)

<font color='red'>可以看到宿主机的网关为192.168.148.20，请记住它，待会儿要用！！！！！！！</font>

### 4.1.2. 编辑配置文件

```bash
vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
```

- 修改<font color='red'>BOOTPROTO=static</font>，既然要配置静态IP，那肯定要关闭DHCP嘛对吧！

  添加<font color='red'>IPADDR=192.168.148.100</font>，IP不用多说吧，**IP地址必须与网关在同一个网段**，否则通信无法正常进行。

  添加<font color='red'>GATEWAY=192.168.148.20</font>，来源于宿主机的网关。

  添加<font color='red'>NETMASK=255.255.255.0</font>

  添加<font color='red'>DNS1=8.8.8.8</font>

  添加<font color='red'>DNS2=8.8.4.4</font>

![image-20241205114551520](/img/network4.png)

### 4.1.3. 重启服务

```bash
systemctl restart network
```

### 4.1.4. 验证网络连通性

```bash
ping www.baidu.com
```

------

## 4.2. 方法二：使用 nmcli 工具

### 4.2.1. 查看网卡名称

```bash
nmcli device status
```

**输出示例**

```cmd
DEVICE  TYPE      STATE      CONNECTION
enp0s3  ethernet  connected  enp0s3
lo      loopback  unmanaged  --
```

### 4.2.2. 配置静态 IP

```bash
nmcli connection modify enp0s3 ipv4.addresses 192.168.148.100/24
nmcli connection modify enp0s3 ipv4.gateway 192.168.148.20
nmcli connection modify enp0s3 ipv4.dns "8.8.8.8,8.8.4.4"
nmcli connection modify enp0s3 ipv4.method manual
nmcli connection up enp0s3
```

### 4.2.3. 验证配置

```bash
nmcli -f ipv4.addresses,ipv4.gateway,ipv4.dns connection show enp0s3
```

**输出示例**

```cmd
ipv4.addresses:                         192.168.148.100/24
ipv4.gateway:                           192.168.148.20
ipv4.dns:                               8.8.8.8,8.8.4.4
```

### 4.2.4. 验证网络连通性

```bash
ping www.baidu.com
```

### 4.2.5. 恢复 DHCP 模式（可选）

```bash
nmcli connection modify enp0s3 ipv4.method auto
nmcli connection up enp0s3
```

### 4.2.6. 删除 nmcli 静态配置（可选）

```bash
nmcli connection delete enp0s3
nmcli device connect enp0s3
```

------

## 4.3. 方法三：使用 nmtui 工具

### 4.3.1. 进入交互界面

```bash
nmtui
```

按照提示进入网卡配置界面

![image-20241207104541968](/img/network5.png)

### 4.3.2. 配置步骤

1. IPv4 CONFIGURATION `<Automatic>` ------->>> <font color='red'>IPv4 CONFIGURATION` <Manual>`</font>
2. <font color='red'>` show`</font>
3. <font color='red'>`[X] Automatically connect`</font>
4. <font color='red'>` <OK>`</font>
5. <font color='red'>` <back>`</font>
6. <font color='red'>` <quit>`</font>

![image-20241207105524062](/img/network6.png)

### 4.3.3. 重启系统

```bash
reboot
```

### 4.3.4. 验证 IP

```bash
ip a
```

### 4.3.5. 验证网络连通性

```bash
ping www.baidu.com
```

------

