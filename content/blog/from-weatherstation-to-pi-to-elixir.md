---
title: "Processing data from my weather station"
date: 2021-08-20T22:19:07+01:00
draft: false
---

# Preamble

In the spring of 2021 I aquired a weather station, something I was meaning to buy for a long time. After reviewing a lot of different types I eventually settled with the [WSX3001 7-In-1][1] professional weather station sold by Explore Scientific. I wanted to go for something by Ambient Weather or AcuRite, however the models I wanted were not available in the EU due to frequency regulations. The bands used by those devices were not allowed without license in the EU. To prevent any hassle down the road I chose to buy a EU certified model, which the WSX3001 was.

One of the thing I was meant to do with the station was to gather its data. I did not know - and still don't know - what to do with the data, but the thought of gathering it in a self hosted environment sounded good. Unfortunately the model does not have any API nor does it allow a custom server/endpoint to be configure to which it can send its data.

But it does connect to both [Awekas][2] (a free Austrian online weather service) and [Wunderground][3]. The measuring units broadcast their data to an indoor base station that is connected to your a WiFi network. It will post the data in turn to said services. At first I did not really know how to be a man in the middle in this setup, so I decided to ask my friend and coworker. He offered a good solution: create a WiFi hotspot, have a DNS server on the hotspot that forwards all traffic to host on the local network that has a web app running and process the data.

Sounded good, but I had not idea how. Obviously, _someone_ already did something like that, no? Yes! Through a series of videos called ['Raspberry Pi on a boat'][4] I got the whole network setup working. The web app is a simple Elixir application, that was the easy part.

Here I want to give an overview of the different parts of the system I setup, which are:

- a Raspberry Pi model 4, acting as an AP, DNS server and web server,
- an Elixir app using cowboy to serve a web endpoint,
- an sqlite db to store the data,
- some utility script to rotate logs and backup the db to Amazon S3.

It's quite a long post... Let's jump in.

# Setting up the Raspberry Pi

First we need to setup the Rasperri Pi. I am using model 4, but model 3 also has a built-in wireless adapter so it should work too. To get started download the latest version of [Raspian OS][5] by following the documentation on [their website][5]. In short this involves:

1. Downloading the latest version
2. Unzip & burn to a (micro) SD card. I used Balena Etcher since I am working in macOS.

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
sudo raspi-config # then choose '5. Location Options' and set your country
```

You will need to reboot after this.

Update & upgrade the base system:

```
sudo apt update
sudo apt full-upgrade
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
    "PASSWORD" => "DyLBOAVR",
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
  query_string: "ID=IZWEVE15&PASSWORD=DyLBOAVR&action=updateraww&realtime=1&rtfreq=5&dateutc=now&baromin=30.19&tempf=65.1&dewptf=57.2&humidity=76&windspeedmph=5.1&windgustmph=5.5&winddir=241&rainin=0.0&dailyrainin=0.01&solarradiation=302.10&UV=3.1&indoortempf=73.5&indoorhumidity=60",
}

13:42:05.443 [info]  GET /weatherstation/updateweatherstation.php
conn: %Plug.Conn{
  host: "ws.awekas.at",
  params: %{
    "ID" => "jeroenb",
    "PASSWORD" => "AEA!upu3gpu!fhb9nzb",
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
  query_string: "ID=jeroenb&PASSWORD=AEA!upu3gpu!fhb9nzb&action=updateraww&realtime=1&rtfreq=5&dateutc=now&baromin=30.19&tempf=65.1&dewptf=57.2&humidity=76&windspeedmph=5.1&windgustmph=5.5&winddir=241&rainin=0.0&dailyrainin=0.01&solarradiation=302.10&UV=3.1&indoortempf=73.5&indoorhumidity=60",
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

[1]: https://youtube.com
[2]: https://www.awekas.at/wp/?lang=en
[3]: https://www.wunderground.com/
[4]: https://youtube.com
[5]: https://www.raspberrypi.org/software/operating-systems/
