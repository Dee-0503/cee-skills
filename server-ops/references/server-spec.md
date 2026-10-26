# Business Server Specification

## Host

| Property | Value |
|----------|-------|
| IP | 64.90.13.184 |
| Business SSH Alias | `cee-server` (`cee` account) |
| Agent SSH Alias | `lackeys-server` (`lackeys` account) |
| Business User | `cee` |
| Hostname | ser978034649211 |
| OS | Ubuntu 24.04 amd64 |

Both aliases connect to the same managed machine. Business workloads use `cee-server` and `/home/cee/`; the dedicated Agent runtime uses `lackeys-server` and `/home/lackeys/`.

## SSH Config

Preferred entry:

```
Host cee-server
  HostName 64.90.13.184
  User cee
  ProxyCommand none

Host lackeys-server
  HostName 64.90.13.184
  User lackeys
  ProxyCommand none
```

SSH public-key authentication for the remote `cee` account is configured. Use `ssh cee-server` for business operations and `ssh lackeys-server` for Agent operations. Check the effective SSH configuration and remote identity before relying on either alias; this example documents the intended mapping and does not authorize rewriting local SSH configuration.

## sudo and firewall

The `cee` account uses the server's authorized sudo workflow. Verify the current sudo policy before non-interactive commands. The host firewall allows SSH, HTTP, and HTTPS; application and database ports must remain private.

## Paths and ownership

Business project paths use `/home/cee/`. Dedicated Agent paths use `/home/lackeys/`. Keep the two users' credentials, data, backups, and runtime ownership separate.
