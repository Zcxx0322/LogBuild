---
title: RKE2高可用集群
date: 2026-06-26 15:07:49
tags:
  - RKE2
  - Kubernetes
  - Rancher
categories: RKE2
---

---

## 一、环境规划

| 角色 | IP | 说明 |
|------|-----|------|
| RKE2 Server (Master) | 192.168.122.10 | 控制平面 + etcd |
| RKE2 Server (Master) | 192.168.122.11 | 控制平面 + etcd |
| RKE2 Server (Master) | 192.168.122.12 | 控制平面 + etcd |
| RKE2 Agent (Worker) | 192.168.122.13 | 工作节点 |
| RKE2 Agent (Worker) | 192.168.122.14 | 工作节点 |
| Rancher (Docker) | 192.168.122.15 | 单节点 Docker 部署 Rancher |

---

## 二、所有节点（1-5 号）通用准备

在 **192.168.122.10 ~ 192.168.122.14** 上依次执行：

### 2.1 系统基础配置

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y curl vim net-tools telnet chrony

# 禁用 Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 加载内核模块
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/rke2.conf
overlay
br_netfilter
EOF

# 配置内核参数
cat <<EOF | sudo tee /etc/sysctl.d/99-rke2.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF

sudo sysctl --system

# 配置主机名（分别在每台机器上执行对应的）
# 192.168.122.10:
sudo hostnamectl set-hostname rke2-master01
# 192.168.122.11:
sudo hostnamectl set-hostname rke2-master02
# 192.168.122.12:
sudo hostnamectl set-hostname rke2-master03
# 192.168.122.13:
sudo hostnamectl set-hostname rke2-worker01
# 192.168.122.14:
sudo hostnamectl set-hostname rke2-worker02

# 配置 hosts
cat <<EOF | sudo tee -a /etc/hosts
192.168.122.10 rke2-master01
192.168.122.11 rke2-master02
192.168.122.12 rke2-master03
192.168.122.13 rke2-worker01
192.168.122.14 rke2-worker02
192.168.122.15 rancher-server
EOF
```

### 2.2 防火墙配置（UFW）

```bash
# 安装并启用 UFW（如未安装）
sudo apt install -y ufw

# 允许 SSH
sudo ufw allow 22/tcp

# 允许 Kubernetes API (6443)
sudo ufw allow from 192.168.122.0/24 to any port 6443 proto tcp

# 允许 RKE2 Supervisor API (9345)
sudo ufw allow from 192.168.122.0/24 to any port 9345 proto tcp

# 允许 etcd 通信 (2379-2381) - 仅控制平面节点之间
sudo ufw allow from 192.168.122.0/24 to any port 2379:2381 proto tcp

# 允许 Kubelet 指标 (10250)
sudo ufw allow from 192.168.122.0/24 to any port 10250 proto tcp

# 允许 Canal/Flannel VXLAN (8472 UDP)
sudo ufw allow from 192.168.122.0/24 to any port 8472 proto udp

# 允许 Canal 健康检查 (9099 TCP)
sudo ufw allow from 192.168.122.0/24 to any port 9099 proto tcp

# 允许 NodePort 范围 (30000-32767)
sudo ufw allow from 192.168.122.0/24 to any port 30000:32767 proto tcp

# 启用防火墙
sudo ufw --force enable
```

### 2.3 NetworkManager 配置（重要）

RKE2 与 NetworkManager 存在已知冲突，需要配置忽略 CNI 接口 ：

```bash
sudo mkdir -p /etc/NetworkManager/conf.d/

cat <<EOF | sudo tee /etc/NetworkManager/conf.d/rke2-canal.conf
[keyfile]
unmanaged-devices=interface-name:flannel*;interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
EOF

sudo systemctl reload NetworkManager
```

### 2.4 配置镜像加速（registries.yaml）

您提供的 `registries.yaml` 配置，在 **所有 5 台 K8s 节点** 上执行：

```bash
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/registries.yaml > /dev/null << 'EOF'
mirrors:
  docker.io:
    endpoint:
      - "https://docker.m.daocloud.io"
      - "https://docker.unsee.tech"
      - "https://docker.1ms.run"
EOF
```

---

## 三、部署 RKE2 Server 节点（Master）

### 3.1 第一个 Master 节点（192.168.122.10）

```bash
# 创建配置文件
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/config.yaml > /dev/null << 'EOF'
token: my-rke2-cluster-token-2026
node-name: rke2-master01
tls-san:
  - 192.168.122.10
  - 192.168.122.11
  - 192.168.122.12
  - rke2-master01
  - rke2-master02
  - rke2-master03
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10
write-kubeconfig-mode: "0644"
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
EOF

# 安装 RKE2 Server
curl -sfL https://get.rke2.io | sudo sh -

# 启用并启动服务
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

# 查看日志
sudo journalctl -u rke2-server -f
```

等待日志显示集群初始化完成（约 2-5 分钟），然后执行：

```bash
# 配置环境变量
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
source ~/.bashrc

# 验证节点
kubectl get nodes

# 查看生成的 token（供其他节点加入使用）
sudo cat /var/lib/rancher/rke2/server/token
```

### 3.2 第二个 Master 节点（192.168.122.11）

```bash
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/config.yaml > /dev/null << 'EOF'
server: https://192.168.122.10:9345
token: my-rke2-cluster-token-2026
node-name: rke2-master02
tls-san:
  - 192.168.122.10
  - 192.168.122.11
  - 192.168.122.12
  - rke2-master01
  - rke2-master02
  - rke2-master03
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10
write-kubeconfig-mode: "0644"
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
EOF

# 安装 RKE2 Server
curl -sfL https://get.rke2.io | sudo sh -

sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

# 配置环境变量
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
source ~/.bashrc
```

### 3.3 第三个 Master 节点（192.168.122.12）

```bash
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/config.yaml > /dev/null << 'EOF'
server: https://192.168.122.10:9345
token: my-rke2-cluster-token-2026
node-name: rke2-master03
tls-san:
  - 192.168.122.10
  - 192.168.122.11
  - 192.168.122.12
  - rke2-master01
  - rke2-master02
  - rke2-master03
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10
write-kubeconfig-mode: "0644"
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
EOF

# 安装 RKE2 Server
curl -sfL https://get.rke2.io | sudo sh -

sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

# 配置环境变量
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
source ~/.bashrc
```

---

## 四、部署 RKE2 Agent 节点（Worker）

### 4.1 Worker 节点 1（192.168.122.13）

```bash
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/config.yaml > /dev/null << 'EOF'
server: https://192.168.122.10:9345
token: my-rke2-cluster-token-2026
node-name: rke2-worker01
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
EOF

# 安装 RKE2 Agent
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -

sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service

# 查看日志
sudo journalctl -u rke2-agent -f
```

### 4.2 Worker 节点 2（192.168.122.14）

```bash
sudo mkdir -p /etc/rancher/rke2

sudo tee /etc/rancher/rke2/config.yaml > /dev/null << 'EOF'
server: https://192.168.122.10:9345
token: my-rke2-cluster-token-2026
node-name: rke2-worker02
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
EOF

# 安装 RKE2 Agent
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -

sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service
```

---

## 五、验证 K8s 集群状态

在任意 Master 节点上执行：

```bash
# 查看所有节点
kubectl get nodes -o wide

# 查看所有 Pod
kubectl get pods -A

# 查看集群信息
kubectl cluster-info

# 查看 etcd 成员（确认高可用）
kubectl -n kube-system exec -it etcd-rke2-master01 -- etcdctl \
  --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key \
  member list
```

预期输出应包含 3 个 `control-plane,etcd,master` 角色的节点和 2 个 `<none>` 角色的 Worker 节点，全部状态为 `Ready` 。

---

## 六、部署 Rancher（Docker 单节点）

在 **192.168.122.15** 上执行：

### 6.1 安装 Docker

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com | sudo sh -

sudo systemctl enable docker
sudo systemctl start docker

# 添加当前用户到 docker 组（可选）
sudo usermod -aG docker $USER
newgrp docker
```

### 6.2 配置 Docker 镜像加速（可选，推荐）

```bash
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.unsee.tech",
    "https://docker.1ms.run"
  ]
}
EOF

sudo systemctl restart docker
```

### 6.3 运行 Rancher 容器

```bash
# 创建持久化目录
sudo mkdir -p /opt/rancher

# 运行 Rancher（单节点 Docker 模式）
sudo docker run -d \
  --name rancher \
  --restart=unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v /opt/rancher:/var/lib/rancher \
  --privileged \
  rancher/rancher:latest
```

### 6.4 获取初始密码并登录

```bash
# 等待约 1-2 分钟后查看日志获取 Bootstrap Password
sudo docker logs rancher 2>&1 | grep "Bootstrap Password:"
```

打开浏览器访问 `https://192.168.122.15`，输入上述密码，然后：
1. 设置新的 admin 密码
2. 配置 **Server URL** 为 `https://192.168.122.15`（或您规划的域名）
3. 同意条款进入 Dashboard 

---

## 七、在 Rancher UI 中手动添加 RKE2 集群

### 7.1 导入已有集群

1. 登录 Rancher UI
2. 点击左上角 **☰ → Cluster Management**
3. 点击 **Import Existing**（导入已有集群）
4. 选择 **Generic**（通用 Kubernetes 集群）
5. 输入集群名称，例如 `rke2-prod`
6. 点击 **Create**

### 7.2 在 Master 节点上执行 Rancher 生成的命令

Rancher 会生成一个 `kubectl apply` 命令，类似：

```bash
kubectl apply -f https://192.168.122.15/v3/import/xxxxxxxx.yaml
```

在任意 RKE2 Master 节点上执行该命令（确保 `kubectl` 和 `KUBECONFIG` 已配置）：

```bash
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl apply -f https://192.168.122.15/v3/import/xxxxxxxx.yaml
```

### 7.3 验证导入

等待几分钟后，在 Rancher UI 中查看集群状态，应显示为 **Active**。

---

## 八、关键配置文件汇总

### 8.1 registries.yaml（所有 K8s 节点）

```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://docker.m.daocloud.io"
      - "https://docker.unsee.tech"
      - "https://docker.1ms.run"
```

### 8.2 Master 01 config.yaml

```yaml
token: my-rke2-cluster-token-2026
node-name: rke2-master01
tls-san:
  - 192.168.122.10
  - 192.168.122.11
  - 192.168.122.12
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10
write-kubeconfig-mode: "0644"
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
```

### 8.3 Worker config.yaml

```yaml
server: https://192.168.122.10:9345
token: my-rke2-cluster-token-2026
node-name: rke2-worker01
kube-proxy-arg:
  - "--proxy-mode=ipvs"
  - "--ipvs-strict-arp=true"
```

---

## 九、常见问题排查

| 问题 | 排查命令 |
|------|----------|
| RKE2 无法启动 | `sudo journalctl -u rke2-server -f` 或 `sudo journalctl -u rke2-agent -f` |
| 节点无法加入 | 检查 9345 端口连通性、token 是否一致 |
| 镜像拉取失败 | 检查 `registries.yaml` 配置，重启服务 |
| kubectl 无法连接 | 确认 `KUBECONFIG=/etc/rancher/rke2/rke2.yaml` |
| CNI 网络异常 | 检查 `br_netfilter` 模块、防火墙 8472/udp |
| Rancher 无法访问 | 检查 Docker 容器状态、`ufw` 是否放行 80/443 |

---

## 十、参考文档

- RKE2 官方快速入门 
- RKE2 配置选项参考 
- RKE2 镜像仓库配置 
- Rancher Docker 单节点安装 
- RKE2 已知问题与限制 