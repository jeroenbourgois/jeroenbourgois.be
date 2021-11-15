---
title: "Arch installation"
date: 2021-11-13T22:19:07+01:00
draft: false
---

Steps to get up and running with Arch Linux.

<!--more-->

Boot arch iso

```
# Increase font size (optional)
# console fonts directory: /usr/share/kbd/consolefonts
setfont ter-132n

# check IP
ip a

# sync repos
pacman -Sy

# partition & mount
lsblk

gdisk /dev/sda

# inside gdisk create 3 partitions:
# - boot (EFI) 250M
# - swap 2GB
# - root 25GB
# - home remaining
#
# boot:
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +250M [ENTER], ef00 [ENTER] (efi partition)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +2G [ENTER], 8200 [ENTER] (swap)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), +25G [ENTER], (8300) [ENTER] (Linux filesystem)
# press n [ENTER], [ENTER] (partition number), [ENTER] (first sector), [ENTER], (8300) [ENTER] (Linux filesystem)
#
# now w [ENTER] to write to disk

# check names of disks again
lsblk

# format disks
mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

# mount partitions
mount /dev/sda3 /mnt
mkdir -p /mnt/boot/efi
mkdir /mnt/home
mount /dev/sda1 /mnt/boot/efi
mount /dev/sda4 /mnt/home

# base install
pacstrap /mnt base linux linux-firmware linux-headers git vim

# generate filesystem table with UUIDs of the partitions
genfstab -U /mnt >> /mnt/etc/fstab

# now enter the new installation
arch-chroot

# run install script
git clone https://gist.github.com/jeroenbourgois/ba337f0ffca32614bd740779b152ce70

# now check videodriver (nvidia)
vim /etc/mkinitcpio.conf
mkinitcpio -p linux

# edit grub
vim /etc/default/grub
# > GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet video=1920x1080"
# > GRUB_GFXMODE=1920x1080
grub-mkconfig -o /boot/grub/grub.cfg

# now exit installation and reboot
exit
umount -a
reboot

# refresh package servers
sudo pacman -Sy

# copy install script

sudo flatpak install -y spotify
sudo pacman -S i3 kitty lxappearance feh thunar

# default X config
cp /etc/X11/xinit/xinitrc ~/.xinitrc
vim ~/.xinitrc # at the bottom add 'exec i3'
```
