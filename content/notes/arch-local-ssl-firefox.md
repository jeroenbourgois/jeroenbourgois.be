---
title: "Local SSL certs in Firefox on Arch"
date: 2022-09-03T09:19:07+01:00
draft: false
---

Steps to get up and running local dev SSL certificates with Arch Linux.

Combine:

- https://dev.to/lmillucci/firefox-installing-self-signed-certificate-on-ubuntu-4f11
- https://stackoverflow.com/questions/13732826/convert-pem-to-crt-and-key

Use the cert file from an `mix phx.gen.cert`, convert it:

```
openssl x509 -outform der -in your-cert.pem -out your-cert.crt
```
