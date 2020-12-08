---
title: "Manjaro on my MBP"
date: 2019-12-20T22:19:07+01:00
draft: false
---

# Install and run Manjaro on a 2015 MBP

This mostly just contains personal notes and references to get Manjaro running, in dual boot, on my MBP, with the following setup:

- Manjaro, i3 flavor
- web dev setup (neovim, apache, php, elixir, mysql)
- termieter (aka my dotfiles)
- mutt
- various apps (slack, mysql UI client, ...)

Most of it is inspired by [lobo tuerto's excellent article](https://lobotuerto.com/blog/how-to-setup-manjaro-linux-i3-on-a-macbook-pro/#fix-your-high-dpi-screen).

Installation and basic setup is completely covered there.

## Packages

I installed the following packages:

- [feh](https://feh.finalrewind.org/): simple image viewer and handles wallpaper
- [dbeaver](): db viewer for MySQL, Postgres, ...
- [mysql]: MySQL, also see this [tutorial](https://manjaro-tutorial.blogspot.com/2016/11/install-mysql-server-on-manjaro-1610.html)
- inotify-tools
- [snap store](https://snapcraft.io/install/slack/manjaro): popular apps installed on many distros
- slack, through snaps
- arandr, UI for `xrandr`
- bmenu, for tooling
- spotify, through snaps

To install all:

```
   sudo pacman -S feh dbeaver mysql inotify-tools snapd arandr
   sudo snap install slack --classic
   sudo snap install spotify
```

## Wifi

Although covered in the guide, it was not working right away, or not perfectly clear to me. But, so it seems, it is quite easy. Just first perform a system update to get the latest kernel headers:

`sudo pacman -Syu`

Then you *must* reboot. After that just follow installation of the Iobo notes, and use the headers of your system:

`uname -r`

## Util

For now, for special stuff I get by using the built in i3 config on manjaro, which offers a binding for some system menu, default is `mod+0`

