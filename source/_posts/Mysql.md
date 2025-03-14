---
title: Mysql
date: 2025-03-14 10:35:03
tags: Mysql
categories: Mysql
index_img: /img/Mysql.png
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



