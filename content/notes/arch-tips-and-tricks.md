---
title: "Arch tips and tricks"
date: 2022-10-29T08:19:07+01:00
draft: false
---

Various small tips, config settings, HowTo's, gathered and centralized.

<!--more-->

# Custom dns (e.g. CloudFlare) with NetworManager

```
# make a note of the name of the connection you wish to configure e.g. "WiFi Secure"
nmcli connection show

# save the name of the connection in a variable
export CONN="WiFi Secure"

# paste the following in your terminal to reconfigure DNS
nmcli connection modify "$CONN" \
    ipv4.ignore-auto-dns yes \
    ipv4.never-default no \
    ipv4.dns "1.1.1.1"

# reactivate the saved connection
nmcli connection up "$CONN"

# optionally restore default DNS (DHCP)
nmcli connection modify "$CONN" \
    ipv4.ignore-auto-dns no
```

# Local SSL certs in Firefox

Steps to get up and running local dev SSL certificates with Arch Linux.

Combine:

- https://dev.to/lmillucci/firefox-installing-self-signed-certificate-on-ubuntu-4f11
- https://stackoverflow.com/questions/13732826/convert-pem-to-crt-and-key

Use the cert file from an `mix phx.gen.cert`, convert it:

```
openssl x509 -outform der -in your-cert.pem -out your-cert.crt
```
