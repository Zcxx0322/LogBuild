---
title: 初始化配置CentOS 7
tags: CentOS7
categories: CentOS7
index_img: /img/CentOS7.png
date: 2024-11-21 17:50:36
---

# 1. 配置YUM

### 1.1. 仅安装64位软件包

```bash
echo "exclude=*.i386 *.i586 *.i686" >> /etc/yum.conf
```

### 1.2. 强制YUM使用IPv4
```bash
echo 'ip_resolve=4' >> /etc/yum.conf
```

# 2. 更新系统

## 2.1. YUM换源

```bash
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak

cat <<EOF > /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-\$releasever - Base
baseurl=https://mirrors.aliyun.com/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-\$releasever - Updates
baseurl=https://mirrors.aliyun.com/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-\$releasever - Extras
baseurl=https://mirrors.aliyun.com/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

yum clean all
yum makecache
```
## 2.2. 更新

```bash
yum update -y
```
# 3. EPEL镜像设置

## 3.1. 安装EPEL软件包

```bash
yum install -y epel-release
```

## 3.2. 设置国内镜像服务器，加速EPEL软件包下载

```bash
sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//download\.fedoraproject\.org/pub!//mirrors.aliyun.com!g' \
    -e 's!http://mirrors!https://mirrors!g' \
    -i /etc/yum.repos.d/epel*.repo
```

## 3.3. 创建YUM缓存，减少网络请求

```bash
yum makecache
```

# 4. 安装常用软件

```bash
yum install -y vim-enhanced wget curl yum-utils tree pwgen unzip expect tar xz bash-completion-extras
```
## 4.1 安装Python3.8+

### 4.1.1. 安装依赖：OpenSSL 1.1+

- 安装OpenSSL 1.1+软件包
```bash
pkg_name=openssl
pkg_ver=1.1.1n
pkg_rel=1
pkg=${pkg_name}-${pkg_ver}
tar_name=${pkg_name}-${pkg_ver}-${pkg_rel}.el7.x86_64.tar.gz
url=http://dl.cdgeekcamp.com/centos/7/${pkg_name}/${pkg_ver}/${tar_name}
prefix=/usr/local/${pkg}

test -d ${prefix} || (wget ${url} -O /tmp/${tar_name} && tar xf /tmp/${tar_name} -C $(dirname ${prefix}))

rm -f /tmp/${tar_name}
```

- 更新动态链接库配置
``` bash
egrep "^${prefix}/lib" /etc/ld.so.conf || (echo "${prefix}/lib" >> /etc/ld.so.conf && ldconfig)
```

- 确认配置
```bash
ldconfig -p | grep ${prefix}
```

**终端输出**
```cmd
[root@localhost ~]# ldconfig -p | grep ${prefix}
        libssl.so.1.1 (libc6,x86-64) => /usr/local/openssl-1.1.1n/lib/libssl.so.1.1
        libssl.so (libc6,x86-64) => /usr/local/openssl-1.1.1n/lib/libssl.so
        libcrypto.so.1.1 (libc6,x86-64) => /usr/local/openssl-1.1.1n/lib/libcrypto.so.1.1
        libcrypto.so (libc6,x86-64) => /usr/local/openssl-1.1.1n/lib/libcrypto.so
```

### 4.1.2. 安装Python3.8+
- 设置Python3.8+安装变量
```bash
pkg_name=python
pkg_ver=3.10.5
pkg_short_num=3
pkg_ver_num=310
pkg_rel=1
pkg=${pkg_name}-${pkg_ver}
tar_name=${pkg_name}-${pkg_ver}-${pkg_rel}.el7.x86_64.tar.gz
url=http://dl.cdgeekcamp.com/centos/7/python/3/${tar_name}
prefix=/usr/local/${pkg}
bin_dir=${prefix}/bin
```
- 安装Python3.8+软件包
```bash
test -d ${prefix} || (wget ${url} -O /tmp/${tar_name} && tar xf /tmp/${tar_name} -C $(dirname ${prefix}))

rm -f /tmp/${tar_name}
```

- 设置Python3.8+的环境变量
```bash
echo "export PATH=${bin_dir}:${PATH}" > /etc/profile.d/python${pkg_short_num}.sh
. /etc/profile
```
- 确认设置
```bash
which python${pkg_short_num} | grep ${prefix}
```
**终端输出**
```cmd
/usr/local/python-3.10.5/bin/python3
```

- 设置Python3.8+的软链接

```bash
cd ${bin_dir}
test -L pip${pkg_ver_num} || ln -v -s pip${pkg_short_num} pip${pkg_ver_num}
test -L python${pkg_ver_num} || ln -v -s python${pkg_short_num} python${pkg_ver_num}

echo -e "PIP软链接：pip${pkg_ver_num}\nPython3软链接：python${pkg_ver_num}"
```

- 测试pip命令
```bash
echo -e "执行命令：pip${pkg_ver_num} list\n" && pip${pkg_ver_num} list
```
**终端输出**

```cmd
执行命令：pip310 list

Package    Version
---------- -------
pip        22.1.2
setuptools 58.1.0

[notice] A new release of pip available: 22.1.2 -> 24.3.1
[notice] To update, run: pip install --upgrade pip
```

*若出现输出内的notice，则说明当前pip版本过低，可以执行pip install --upgrade pip来升级pip，下次便不会提醒！*

<font color=red>注：可能会因为源的问题导致更新pip失败！</font>

- 这里提供pip换源的方式
```bash
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com

[install]
use-deprecated=legacy-resolver
EOF
```

## 4.2. 安装命令行编辑工具

### 4.2.1. XML编辑工具
```bash
yum install -y xmlstarlet
```

### 4.2.2 INI和Java Properties文件编辑工具
```bash
yum install -y crudini
```

# 5. 设置系统时区

*当前系统时区设置为 中国上海*

```bash
yes|cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

# 6. 安装时间同步服务

安装时间同步软件chrony
```bash
yum install -y chrony
```

设置开机启动
```bash
systemctl enable chronyd
```

启动时间同步服务
```bash
systemctl start chronyd
```

# 7. 禁用IPv6

永久禁用IPv6，重启后生效
```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" >>  /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >>  /etc/sysctl.conf
```

# 8. 删除安装日志

```bash
rm -f ~/anaconda-ks.cfg  ~/install.log  ~/install.log.syslog
```

# 9. 禁用SELINUX

```bash
echo SELINUX=disabled>/etc/selinux/config
echo SELINUXTYPE=targeted>>/etc/selinux/config
```

# 10. 关闭防火墙
```bash
systemctl disable firewalld
systemctl stop firewalld
```

# 11. 设置最大文件句柄

*也许你听过，"Linux下，一切皆文件"。 文件句柄 种类很多，常见的有普通文件句柄（C语言中 open() 函数返回的就是文件句柄）、网络相关句柄等*

永久设置打开文件（句柄）的最大数量，重启后生效
```bash
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
```

# 12. 优化SSH服务

- 修改SSH服务端配置文件sshd_config，加速登录速度、设置连接保持等
```bash
# SSH连接时，服务端会将客户端IP反向解析为域名，导致登录过程缓慢
sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config
sed -i "s/GSSAPICleanupCredentials yes/GSSAPICleanupCredentials no/" /etc/ssh/sshd_config
# 登录失败最大尝试次数
sed -i "s/#MaxAuthTries 6/MaxAuthTries 10/" /etc/ssh/sshd_config
# 连接保持：服务端每隔N秒发送一次请求给客户端，客户端响应后完成一次连接保持检查
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 30/" /etc/ssh/sshd_config
# 连接保持最大重试次数：服务端发出请求后，超过N次没有收到客户端响应，服务端则断开客户端连接
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 10/" /etc/ssh/sshd_config
```

- 重载SSH服务端配置
```bash
systemctl reload sshd
```

- 退出当前Shell，重新登录SSH后，新配置生效

# 13. 设置主机名

## 13.1. 初始化本地解析设置

```bash
echo '127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts
```

# 14. 重启
```bash
reboot
```



