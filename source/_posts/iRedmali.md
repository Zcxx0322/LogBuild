---
title: iRedmali
date: 2026-06-15 11:08:31
tags: iRedmali
categories: iRedmali
---

# 一、安装iRedmail

## 1. 配置主机名

```bash
vim /etc/hostname 

mail
```

## 2. 域名解析

```
vim /etc/hosts

127.0.0.1   mail.zcx.com mail localhost localhost.localdomain
```

## 3. 重启系统

```
reboot

# 重启系统后
hostname -f

mail.zcx.com
```

## 4. 安装必要软件

```
sudo apt-get install tar gzip
```

## 5. 安装iRedmail

```
cd /root/

wget -c https://github.com/iredmail/iRedMail/archive/refs/tags/1.7.4.tar.gz

tar zxf 1.7.4.tar.gz

cd iRedMail-1.7.4

CHECK_NEW_IREDMAIL=NO bash iRedMail.sh
```

# 二、iRedMail版本升级

## 1. 1.7.4升级到1.8.0

### 1.1. 升级 iRedAPD (Postfix 策略服务器)

```bash
cd /root/
wget -c https://github.com/iredmail/iRedAPD/archive/refs/tags/6.1.tar.gz
tar zxf 6.1.tar.gz
cd iRedAPD-6.1/tools/
bash upgrade_iredapd.sh
```

### 1.2. 升级 iRedAdmin 开源版后台

```bash
cd /root
wget -c https://github.com/iredmail/iRedAdmin/archive/refs/tags/2.8.1.tar.gz
tar zxf 2.8.1.tar.gz
cd iRedAdmin-2.8.1/tools/
bash upgrade_iredadmin.sh
```

### 1.3. 升级 mlmmjadmin (邮件列表管理器)

```bash
cd /root
wget -c https://github.com/iredmail/mlmmjadmin/archive/refs/tags/3.6.3.tar.gz
tar zxf 3.6.3.tar.gz
cd mlmmjadmin-3.6.3/tools/
bash upgrade_mlmmjadmin.sh
systemctl restart mlmmjadmin
```

### 1.4. 升级 Roundcube（可选，选用SOGO可忽略）

```bash
cd /root/
wget -c https://github.com/roundcube/roundcubemail/releases/download/1.7.1/roundcubemail-1.7.1-complete.tar.gz
tar xzf roundcubemail-1.7.1-complete.tar.gz
mv roundcubemail-1.7.1 /opt/www/roundcubemail-1.7.1

# 执行数据库与配置升级
cd /opt/www/roundcubemail-1.7.1/bin/
./installto.sh /opt/www/roundcubemail-1.6.11

# 切换软链接与清理
cd /opt/www/
rm -f roundcubemail
ln -s /opt/www/roundcubemail-1.7.1 roundcubemail
rm -rf /opt/www/roundcubemail-1.7.1/public_html/installer

# 修复权限与缓存
chown -R www-data:www-data /opt/www/roundcubemail-1.7.1
find /opt/www/roundcubemail-1.7.1/ -type d -exec chmod 755 {} \;
find /opt/www/roundcubemail-1.7.1/ -type f -exec chmod 644 {} \;
rm -rf /opt/www/roundcubemail-1.7.1/public_html/temp/*

vim /etc/nginx/templates/roundcube.tmpl
```

```nginx
# ==========================================
# iRedMail Roundcube 1.7.x Standard Template
# ==========================================

# 阻断敏感物理目录访问
location ~ ^/mail/(bin|config|installer|logs|SQL|temp|vendor)($|/.*) { deny all; }
location ~ ^/mail/public_html/(bin|config|installer|logs|SQL|temp|vendor)($|/.*) { deny all; }

# 阻断默认文本及配置文件
location ~ ^/mail/(CHANGELOG|composer.json|INSTALL|jsdeps.json|LICENSE|README|UPGRADING)($|.*) { deny all; }
location ~ ^/mail/plugins/.*/config.inc.php.* { deny all; }
location ~ ^/mail/plugins/enigma/home($|/.*) { deny all; }

# 根路径自动补全
location = /mail {
    return 301 /mail/;
}

# 1. 核心：完美支持 1.7.x 的 static.php 路径解析（解决样式 text/html 报错的关键）
location ~ ^/mail/static\.php(/.*)$ {
    include /etc/nginx/templates/hsts.tmpl;
    include /etc/nginx/templates/fastcgi_php.tmpl;
    
    fastcgi_param SCRIPT_FILENAME /opt/www/roundcubemail/public_html/static.php;
    fastcgi_param PATH_INFO $1;
}

# 2. 常规 PHP 脚本解析块
location ~ ^/mail/(.*\.php)$ {
    include /etc/nginx/templates/hsts.tmpl;
    include /etc/nginx/templates/fastcgi_php.tmpl;
    fastcgi_param SCRIPT_FILENAME /opt/www/roundcubemail/public_html/$1;
}

# 3. 静态资源路由拦截
location ~ ^/mail/(skins|plugins|program)/ {
    root /opt/www/roundcubemail/public_html/;
    access_log off;
    expires 30d;
}

# 4. 现代标准兜底规则
location /mail/ {
    root /opt/www/roundcubemail/public_html/;
    index index.php;
    try_files $uri $uri/ /mail/index.php?$args;
}
```

### 1.5. 重载 Nginx 服务

```bash
nginx -t
nginx -s reload
```

### 1.6. 1.8.0 升级完成

```bash
echo "1.8.0" > /etc/iredmail-release
```

---

## 2. 升级到 1.8.1

由于四大组件已在第一阶段完成了全量升级，且 Nginx 的 1.7.x 路由模板已在 1.4 中配置完毕，此处直接递进版本号：

```bash
echo "1.8.1" > /etc/iredmail-release
```

---

## 3. 升级到 1.8.2

正式标定最新版本号，并完全重启系统服务链使全新组件代码在内存中生效：

```bash
echo "1.8.2" > /etc/iredmail-release

systemctl restart postfix dovecot iredapd nginx mlmmjadmin
```



