---
title: Kubernetes
date: 2026-03-18 10:52:24
tags: Kubernetes
categories: Kubernetes
---

# 一. Centos Stream 9 部署Kubernetes

## 1. 环境准备

- [CentOS Stream 9](CentOS-Stream-9-latest-x86_64-dvd1.iso)  
- Kubernetesb版本：v1.28.2
- Kubernetesb网络插件：flannel
- 192.168.2.100 node1 (master)
- 192.168.2.101 node2 (worker)
- 192.168.2.102 node3 (worker)

## 3. 系统配置(所有节点)
```bash
# 域名解析
cat <<EOF >> /etc/hosts
192.168.2.100 node1
192.168.2.101 node2
192.168.2.102 node3
EOF

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭selinux
sed -i '/selinux/s/enforcing/disabled/' /etc/selinux/config
setenforce 0

# 关闭swap
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab

# 将桥接的 IPv4 流量传递到 iptables 的链
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

## 4. 安装基础工具(所有节点)
```bash
yum install -y wget vim net-tools telnet
```

## 5. 安装containerd(所有节点)
k8s依赖容器运行时（v1.24 弃用 dockershim）（如果需要使用docker，需要安装cri-dockerd组件），我们这里直接使用containerd。
```bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf update
sudo dnf install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# 修改containerd配置
$ sudo vi /etc/containerd/config.toml
找到[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]并将值更改SystemdCgroup为true
找到sandbox = "k8s.gcr.io/pause:3.6"并改为sandbox = "registry.aliyuncs.com/google_containers/pause:3.6"

# 重启以应用更改
$ sudo systemctl restart containerd
# 加入开机启动
$ sudo systemctl enable containerd
```

## 6. 安装Kubernetes集群及网络插件
### 6.1. 添加Kubernetes仓库(所有节点)
```bash
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo[kubernetes]name=Kubernetesbaseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/enabled=1gpgcheck=0repo_gpgcheck=0gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpgEOF
```

### 6.2. 安装Kubernetes modules(所有节点)
```bash
sudo dnf update

sudo dnf install -y kubelet kubeadm kubectl

sudo systemctl enable kubelet
```

### 6.3. 初始化Kubernetes集群(master)
```bash
# --apiserver-advertise-address=这里填写的IP要和master节点的一致
kubeadm init \
  --apiserver-advertise-address=192.168.2.100 \
  --image-repository registry.aliyuncs.com/google_containers \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=Mem

# 输出
# [root@localhost ~]# kubeadm init --apiserver-advertise-address=192.168.2.100 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Mem
# I0317 22:24:07.597908    5638 version.go:256] remote version is much newer: v1.35.2; falling back to: stable-1.28
# [init] Using Kubernetes version: v1.28.15
# [preflight] Running pre-flight checks
# [preflight] Pulling images required for setting up a Kubernetes cluster
# [preflight] This might take a minute or two, depending on the speed of your internet connection
# [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
# [certs] Using certificateDir folder "/etc/kubernetes/pki"
# [certs] Generating "ca" certificate and key
# [certs] Generating "apiserver" certificate and key
# [certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local localhost.localdomain] and IPs [10.96.0.1 192.168.2.100]
# [certs] Generating "apiserver-kubelet-client" certificate and key
# [certs] Generating "front-proxy-ca" certificate and key
# [certs] Generating "front-proxy-client" certificate and key
# [certs] Generating "etcd/ca" certificate and key
# [certs] Generating "etcd/server" certificate and key
# [certs] etcd/server serving cert is signed for DNS names [localhost localhost.localdomain] and IPs [192.168.2.100 127.0.0.1 ::1]
# [certs] Generating "etcd/peer" certificate and key
# [certs] etcd/peer serving cert is signed for DNS names [localhost localhost.localdomain] and IPs [192.168.2.100 127.0.0.1 ::1]
# [certs] Generating "etcd/healthcheck-client" certificate and key
# [certs] Generating "apiserver-etcd-client" certificate and key
# [certs] Generating "sa" key and public key
# [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
# [kubeconfig] Writing "admin.conf" kubeconfig file
# [kubeconfig] Writing "kubelet.conf" kubeconfig file
# [kubeconfig] Writing "controller-manager.conf" kubeconfig file
# [kubeconfig] Writing "scheduler.conf" kubeconfig file
# [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
# [control-plane] Using manifest folder "/etc/kubernetes/manifests"
# [control-plane] Creating static Pod manifest for "kube-apiserver"
# [control-plane] Creating static Pod manifest for "kube-controller-manager"
# [control-plane] Creating static Pod manifest for "kube-scheduler"
# [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
# [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
# [kubelet-start] Starting the kubelet
# [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
# [apiclient] All control plane components are healthy after 7.501386 seconds
# [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
# [kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
# [upload-certs] Skipping phase. Please see --upload-certs
# [mark-control-plane] Marking the node localhost.localdomain as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
# [mark-control-plane] Marking the node localhost.localdomain as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
# [bootstrap-token] Using token: 1s8frr.vlyg2sw7e9hpdov7
# [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
# [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
# [bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
# [bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
# [bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
# [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
# [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
# [addons] Applied essential addon: CoreDNS
# [addons] Applied essential addon: kube-proxy

# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.2.100:6443 --token 1s8frr.vlyg2sw7e9hpdov7 \
#         --discovery-token-ca-cert-hash sha256:284f7e8a02f1007f45417629b048b716a7d210b15de14eab54d99da898efa163
```
### 6.4. 保存好加入集群命令
```bash
kubeadm join 192.168.2.100:6443 --token 1s8frr.vlyg2sw7e9hpdov7 \
         --discovery-token-ca-cert-hash sha256:284f7e8a02f1007f45417629b048b716a7d210b15de14eab54d99da898efa163
```
### 6.5. 按照输出提示创建和声明目录(master)
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 6.6. 部署网络插件(master)
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### 6.7. 验证主节点状态(master)
```bash
[root@node1 ~]# kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
node1   Ready    control-plane   92s   v1.28.2

# 建议检查所有 Pod 是否正常运行：
kubectl get pods --all-namespaces(master)

# [root@node1 ~]# kubectl get pods --all-namespaces
# NAMESPACE      NAME                            READY   STATUS    RESTARTS   AGE
# kube-flannel   kube-flannel-ds-6n5qg           1/1     Running   0          7s
# kube-system    coredns-66f779496c-vg76x        1/1     Running   0          66s
# kube-system    coredns-66f779496c-xtlrb        1/1     Running   0          66s
# kube-system    etcd-node1                      1/1     Running   0          82s
# kube-system    kube-apiserver-node1            1/1     Running   0          81s
# kube-system    kube-controller-manager-node1   1/1     Running   0          81s
# kube-system    kube-proxy-qc4kh                1/1     Running   0          67s
# kube-system    kube-scheduler-node1            1/1     Running   0          82s
```

## 7. 工作节点加入集群(worker)
```bash
kubeadm join 192.168.2.100:6443 --token 1s8frr.vlyg2sw7e9hpdov7 \
         --discovery-token-ca-cert-hash sha256:284f7e8a02f1007f45417629b048b716a7d210b15de14eab54d99da898efa163
```

## 7.1. 验证状态(master)
```bash
kubectl get nodes

[root@node1 ~]# kubectl get nodes
NAME    STATUS   ROLES           AGE     VERSION
node1   Ready    control-plane   4m53s   v1.28.2
node2   Ready    <none>          3m13s   v1.28.2
node3   Ready    <none>          3m10s   v1.28.2
```

## 7.2. 配置角色(master)
```bash
kubectl label node node2 node-role.kubernetes.io/worker=worker
kubectl label node node3 node-role.kubernetes.io/worker=worker


# [root@node1 ~]# kubectl get nodes
# NAME    STATUS   ROLES           AGE   VERSION
# node1   Ready    control-plane   45m   v1.28.2
# node2   Ready    worker          43m   v1.28.2
# node3   Ready    worker          43m   v1.28.2
```

## 7.3. 如果需要在子节点访问kubernetes集群(master)
```bash
scp $HOME/.kube/config root@192.168.2.101:~/.kube/config
scp $HOME/.kube/config root@192.168.2.102:~/.kube/config

将配置文件拷贝后则可以在子节点查看集群状态了
# [root@node2 ~]# kubectl get nodes
# NAME    STATUS   ROLES           AGE   VERSION
# node1   Ready    control-plane   48m   v1.28.2
# node2   Ready    worker          46m   v1.28.2
# node3   Ready    worker          46m   v1.28.2
```
## 8. 安装Dashboard
```bash
# 执行官方提供的 YAML 配置
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 替换 Dashboard 镜像
kubectl set image deployment/kubernetes-dashboard kubernetes-dashboard=registry.cn-hangzhou.aliyuncs.com/google_containers/dashboard:v2.7.0 -n kubernetes-dashboard
# 替换 Metrics Scraper 镜像
kubectl set image deployment/dashboard-metrics-scraper dashboard-metrics-scraper=registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-scraper:v1.0.8 -n kubernetes-dashboard

# 查看状态
kubectl get pods -n kubernetes-dashboard

# 修改服务类型为 NodePort (方便外部访问)
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'

# 查看分配的随机端口：在输出中寻找 kubernetes-dashboard 的 PORT(S) 部分，你会看到类似 443:3xxxx/TCP 的内容。记下这个 3xxxx 端口号（例如 31456）。
kubectl get svc -n kubernetes-dashboard

# 创建管理账号
# 创建配置文件 dashboard-admin.yaml
cat <<EOF > dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
# 应用配置
kubectl apply -f dashboard-admin.yaml

# 生成登录 Token
kubectl -n kubernetes-dashboard create token admin-user

# 浏览器访问

https://192.168.2.100:端口号

选择 "Token" 模式，粘贴刚才生成的长字符串。
```











