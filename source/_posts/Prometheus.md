---
title: Prometheus
tags: Prometheus
categories: Prometheus
date: 2025-03-08 14:10:14
---
# 1.简介

本指南是“Hello World”风格的教程，展示了如何安装、配置和使用简单的 Prometheus 实例。您将在本地下载并运行 Prometheus，将其配置为抓取自身和示例应用程序，然后使用查询、规则和图表来使用收集的时间序列数据。

# 下载并解压Prometheus

[下载最新版本的 Prometheus](https://prometheus.io/download)，然后解压并运行它：

```bash
wget -c https://github.com/prometheus/prometheus/releases/download/v3.2.1/prometheus-3.2.1.linux-amd64.tar.gz

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

# 2. 运行Prometheus

要使用新创建的配置文件启动 Prometheus，请切换到包含 Prometheus 二进制文件的目录并运行：

```bash
cd prometheus-*

./prometheus --config.file=prometheus.yml
```

Prometheus 应该启动了。您还应该能够在[localhost:9090](http://localhost:9090/query) 浏览有关其自身的状态页面。给它几秒钟时间从其自己的 HTTP 指标端点收集有关自身的数据。


<font color='red'>当然这里只是通过终端临时启动Prometheus，我们可以给它创建系统服务，以实现开机自动启动</font>

# 3. 创建Prometheus服务

```bash
cat << EOF > /etc/systemd/system/prometheus.service

[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=/home/zcx/Downloads/prometheus-3.2.1.linux-amd64/prometheus --config.file=/home/zcx/Downloads/prometheus-3.2.1.linux-amd64/prometheus.yml

[Install]
WantedBy=default.target

EOF
```

# 4. 启动Prometheus服务

```bash
#启动
systemctl start prometheus.service

#设置服务开机启动
systemctl enable prometheus.service

#查看服务状态
systemctl status prometheus.service
```

*那么现在可以继续访问使用Prometheus了*



