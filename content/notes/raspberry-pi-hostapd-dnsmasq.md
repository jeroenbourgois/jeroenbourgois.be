---
title: "Raspberri Pi as a AP (hostapd & dnsmasq)"
date: 2021-08-20T22:19:07+01:00
draft: false
---

# Setup Raspberry Pi

## Install OS

1. https://www.raspberrypi.org/software/operating-systems/
2. unzip & burn with Etcher

## First boot & config

Create an empty file called `ssh` at the root of the boot partition on the SD card.

```
cd /Volumes/boot && touch ssh
```

Plug in ethernet cable, connect to screen and boot.

Find the IP address of the Pi (Mijn Telenet).

SSH into the Pi:

```
ssh pi@IP # password will be 'raspberry' by default
```

Update the password with `passwd`

Configure the country code for wifi. While you are at it, also change locale & timezone in the settings. This will prevent Perl locale errors.

```
sudo raspi-config nonint do_wifi_country BE
```

You will need to reboot after this.

Update & upgrade the base system:

```
sudo apt update
sudo apt full-upgrade

# this is optional if you prefer nano or just plain vi
sudo apt install vim
```

## Install & configure dnsmasq

Install dnsmasq package:

```
sudo apt install dnsmasq
```

Configuration for dsnmasq is done in `/etc/dnsmasq.conf`. The default config file is rather large and provides a lot of info about default settings. The only thing you need to update is uncomment the `conf-dir` option inside `/etc/dnsmasq.conf`.

```
# Include another lot of configuration options.
#conf-file=/etc/dnsmasq.more.conf
conf-dir=/etc/dnsmasq.d # <- removed # here to load files from that directory
```

Create a new file inside `/etc/dnsmasq.d/` folder. All files in this folder will also be read. That way the original file can be kept as a reference.

```
sudo vi /etc/dnsmasq.d/ap.conf
```

Contents of the file:

```
interface=wlan0
except-interface=eth0
# range of ip addresses from dhcp server for the clients
dhcp-range=192.168.10.50,192.168.10.100,255.255.255.0,24h
```

## Configure dhcpd (static ip of the pi)

Edit `/etc/dhcpcd.conf`

```
sudo vi /etc/dhcpcd.conf
```

Append the following to the file:

```
# AP settings

# assign static ip for the raspberry
interface wlan0
static ip_address=192.168.10.1/24

# disable the hook for wpa_supplicant so hostap can take care of wpa auth
nohook wpa_supplicant
```

## Install & configure hostapd

Install hostapd package:

```
sudo apt install hostapd
```

Edit the config:

```
sudo vi /etc/hostapd/hostapd.conf
```

Contents:

```
interface=wlan0
driver=nl80211
channel=6
ssid=YOUR_NETWORK_SSID
country_code=BE
hw_mode=g
auth_algs=1
wpa=2
wpa_passphrase=YOUR_PASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP

```

Now tell hostpad to load this file:

```
sudo vi /etc/default/hostapd
```

Provide the path to the config as a value of `DAEMON_CONF` (and uncomment it):

```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

**Now unmask & reenable the hostapd service:**

```
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
```

Also, put both hostapd and dsnmasq on a service that is started when (re)booting:

```
sudo update-rc.d dnsmasq enable
sudo update-rc.d hostapd enable
```

You can reboot now, and the network should already show up on other devices. Internet access however will not yet work.

## IP4 forwarding (Pass through the internet)

Edit the `/etc/sysctl.conf` file to uncomment the ipv4 forwarding setting:

```
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
```

But we need to mask our IP address, which we can do using `iptables`:

```
sudo apt install iptables
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

When rebooting, this is lost. So write the current state to a file:

```
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

Finally edit `/etc/rc.local` file to load the iptables file, just before the `exit 0` line:

```
# ...

iptables-restore < /etc/iptables.ipv4.nat

exit 0
```

Reboot.

## Run a webserver with an app to forward

Install Elixir and erlang using `asdf`. This is slower than the official install but has no issues on the Pi.

[](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)

```
sudo apt install curl git
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1
sudo apt-get install unzip
```

For the application sqlite is also needed:

```
sudo apt install sqlite3
```

Example payload:
q

```
13:42:04.819 [info]  GET /weatherstation/updateweatherstation.php
conn: %Plug.Conn{
  host: "rtupdate.wunderground.com",
  params: %{
    "ID" => "IZWEVE15",
    "PASSWORD" => "***",
    "UV" => "3.1",
    "action" => "updateraww",
    "baromin" => "30.19",
    "dailyrainin" => "0.01",
    "dateutc" => "now",
    "dewptf" => "57.2",
    "humidity" => "76",
    "indoorhumidity" => "60",
    "indoortempf" => "73.5",
    "rainin" => "0.0",
    "realtime" => "1",
    "rtfreq" => "5",
    "solarradiation" => "302.10",
    "tempf" => "65.1",
    "winddir" => "241",
    "windgustmph" => "5.5",
    "windspeedmph" => "5.1"
  },
  path_info: ["weatherstation", "updateweatherstation.php"],
  query_string: "ID=IZWEVE15&PASSWORD=****&action=updateraww&realtime=1&rtfreq=5&dateutc=now&baromin=30.19&tempf=65.1&dewptf=57.2&humidity=76&windspeedmph=5.1&windgustmph=5.5&winddir=241&rainin=0.0&dailyrainin=0.01&solarradiation=302.10&UV=3.1&indoortempf=73.5&indoorhumidity=60",
}

13:42:05.443 [info]  GET /weatherstation/updateweatherstation.php
conn: %Plug.Conn{
  host: "ws.awekas.at",
  params: %{
    "ID" => "USERNAME",
    "PASSWORD" => "*****",
    "UV" => "3.1",
    "action" => "updateraww",
    "baromin" => "30.19",
    "dailyrainin" => "0.01",
    "dateutc" => "now",
    "dewptf" => "57.2",
    "humidity" => "76",
    "indoorhumidity" => "60",
    "indoortempf" => "73.5",
    "rainin" => "0.0",
    "realtime" => "1",
    "rtfreq" => "5",
    "solarradiation" => "302.10",
    "tempf" => "65.1",
    "winddir" => "241",
    "windgustmph" => "5.5",
    "windspeedmph" => "5.1"
  },
  path_info: ["weatherstation", "updateweatherstation.php"],
  query_string: "ID=USERNAME&PASSWORD=****&action=updateraww&realtime=1&rtfreq=5&dateutc=now&baromin=30.19&tempf=65.1&dewptf=57.2&humidity=76&windspeedmph=5.1&windgustmph=5.5&winddir=241&rainin=0.0&dailyrainin=0.01&solarradiation=302.10&UV=3.1&indoortempf=73.5&indoorhumidity=60",
  request_path: "/weatherstation/updateweatherstation.php",
}

```

install aws cli

### References

- <https://ownthe.cloud/posts/configure-aws-cli-on-raspberry-pi/>
- <https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html>
- <https://aws.amazon.com/getting-started/hands-on/backup-to-s3-cli/>
- <https://elixircasts.io/installing-elixir-with-asdf>
- <https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies>
- <https://www.youtube.com/watch?v=G5rR5xJ3u8I>

### TODO

- backup sqlite db on pi to S3
