---
title: Prometheus
tags: Prometheus
categories: Prometheus
date: 2025-03-08 14:10:14
---
# 一. 安装Prometheus

## 1. 简介

本指南是“Hello World”风格的教程，展示了如何安装、配置和使用简单的 Prometheus 实例。您将在本地下载并运行 Prometheus，将其配置为抓取自身和示例应用程序，然后使用查询、规则和图表来使用收集的时间序列数据。

## 2. 下载并解压Prometheus

[下载最新版本的 Prometheus](https://prometheus.io/download)，然后解压并运行它：

```bash
wget -c https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz

tar xvfz prometheus-*.tar.gz
```

Prometheus 通过抓取指标 HTTP 端点从目标收集指标。由于 Prometheus 以相同的方式公开有关自身的数据，因此它也可以抓取和监控自己的健康状况。

虽然仅收集有关自身的数据的 Prometheus 服务器不是很有用，但它是一个很好的入门示例。将以下基本 Prometheus 配置保存为名为 prometheus.yml 的文件：

```
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']
```

有关配置文件的完整规范，请参阅[官方配置文档](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)。

# 3. 运行Prometheus

要使用新创建的配置文件启动 Prometheus，请切换到包含 Prometheus 二进制文件的目录并运行：

```bash
cd prometheus-*

./prometheus --config.file=prometheus.yml
```

Prometheus 应该启动了。您还应该能够在[localhost:9090](http://localhost:9090/query) 浏览有关其自身的状态页面。给它几秒钟时间从其自己的 HTTP 指标端点收集有关自身的数据。


<font color='red'>当然这里只是通过终端临时启动Prometheus，我们可以给它创建系统服务，以实现开机自动启动</font>

# 4. 创建Prometheus服务

```bash
cat << EOF > /etc/systemd/system/prometheus.service

[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=/root/prometheus-3.5.0.linux-amd64/prometheus --config.file=/root/prometheus-3.5.0.linux-amd64/prometheus.yml

[Install]
WantedBy=default.target

EOF
```

# 5. 启动Prometheus服务

```bash
#启动
systemctl start prometheus.service

#设置服务开机启动
systemctl enable prometheus.service

#查看服务状态
systemctl status prometheus.service
```

*那么现在可以继续访问使用Prometheus了*

# 二. 安装 Node Exporter
Prometheus 自己只能监控自己，我们需要 Node Exporter 来监控 Linux 主机（CPU、内存、磁盘等）

## 1. 下载并安装
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz

tar -xvf node_exporter-*.tar.gz
cd node_exporter-*.linux-amd64

cp node_exporter /usr/local/bin/
```

## 2. 配置 Systemd 服务
```bash
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
```

## 3. 启动并配置 Prometheus

启动 Node Exporter
```bash
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
```

编辑 Prometheus 配置文件
```bash
vim /etc/prometheus/prometheus.yml
```
在文件末尾的 scrape_configs 部分，添加如下内容（注意 YAML 缩进格式）
```bash
- job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

重启 Prometheus 生效
```bash
systemctl restart prometheus
```

# 三. 安装 Grafana

## 1. 添加官方 YUM 源
```bash
cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
```

### 1.1. 若下载慢，可更换国内镜像源
```bash
cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://mirrors.tuna.tsinghua.edu.cn/grafana/yum/rpm/
repo_gpgcheck=0
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
```

## 2. 安装并启动
```bash
dnf install grafana -y

systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server
```

## 3. 防火墙设置
如果你的 Rocky Linux 开启了 Firewalld，需要放行端口。
```bash
# 开放 Prometheus (9090), Node Exporter (9100), Grafana (3000)
firewall-cmd --permanent --add-port=9090/tcp
firewall-cmd --permanent --add-port=9100/tcp
firewall-cmd --permanent --add-port=3000/tcp

# 重载防火墙
firewall-cmd --reload
```

## 4. Web 界面配置
- 登录 Grafana
- 访问：http://<你的IP>:3000
- 默认账号/密码：admin / admin (首次登录会强制要求修改密码)

- 添加数据源 (Data Source)
- 在 Grafana 左侧菜单，点击 Connections (或 Configuration) -> Data Sources

- 点击 Add data source

- 选择 Prometheus

- 在 Prometheus server URL 栏输入：http://localhost:9090

- 滚动到底部，点击 Save & test。如果显示绿色对勾，说明连接成功。

- 导入仪表盘 (Dashboard)
不要自己从头画图，直接使用社区成熟的模板。

- 在 Grafana 左侧菜单，点击 Dashboards -> New -> Import。

- 在 "Import via grafana.com" 输入框中填入 ID：1860 (这是最经典的 Node Exporter Full 模板)。

- 点击 Load。

- 在底部的 Prometheus 下拉框中，选择你刚才创建的数据源。

- 点击 Import。




