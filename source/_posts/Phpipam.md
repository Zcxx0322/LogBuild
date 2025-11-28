---
title: Phpipam
date: 2025-07-23 11:03:35
tags: phpipam
categories: phpipam
---

# 1. 简介

phpipam 是一款开源的 Web IP 地址管理应用程序 (IPAM)。其目标是提供轻量、现代且实用的 IP 地址管理。

# 2. 环境准备

- CentOS7
  - 系统镜像下载：https://mirrors.aliyun.com/centos/7/isos/x86_64/
  - 系统初始化配置（可选）：https://zcxx0322.github.io/2024/11/21/%E5%88%9D%E5%A7%8B%E5%8C%96%E9%85%8D%E7%BD%AECentOS7/
- phpipam
  - https://github.com/phpipam/phpipam/releases/download/v1.7.3/phpipam-v1.7.3.tgz

- Mysql5.7
- Apache
- PHP7.4+

# 3. Mysql

## 3.1. 新增Yum仓库

***新增仓库***

```bash
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
```

*** 导入公钥***

```bash
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql*
```

*** 默认禁用MySQL仓库***

```bash
yum-config-manager --disable mysql-connectors-community | egrep '(\[mysql-connectors-community\])|enabled'
yum-config-manager --disable mysql-tools-community | egrep '(\[mysql-tools-community\])|enabled'
yum-config-manager --disable mysql80-community | egrep '(\[mysql80-community\])|enabled'
```

## 3.2. 安装Mysql5.7

```bash
yum --enablerepo=mysql57-community install -y mysql-community-server
```

## 3.3. 初始化Mysql5.7

***设置日志***

```bash
mkdir -p /var/log/mysqld
touch /var/log/mysqld/error.log
chown -R mysql:mysql /var/log/mysqld

crudini --set --existing /etc/my.cnf mysqld log-error /var/log/mysqld/error.log
```

***设置MySQL数据目录***

```bash
mkdir -p /data/mysql

crudini --set --existing /etc/my.cnf mysqld datadir /data/mysql
```

## 3.4. 配置Mysql5.7

```bash
crudini --set /etc/my.cnf mysqld default-storage-engine InnoDB
crudini --set /etc/my.cnf mysqld disabled_storage_engines '"MyISAM"'

crudini --set /etc/my.cnf mysqld bind-address 0.0.0.0
crudini --set /etc/my.cnf mysqld max_connections 1000

crudini --set /etc/my.cnf mysqld general_log OFF
crudini --set /etc/my.cnf mysqld general_log_file /var/log/mysqld/general.log

crudini --set /etc/my.cnf mysqld long_query_time 3
crudini --set /etc/my.cnf mysqld slow_query_log ON
crudini --set /etc/my.cnf mysqld slow_query_log_file /var/log/mysqld/slow_query.log

# 开启兼容模式，兼容老MySQL代码，比如使用空字符串代替NULL插入数据
crudini --set /etc/my.cnf mysqld sql_mode '""'

crudini --set /etc/my.cnf mysqld skip-name-resolve 'OFF'

crudini --set /etc/my.cnf mysqldump max_allowed_packet 100M
echo "quick" >> /etc/my.cnf
echo "quote-names" >> /etc/my.cnf
```

## 3.5. 启动Mysql5.7

```bash
systemctl enable mysqld

systemctl start mysqld

systemctl status mysqld
```

## 3.6. 配置Mysql密码

***临时密码有不常用的特殊字符，不便日常管理。不降低安全性的前提性，更改MySQL密码***

```bash
MYSQL_TMP_ROOT_PASSWORD=$(grep 'A temporary password' /var/log/mysqld/error.log | tail -n 1 | awk '{print $NF}')

export BY_MYSQL_ROOT_PASSWORD=geek
# 永久保存临时配置（重新登录或重启都有效）
sed -i '/export BY_/d' ~/.bash_profile && env | grep BY_ | awk '{print "export "$1}' >> ~/.bash_profile

echo -e "  MySQL用户名：root\nMySQL临时密码：${MYSQL_TMP_ROOT_PASSWORD}\n  MySQL新密码：${BY_MYSQL_ROOT_PASSWORD}"

mysqladmin -uroot -p"${MYSQL_TMP_ROOT_PASSWORD}" password ${BY_MYSQL_ROOT_PASSWORD}
```

*终端输出*

```bash
MySQL用户名：root
MySQL临时密码：caJ<TYnjX8iC
MySQL新密码：geek
```

## 3.7. 修改Mysql密码策略

```mysql
set global validate_password_policy=0;
set global validate_password_length=0;
```

## 3.8. 创建phpipam用户/数据库

```mysql
CREATE DATABASE phpipam;
CREATE USER 'phpipam'@'localhost' IDENTIFIED BY 'geek';
GRANT ALL PRIVILEGES ON phpipam.* TO 'phpipam'@'localhost';	
GRANT ALL PRIVILEGES ON *.* TO 'phpipam'@'本机IP' IDENTIFIED BY 'geek' WITH GRANT OPTION; 
FLUSH PRIVILEGES;
EXIT;
```

# 4. Apache

## 4.1. 安装httpd

```bash
sudo yum install httpd -y
sudo systemctl enable --now httpd
```

## 4.2. 配置httpd

```bash
vim /etc/httpd/conf.d/phpipam.conf

<VirtualHost *:80>
    ServerName 修改为想要的IP地址
    DocumentRoot /var/www/html/phpipam
    <Directory /var/www/html/phpipam>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/phpipam_error.log
    CustomLog /var/log/httpd/phpipam_access.log combined
</VirtualHost>

# 重启httpd服务
sudo systemctl restart httpd
```

# 5. PHP

```bash
sudo yum install epel-release -y
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
sudo yum-config-manager --enable remi-php74  # 启用 PHP 7.4
sudo yum install php php-cli php-mysqlnd php-json php-gd php-ldap php-curl php-zip php-mbstring php-xml php-bcmath php-gmp php-pear -y
```

# 6. phpipam

## 6.1. 下载phpipam

```bash
cd /tmp
wget -c https://github.com/phpipam/phpipam/releases/download/v1.7.3/phpipam-v1.7.3.tgz 
tar -xzvf phpipam-v1.7.3.tgz
sudo mv phpipam /var/www/html/
sudo chown -R apache:apache /var/www/html/phpipam
```

## 6.2. 配置phpipam

```bash
cp /var/www/html/phpipam/config.dist.php /var/www/html/phpipam/config.php
vim  /var/www/html/phpipam/config.php

$db['host'] = '虚拟机IP'; // 使用虚拟机实际IP 

$db['user'] = 'phpipam';         // 专用用户 

$db['pass'] = 'geek'; 

$db['name'] = 'phpipam'
```

## 6.3. 配置 Cron 任务

用于扫描网络状态：

```bash
sudo crontab -e

*/5 * * * * /usr/bin/php /var/www/html/phpipam/functions/scripts/pingCheck.php
*/5 * * * * /usr/bin/php /var/www/html/phpipam/functions/scripts/discoveryCheck.php
```

# 7. 关闭SELinux和防火墙

```bash
echo SELINUX=disabled>/etc/selinux/config
echo SELINUXTYPE=targeted>>/etc/selinux/config

systemctl disable firewalld
systemctl stop firewalld

# 重启虚拟机
reboot
```

# 8. 访问phpipam开始安装

```url
http://虚拟机IP/phpipam/
```

# 9. 常见问题解决

- **PHP 扩展缺失**：根据报错安装对应扩展（如 `php-pecl-zip`）。
- **文件权限问题**：确保 `/var/www/html/phpipam` 属主为 `apache`。
- **数据库连接错误**：检查数据库用户权限及密码。
- **页面空白**：检查 PHP 错误日志 `/var/log/php-fpm/error.log`。

完成以上步骤后，即可通过 Web 界面管理 IP 地址。如需 HTTPS，可使用 Let's Encrypt 配置 SSL 证



