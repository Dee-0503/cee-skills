# Server Specification

## Hardware

| Property | Value |
|----------|-------|
| IP | 64.90.11.148 |
| SSH Alias | `cee-server` |
| Hostname | s877287 |
| OS | Ubuntu 22.04.5 LTS |
| Kernel | Linux 5.15.0-161-generic x86_64 |
| CPU | Intel Xeon Platinum, 2 cores |
| RAM | 7.6 GiB |
| Disk | 39G total (`/dev/vda1`) |
| Docker | v29.1.3 |
| Swap | None configured |

## SSH Config

```
Host cee-server
  HostName 64.90.11.148
  User cee
  ProxyCommand none
```

## sudo Workaround

`cee` has sudo and passwordless sudo access is configured. Non-interactive SSH commands with sudo work normally.
For example: `ssh cee-server "sudo ufw status"`

## Firewall (ufw)

Status: Currently inactive.

## Domain

`ceee.cloud` — Cloudflare DNS, proxied (orange cloud), SSL mode = Flexible.
Server IP hidden behind Cloudflare; direct IP access to internal ports blocked.
