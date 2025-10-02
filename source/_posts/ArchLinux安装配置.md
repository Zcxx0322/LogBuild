---
title: ArchLinux安装配置
tags: ArchLinux
categories: ArchLinux
date: 2024-11-26 14:35:57
---

# 安装前说明

*ArchLinux安装可以在启动镜像之后，通过SSH连接复制以下命令字符完成安装。步骤如下：*

当然这里涉及到联网的问题，请参考[连接WIFI](#4-连接WIFI)

1. `ip a` 查看IP地址；
2. `systemctl start sshd` 启动SSH服务；
3. `passwd` 修改启动镜像root用户密码；
4. 使用任意SSH客户端软件，连接启动镜像IP地址的22端口即可。

*如果是安装中途连接SSH的，请注意适时执行 `arch-chroot /mnt` 命令进入安装目标硬盘。否则，所有安装操作重启系统后无效（安装到了启动镜像中）。*

# 1. 建立硬盘分区

```bash	
cfdisk
```

*按照本教程安装<font color='red'>ArchLinux</font> ，硬盘至少需要10G以上。*

*如果使用UEFI启动方式，需要新建 `/dev/sda1` 容量300~500M，并且设置为启动分区，其余分区编号顺延。*

## 1.1. 新建EFI分区

![](/img/arch1.png)

## 1.2. 新建交换分区

*可选可不选，类似于虚拟内存*

![](/img/arch2.png)

## 1.3. 新建主分区

*剩下全部建立到一起为根目录分区，类型默认即可*。

![](/img/arch3.png)

选中`Write`,输入`yes`确定，选择`Quit`退出分区。

## 1.4. 查看分区情况

```bash
fdisk -l
```

*确定好自己每一个分区的类型，目的，名称。*

![](/img/arch4.png)

# 2. 格式化分区

## 2.1. 格式化主分区

```bash
mkfs.ext4 /dev/sda3
```

*此为格式化分区，会擦除数据*

```cmd
root@archiso ~ # mkfs.ext4 /dev/sda3
mke2fs 1.47.1 (20-May-2024)
Creating filesystem with 4065792 4k blocks and 1018000 inodes
Filesystem UUID: 809a516d-805b-4ec4-afa9-dc7538873a12
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

## 2.2. 格式化交换分区（未设置就跳过）

```bash	
mkswap /dev/sda2
```

```cmd
root@archiso ~ # mkswap /dev/sda2
Setting up swapspace version 1, size = 4 GiB (4294963200 bytes)
no label, UUID=e32cf483-6326-4d86-8210-bfe78fefb050
```

## 2.3. 格式化EFI分区

```bash
mkfs.fat -F 32 /dev/sda1
```

```cmd
root@archiso ~ # mkfs.fat -F 32 /dev/sda1
mkfs.fat 4.2 (2021-01-31)
```

*可运行`lsblk -f`*确认分区或格式错误

```cmd
root@archiso ~ # lsblk -f
NAME   FSTYPE   FSVER            LABEL       UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0  squashfs 4.0                                                                     0   100% /run/archiso/airootfs
sda
├─sda1 vfat     FAT32                        B52E-2E89
├─sda2 swap     1                            e32cf483-6326-4d86-8210-bfe78fefb050
└─sda3 ext4     1.0                          809a516d-805b-4ec4-afa9-dc7538873a12
sr0    iso9660  Joliet Extension ARCH_202411 2024-11-01-10-09-22-00                     0   100% /run/archiso/bootmnt
```

# 3. 挂载分区

- 挂载主分区

```bash
mount /dev/sda3 /mnt
```

- 挂载EFI分区

```bash
mount --mkdir /dev/sda1 /mnt/boot
```

- 挂载交换分区

```bash
swapon /dev/sda2
```

# 4. 连接WIFI

如果想要了解该方法的原理请参考[官方文档](https://wiki.archlinux.org/title/Iwd#iwctl)

*这里以WIFI网卡名称 wlan0  和 WIFI硬件名称 phy0为例*

*执行`iwctl`命令，进入iwd交互shell：*

```cmd
# 获得WIFI网卡名称 wlan0 和WIFI硬件名称 phy0
device list

device wlan0 set-property Powered on
adapter phy0 set-property Powered on

# 不会有任何屏幕输出
station wlan0 scan

# 列表WIFI清单
station wlan0 get-networks

# 会提示输入连接密码，其中 GEEKCAMP_5G 是选择的WIFI SSID
station wlan0 connect GEEKCAMP_5G

# 查看WIFI连接
station	wlan0 show

# 退出iwd Shell
exit
```

*测试网络连接：*

```bash
ping qq.com
```

# 5. 基础包安装

## 5.1. 设置国内镜像源

```bash
cat << EOF > /etc/pacman.d/mirrorlist
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF
```

## 5.2. 安装基础包

```bash	
pacstrap /mnt base
```

# 6. 开机挂载分区

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

# 7. 切换到全新ArchLinux系统

```bash
arch-chroot /mnt
```

## 7.1. 设置国内镜像源

```bash
cat << EOF > /etc/pacman.d/mirrorlist
Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
EOF
```

## 7.2. 安装vim sudo

```bash
pacman -S vim sudo 
```

## 7.3. 设置时区

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

## 7.4. 本地化语言支持

*启用语言参数：*

```bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.GB18030 GB18030" >> /etc/locale.gen
echo "zh_CN.GBK GBK" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN GB2312" >> /etc/locale.gen
```

*生成locale：*

```bash
locale-gen
```

*设置系统默认语言：*

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

<font color="red">全局设置为英文，tty控制台不会乱码，新用户默认目录也是英文名称，方便使用。</font>

<font color="red">新用户登录桌面后，自行找到控制面板中的 “Region and Language”（区域和语言）设置为 `汉语` 即可。设置后，如果提示更新目录名称为中文，请选择 “保留旧的文件名”，除非你想在终端经常打中文目录名称（累死你~~）。</font>

## 7.5. 键盘布局

```bash
echo echo "KEYMAP=us" > /etc/vconsole.conf
```

## 7.6. 设置主机名

```bash
echo 'archlinux' > /etc/hostname
```

## 7.7. 本地网络配置

```bash
echo '127.0.0.1 localhost' > /etc/hosts
# 添加主机名对应的设置
echo '127.0.0.1 archlinux' >> /etc/hosts
```

## 7.8.  设置root密码

```bash
passwd
```

## 7.9. 创建用户

*新增用户*

```bash
useradd -m 你的用户名
```

*设置用户密码*

```bash
passwd 你的用户名
```

*添加到sudo列表*

```bash
echo '你的用户名   ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
```

## 7.10. 安装Grub引导

```bash
pacman -S grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch

pacman -S linux linux-headers linux-lts linux-lts-headers

grub-mkconfig -o /boot/grub/grub.cfg
```

<font color="red">Windows+Linux双引导</font>

```bash
pacman -S grub os-prober ntfs-3g
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
```

<font color="red">下次进入GNOME桌面后，执行 grub-mkconfig -o /boot/grub/grub.cfg​ 命令就会自动将Windows系统加入到Grub启动菜单</font>

## 7.11. 安装桌面

```bash
# 更新软件包索引
pacman -Syy

# 桌面环境
pacman -S gnome vim networkmanager

# WIFI驱动
pacman -S linux-firmware

# 拼音输入法
pacman -S ibus-sunpinyin sunpinyin sunpinyin-data

# 显卡驱动
pacman -S xf86-video-fbdev xf86-video-intel xf86-video-vesa xf86-video-ati xf86-video-amdgpu

# 汉字字体
pacman -S wqy-microhei wqy-zenhei

# 开机启动
systemctl enable NetworkManager
systemctl enable gdm
```

## 7.12. 重启

```bash
exit

reboot
```

## 7.13. 设置pacman

*增加 `Arch Linux 中文社区仓库` 的腾讯镜像服务器：*

```bash
# 进入root
sudo -i

cat << EOF >> /etc/pacman.conf
[archlinuxcn]
Server = https://mirrors.cloud.tencent.com/archlinuxcn/\$arch
SigLevel = Optional TrustAll
EOF

exit
```

## 7.14. 安装常用软件

```bash
sudo pacman -Syy

sudo pacman -S archlinuxcn-keyring

sudo pacman -S gedit vim screen thunderbird thunderbird-i18n-zh-cn openssh bash-completion cmake git curl wget filezilla gcc make mlocate nginx ntp p7zip rsync virtualbox virtualbox-guest-iso virtualbox-host-dkms file-roller parted sshpass rdesktop qt5-base qt6-base fakeroot yay openssl wireshark-qt base-devel code gnome-terminal os-prober

yay -S google-chrome
```

## 7.15. 系统设置

```bash
# GNOME 桌面设置
gsettings set org.gnome.nautilus.preferences always-use-location-entry true
gsettings set org.gnome.nautilus.preferences default-sort-order name
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
# Ctrl+Shift+Alt+R 录像时，30秒后自动结束。设置为0,不限制
gsettings set org.gnome.settings-daemon.plugins.media-keys max-screencast-length 0
# 禁用最近文件访问记录
gsettings set org.gnome.desktop.privacy remember-recent-files false

# virtualbox 设置
sudo gpasswd -a root vboxusers
sudo gpasswd -a $USER vboxusers
# wireshark 设置
sudo gpasswd -a root wireshark
sudo gpasswd -a $USER wireshark

# 系统日志
sudo gpasswd -a $USER adm
sudo gpasswd -a $USER systemd-journal
sudo gpasswd -a $USER wheel

# docker
#sudo gpasswd -a $USER docker

sudo grpunconv

# 开机启动
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
sudo systemctl enable sshd
sudo systemctl mask tmp.mount
```

