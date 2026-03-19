---
title: Ansible
date: 2026-03-19 10:47:51
tags: Ansible
categories: Ansible
---


# 从零开始学习 Ansible：用三台虚拟机搭建自动化运维环境

## 前言

作为一名运维或开发人员，你可能经常需要在多台服务器上执行相同的命令、部署应用或修改配置。手动登录每台机器不仅效率低下，还容易出错。**Ansible** 就是为解决这类问题而生的自动化工具。它无需在受控节点安装代理，仅基于 SSH 协议，简单易用且功能强大。

本文在三台 CentOS Stream 9 虚拟机上搭建 Ansible 实验环境，并通过实际练习掌握 Ansible 的基本用法。

---

## 实验环境

- **主控节点**：192.168.2.100（安装 Ansible，执行管理命令）
- **受控节点 1**：192.168.2.101
- **受控节点 2**：192.168.2.102

所有节点均为 CentOS Stream 9，已配置好网络并能相互 ping 通。

---

## 1. 在主控节点上安装 Ansible

Ansible 的安装方式有多种，这里介绍最常用的两种：通过 EPEL 仓库和使用 pip。

### 方法一：通过 EPEL 仓库安装（推荐）

```bash
# 更新系统包
sudo dnf update -y

# 安装 EPEL 仓库
sudo dnf install epel-release -y

# 安装 Ansible
sudo dnf install ansible -y
```

### 方法二：通过 pip 安装（获取最新版本）

```bash
# 安装 Python3 和 pip
sudo dnf install python3-pip -y

# （可选）创建虚拟环境
python3 -m venv ansible-env
source ansible-env/bin/activate

# 安装 Ansible
pip install ansible
```

安装完成后验证版本：

```bash
ansible --version
```

---

## 2. 配置 SSH 免密登录

Ansible 通过 SSH 连接受控节点，因此需要配置主控节点到两个受控节点的免密登录。

### 2.1 在主控节点生成 SSH 密钥（如果已有则跳过）

```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
```

### 2.2 将公钥复制到受控节点

假设我们使用 `root` 用户进行管理（生产环境建议使用普通用户并配置 sudo）：

```bash
ssh-copy-id root@192.168.2.101
ssh-copy-id root@192.168.2.102
```

> 如果是首次连接，会提示确认主机密钥，输入 `yes` 即可。

### 2.3 测试免密登录

```bash
ssh root@192.168.2.101 'hostname'
ssh root@192.168.2.102 'hostname'
```

若直接返回主机名，说明配置成功。

---

## 3. 编写 Inventory 文件

Inventory 文件定义了要管理的受控节点。在主控节点上创建一个名为 `inventory.ini` 的文件：

```ini
[webservers]
192.168.2.101
192.168.2.102

[all:vars]
ansible_user=root          # 如果使用 root 用户；若使用普通用户则改为对应用户名
```

---

## 4. 测试 Ansible 连通性

执行 ping 模块测试：

```bash
ansible all -i inventory.ini -m ping
```

如果输出类似以下内容，说明主控节点可以正常管理两个受控节点：

```
192.168.2.101 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
192.168.2.102 | SUCCESS => {
    ...
}
```

---

## 5. 执行 Ad-Hoc 命令

Ad-Hoc 命令是 Ansible 的“单行命令”，用于快速执行临时任务。

### 5.1 查看受控节点系统信息

```bash
ansible all -i inventory.ini -m setup
```

`setup` 模块会收集主机的详细 facts 信息（CPU、内存、网络等），非常有用。

### 5.2 执行远程命令

```bash
ansible all -i inventory.ini -m command -a "uptime"
```

### 5.3 安装软件包

例如在两台受控节点上安装 nginx：

```bash
ansible all -i inventory.ini -m dnf -a "name=nginx state=present" -b
```

`-b` 表示以特权用户执行（become），因为安装软件需要 root 权限。

### 5.4 启动服务并设置开机自启

```bash
ansible all -i inventory.ini -m service -a "name=nginx state=started enabled=yes" -b
```

---

## 6. 编写第一个 Playbook

Playbook 是 Ansible 的配置、部署、编排语言，使用 YAML 格式。下面我们编写一个简单的 Playbook，完成以下任务：

- 确保 nginx 已安装
- 确保 nginx 服务启动并启用开机自启
- 在 `/tmp` 目录下创建一个测试文件

创建文件 `first-playbook.yml`：

```yaml
---
- name: 我的第一个 Playbook
  hosts: all
  become: yes

  tasks:
    - name: 确保 nginx 已安装
      dnf:
        name: nginx
        state: present

    - name: 确保 nginx 服务运行
      service:
        name: nginx
        state: started
        enabled: yes

    - name: 创建一个测试文件
      copy:
        content: "Hello from Ansible\n"
        dest: /tmp/ansible_test.txt
```

执行 Playbook：

```bash
ansible-playbook -i inventory.ini first-playbook.yml
```

如果一切顺利，你将看到每个任务的执行结果，并在受控节点的 `/tmp` 目录下找到 `ansible_test.txt` 文件。

---


## 常见问题与解决方案

- **Host key checking**：首次连接会提示确认主机密钥，可临时在 `ansible.cfg` 中禁用（不推荐生产）：
  ```ini
  [defaults]
  host_key_checking = False
  ```
  或在 inventory 组变量中添加 `ansible_ssh_common_args='-o StrictHostKeyChecking=no'`。

- **普通用户 sudo 需要密码**：可在 inventory 中设置 `ansible_become_pass` 密码（明文不安全），或使用 `--ask-become-pass` 参数，更推荐配置 sudo NOPASSWD。

- **防火墙问题**：如果受控节点启用了 firewalld，需确保 SSH 端口（22）开放：
  ```bash
  firewall-cmd --permanent --add-service=ssh
  firewall-cmd --reload
  ```

- **SELinux**：部分操作可能被 SELinux 阻止，测试时可临时设置宽松模式：
  ```bash
  setenforce 0
  ```
  生产环境应编写适当的 SELinux 策略。

---
