# Business Server Specification

## Host

| Property | Value |
|----------|-------|
| IP | 64.90.13.82 |
| SSH Alias | `cee-server` (legacy alias; resolves to `lackeys-server`) |
| Canonical SSH Host | `lackeys-server` |
| Business User | `cee` |
| Hostname | ser978034649211 |
| OS | Ubuntu 24.04 amd64 |

The former `cee-server` machine has been decommissioned. Business workloads now run on `lackeys-server`; use the `cee` account for business operations. The `lackeys` account remains reserved for the dedicated Agent runtime.

## SSH Config

Preferred entry:

```
Host lackeys-server
  HostName 64.90.13.82
  User cee
  ProxyCommand none
```

The existing `cee-server` alias should point to the same host and use the business user:

```
Host cee-server
  HostName 64.90.13.82
  User cee
  ProxyCommand none
```

Authentication is configured for the local SSH identity on the remote `cee` account; both aliases are ready for business operations.

## sudo and firewall

The `cee` account uses the server's authorized sudo workflow. Verify the current sudo policy before non-interactive commands. The host firewall allows SSH, HTTP, and HTTPS; application and database ports must remain private.

## Paths and ownership

Business project paths use `/home/cee/`. Dedicated Agent paths use `/home/lackeys/`. Keep the two users' credentials, data, backups, and runtime ownership separate.
