---
title: KVM
date: "2025-03-12 11:09:50"
tags:
  - KVM
categories:
  - KVM
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

## 1.5. 无图形化安装虚拟机

```text
Arch Linux 宿主机
系统级 libvirt：qemu:///system
镜像：/var/lib/libvirt/images/noble-server-cloudimg-amd64.img
虚拟机名：ubuntu-noble01
```

### 1.5.1. 安装依赖

```bash
sudo pacman -Syu
sudo pacman -S --needed qemu-full libvirt virt-install dnsmasq iptables-nft bridge-utils cloud-image-utils

wget https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/noble/20260518/noble-server-cloudimg-amd64.img -O /var/lib/libvirt/images/
```

启动 libvirt：

```bash
sudo systemctl enable --now libvirtd
```

加入用户组：

```bash
sudo usermod -aG libvirt,kvm $USER
```

重新登录，或重启：

```bash
reboot
```

### 1.5.2. 设置默认使用系统级 libvirt

如果你用 bash：

```bash
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.bashrc
source ~/.bashrc
```

如果你用 zsh：

```bash
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.zshrc
source ~/.zshrc
```

验证：

```bash
virsh uri
```

应输出：

```text
qemu:///system
```

### 1.5.3. 创建并启动 default 网络

查看网络：

```bash
sudo virsh -c qemu:///system net-list --all
```

如果没有 `default`，执行：

```bash
cat > /tmp/default-network.xml <<'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh -c qemu:///system net-define /tmp/default-network.xml
```

启动并设置自启：

```bash
sudo virsh -c qemu:///system net-start default
sudo virsh -c qemu:///system net-autostart default
```

### 1.5.4. 准备虚拟机磁盘

```bash
cd /var/lib/libvirt/images

sudo cp noble-server-cloudimg-amd64.img ubuntu-noble01.qcow2
sudo qemu-img resize ubuntu-noble01.qcow2 30G
sudo chmod 644 ubuntu-noble01.qcow2
```

### 1.5.5. 创建 cloud-init 配置

```bash
sudo mkdir -p /var/lib/libvirt/images/cloud-init/ubuntu-noble01
cd /var/lib/libvirt/images/cloud-init/ubuntu-noble01
```

创建 `user-data`：

- 用户名：name: ubuntu
- 密码：plain_text_passwd: ubuntu123

```bash
sudo tee user-data > /dev/null <<'EOF'
#cloud-config
hostname: ubuntu-noble01
manage_etc_hosts: true

users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    plain_text_passwd: ubuntu123

ssh_pwauth: true
disable_root: true

package_update: true
packages:
  - qemu-guest-agent
  - vim
  - curl
  - wget

growpart:
  mode: auto
  devices:
    - /

resize_rootfs: true
timezone: Asia/Shanghai

runcmd:
  - systemctl enable --now qemu-guest-agent
  - sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
EOF
```

创建 `meta-data`：

```bash
sudo tee meta-data > /dev/null <<'EOF'
instance-id: ubuntu-noble01
local-hostname: ubuntu-noble01
EOF
```

生成 ISO：

```bash
sudo cloud-localds seed.iso user-data meta-data
sudo chmod 644 seed.iso
```

### 1.5.6. 创建虚拟机

如果之前失败过，先清理：

```bash
sudo virsh -c qemu:///system destroy ubuntu-noble01 2>/dev/null || true
sudo virsh -c qemu:///system undefine ubuntu-noble01 --nvram 2>/dev/null || true
```

创建：

```bash
sudo virt-install \
  --connect qemu:///system \
  --name ubuntu-noble01 \
  --memory 3072 \
  --vcpus 2 \
  --cpu host-model \
  --disk path=/var/lib/libvirt/images/ubuntu-noble01.qcow2,format=qcow2,bus=virtio \
  --disk path=/var/lib/libvirt/images/cloud-init/ubuntu-noble01/seed.iso,device=cdrom \
  --os-variant ubuntu24.04 \
  --network network=default,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --import \
  --noautoconsole
```

如果 `ubuntu24.04` 不支持，改成：

```bash
--os-variant ubuntu22.04
```

### 1.5.7. 查看虚拟机和 IP

查看虚拟机：

```bash
sudo virsh -c qemu:///system list --all
```

查看 IP：

```bash
sudo virsh -c qemu:///system net-dhcp-leases default
```

或：

```bash
sudo virsh -c qemu:///system domifaddr ubuntu-noble01
```

### 1.5.8. 登录

假设 IP 是 `192.168.122.100`：

```bash
ssh ubuntu@192.168.122.100
```

密码：

```text
ubuntu123
```

### 1.5.9. 常用命令

启动：

```bash
sudo virsh -c qemu:///system start ubuntu-noble01
```

关机：

```bash
sudo virsh -c qemu:///system shutdown ubuntu-noble01
```

强制关机：

```bash
sudo virsh -c qemu:///system destroy ubuntu-noble01
```

控制台：

```bash
sudo virsh -c qemu:///system console ubuntu-noble01
```

删除虚拟机：

```bash
sudo virsh -c qemu:///system destroy ubuntu-noble01 2>/dev/null || true
sudo virsh -c qemu:///system undefine ubuntu-noble01 --nvram 2>/dev/null || true
sudo rm -f /var/lib/libvirt/images/ubuntu-noble01.qcow2
sudo rm -rf /var/lib/libvirt/images/cloud-init/ubuntu-noble01
echo '[]' | sudo tee /var/lib/libvirt/dnsmasq/virbr0.status
```



# 2. Fedora安装KVM

## 2.1. 安装软件

```bash
sudo dnf install @virtualization
```

## 2.2. 启动并设置服务自启

```bash
sudo systemctl enable --now libvirtd
```

## 2.3.配置用户权限

将用户加入libvirt组：

```bash
sudo usermod -aG libvirt $USER
```

## 2.4. 使新加入的用户组权限生效

```bash
注销并重新登录

或执行

newgrp libvirt
```

## 2.5. 修改默认硬盘镜像目录权限

```bash
sudo setfacl -m u:你的用户名:rwx /var/lib/libvirt/images
```

# 3. 常用命令

```bash
# 进入root
su

# 创建虚拟磁盘
qemu-img create -f qcow2 /var/lib/libvirt/images/vm1 10G

# 创建虚拟机
virt-install \
--name vm1 \
--ram 4096 \
--disk path=/var/lib/libvirt/images/vm1,size=10 \
--vcpus 4 \
--cpu host-model,topology.sockets=1,topology.cores=4,topology.threads=1 \
--os-variant centos7 \
--network bridge=virbr0 \
--console pty,target_type=serial \
--cdrom=/var/lib/libvirt/images/CentOS-7-x86_64-Minimal-1908.iso \
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


sudo virt-install \
  --name ubuntu-noble01 \
  --memory 3072 \
  --vcpus 2 \
  --cpu host \
  --disk path=/var/lib/libvirt/images/ubuntu-noble01.qcow2,format=qcow2,bus=virtio \
  --disk path=/var/lib/libvirt/images/cloud-init/ubuntu-noble01/seed.iso,device=cdrom \
  --os-variant ubuntu24.04 \
  --network network=default,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --import \
  --noautoconsole
```





