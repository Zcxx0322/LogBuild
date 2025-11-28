---
title: Mysql
date: 2025-03-14 10:35:03
tags: Mysql
categories: Mysql
---

# 1. 安装Mysql

## 1.1 Archlinux

### 1.1.1. 安装并初始化Mysql

```bash
sudo pacman -S mysql

sudo mysqld --initialize --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

观察终端输出可以发现初始化完成后，随机生成了初始帐号密码：

- root@localhost
- o,FRbratO8U6
  帐号密码是随即生成的，请注意自行保存，后面有用！

<font color=red>*终端输出*</font>

```terminal
2025-03-14T02:41:41.212250Z 0 [System] [MY-015017] [Server] MySQL Server Initialization - start.
2025-03-14T02:41:41.213204Z 0 [Warning] [MY-010915] [Server] 'NO_ZERO_DATE', 'NO_ZERO_IN_DATE' and 'ERROR_FOR_DIVISION_BY_ZERO' sql modes should be used with strict mode. They will be merged with strict mode in a future release.
2025-03-14T02:41:41.213243Z 0 [System] [MY-013169] [Server] /usr/bin/mysqld (mysqld 9.2.0) initializing of server in progress as process 19340
2025-03-14T02:41:41.225654Z 1 [System] [MY-013576] [InnoDB] InnoDB initialization has started.
2025-03-14T02:41:41.492273Z 1 [System] [MY-013577] [InnoDB] InnoDB initialization has ended.
2025-03-14T02:41:42.326345Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: o,FRbratO8U6
2025-03-14T02:41:44.238961Z 0 [System] [MY-015018] [Server] MySQL Server Initialization - end.
[zcx@archlinux LogBuild]$ grep 'temporary password' /var/log/mysqld.log
```

### 1.1.2. 启动Mysql服务

```bash
systemctl start mysqld.service

systemctl status mysqld.service

systemctl enable mysqld.service
```

### 1.1.3. 登陆Mysql

```bash
# 输入密码即可
mysql -u root -p 
Enter password:
```

### 1.1.4. 修改root密码

```bash
alter user 'root'@'localhost' identified by 'geek';
```

<font color=red>下次登陆时，使用更改后的密码即可！</font>

## 1.2. CentOS

### 1.2.1. 新增Yum仓库

*新增仓库*

```bash
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
```

*导入公钥*

```bash
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql*
```

*默认禁用MySQL仓库*

```bash
yum-config-manager --disable mysql-connectors-community | egrep '(\[mysql-connectors-community\])|enabled'
yum-config-manager --disable mysql-tools-community | egrep '(\[mysql-tools-community\])|enabled'
yum-config-manager --disable mysql80-community | egrep '(\[mysql80-community\])|enabled'
```

### 1.2.2. 安装Mysql5.7

```bash
yum --enablerepo=mysql57-community install -y mysql-community-server
```

### 1.2.3. 初始化Mysql5.7

*设置日志*

```bash
mkdir -p /var/log/mysqld
touch /var/log/mysqld/error.log
chown -R mysql:mysql /var/log/mysqld

crudini --set --existing /etc/my.cnf mysqld log-error /var/log/mysqld/error.log
```

*设置MySQL数据目录*

```bash
mkdir -p /data/mysql

crudini --set --existing /etc/my.cnf mysqld datadir /data/mysql
```

### 1.2.4. 配置Mysql5.7

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

### 1.2.5. 启动Mysql5.7

```bash
systemctl enable mysqld

systemctl start mysqld

systemctl status mysqld
```

### 1.2.6. 修改密码

*临时密码有不常用的特殊字符，不便日常管理。不降低安全性的前提性，更改MySQL密码*

```bash
MYSQL_TMP_ROOT_PASSWORD=$(grep 'A temporary password' /var/log/mysqld/error.log | tail -n 1 | awk '{print $NF}')

# 这里我的密码设置为geek
export BY_MYSQL_ROOT_PASSWORD=geek
# 永久保存临时配置（重新登录或重启都有效）
sed -i '/export BY_/d' ~/.bash_profile && env | grep BY_ | awk '{print "export "$1}' >> ~/.bash_profile

echo -e "  MySQL用户名：root\nMySQL临时密码：${MYSQL_TMP_ROOT_PASSWORD}\n  MySQL新密码：${BY_MYSQL_ROOT_PASSWORD}"

mysqladmin -uroot -p"${MYSQL_TMP_ROOT_PASSWORD}" password ${BY_MYSQL_ROOT_PASSWORD}
```

*<font color=red>终端输出</font>*

```terminal
MySQL用户名：root
MySQL临时密码：caJ<TYnjX8iC
MySQL新密码：geek
```

### 1.2.7. 本机无密码配置

*脚本无人化配置（自动输入密码）*

```bash
unbuffer expect -c "
spawn mysql_config_editor set --skip-warn --login-path=client --host=localhost --user=root --password
expect -nocase \"Enter password:\" {send \"${BY_MYSQL_ROOT_PASSWORD}\n\"; interact}
"
```

*<font color=red>终端输出</font>*

```terminal
spawn mysql_config_editor set --skip-warn --login-path=client --host=localhost --user=root --password
Enter password: 
```

*查看MySQL无密码配置清单*

```bash
mysql_config_editor print --all
```

*<font color=red>终端输出</font>*

```terminal
[client]
user = root
password = *****
host = localhost
```

*<font color=red>无密码登录测试</font>*

```bash
mysql -e "show databases;"
```

### 1.2.8. 修改密码策略(可选)

*默认的密码复杂度要求太高导致修改密码报错可以执行*

```mysql
set global validate_password_policy=0;
set global validate_password_length=0;
```
