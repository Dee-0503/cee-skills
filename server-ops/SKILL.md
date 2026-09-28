---
name: server-ops
description: "Use when operating the shared business server `cee-server` (`64.90.11.148`) or the dedicated Agent server `lackeys-server` (`64.90.13.82`) for an authorized project. Covers project-local deployment, restart, health checks, disk checks, and related reverse-proxy work. Keep the two server scopes separate and do not operate on unrelated projects, containers, processes, domains, or host configuration."
---

# Server Operations

Operational reference for the shared business server `cee-server` (`64.90.11.148`) and the dedicated Agent server `lackeys-server` (`64.90.13.82`). Bundled automation scripts currently target `cee-server` only.

## Server roles

- `cee-server` (`64.90.11.148`): shared business server. The `cee` user owns project-scoped operations under `/home/cee/`; preserve unrelated users, projects, databases, Codex/cc-switch installations, and Orca runtime.
- `lackeys-server` (`64.90.13.82`): dedicated Agent server. The `lackeys` user owns the cee-lackeys Agent runtime and its data under `/home/lackeys/`; this is the only host intended for the migrated Agent stack.

The hosts use different operating models. On `cee-server`, Docker and service operations require the existing `cee` sudo workflow and must target a verified project Compose file. On `lackeys-server`, system bootstrap and service administration are root/sudo operations, while Agent runtime data is owned by `lackeys`; do not add `lackeys` to the Docker group. Use separate paths, credentials, backups, and rollback records for each host. Never treat a path copied from one host as authorization to inspect the other host.

## Connection

```
ssh cee-server
ssh lackeys-server
```
- `cee-server`: user `cee`, key auth via `~/.ssh/config`
- `lackeys-server`: user `lackeys`, key auth via `~/.ssh/config`; root SSH is disabled after bootstrap
- On `lackeys-server`, Nginx uses Certbot's root-owned `certbot.timer` for twice-daily renewal attempts. A certificate must be issued for the domain first; `certbot renew` does not create a new certificate. Run renewal checks with `sudo`, validate with `sudo nginx -t`, and reload Nginx only after a successful configuration check.
- Docker access is executed through authorized `sudo`; do not enumerate host-wide containers. All Compose commands must target the verified project file.
- `cee-server` sudo is passwordless. `lackeys-server` sudo requires the user-provided password; use an interactive prompt or protected stdin, never store passwords in this skill or source control.
- New dedicated-server production directories use `/home/lackeys/apps/{cee-lackeys,cumora,cumora-byoa,codex,cc-switch}` and `/home/lackeys/data/{cumora,codex,cc-switch,cee-wiki}` without `pilot`. Source paths on cee-server retain their existing names.
- For dedicated-server status and bootstrap details read [references/lackeys-server.md](references/lackeys-server.md). Existing helper scripts and `/home/cee/` examples below target the shared server; inspect their path and sudo assumptions before adapting them.

## Quick Status Check

Resolve local script paths from the directory containing the currently loaded `SKILL.md`, not from a fixed installation path or the project's working directory. Set `SERVER_OPS_SKILL_DIR` to that directory's absolute path before running the examples below; keep it quoted to support paths containing spaces. This variable is local and is not a remote project path.

Status checks must be scoped to a verified project. Pass the canonical project directory and, when needed, its Compose file:

```bash
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/server-status.sh"
```

## Conversation Authorization

Treat the user's request as authorization for the requested operation only when the target is within the owned scope:

| User request | Default authorization | Boundary |
|---|---|---|
| Deploy, restart, inspect, or update a project under `/home/cee/` | Authorized for that project | Verify the project path and target service before acting |
| Read or modify project-owned files, Compose files, app services, or project-local environment | Authorized when directly required by the request | Do not expand to unrelated projects, containers, or services |
| Configure or cut over a domain | Authorized for the named project's app-side work, the related `/etc/nginx` reverse-proxy configuration, and Cloudflare work when requested | Verify the named domain and target project before changing routing |
| Read, modify, test, reload, or restart Nginx under `/etc/nginx` | Authorized for reverse-proxy configuration required by the named project | Restrict changes to the requested project's server block and preserve unrelated configuration |
| Reuse, renew, or repair certificates under `/etc/letsencrypt` | Authorized when required for the named domain | Prefer existing certificates and the server's existing renewal mechanism; do not add dependencies or alter unrelated certificates |

A request to deploy a named project authorizes the required project-local steps plus the related Nginx reverse-proxy and certificate work for that project's explicitly named domain. Do not expand the request to unrelated projects, containers, domains, certificates, or host configuration. Before acting, verify the canonical project path, Compose file, target service, domain, and matching Nginx server block. If a target cannot be tied to the named project, stop and ask for the missing identifier.

For certificate errors, first inspect the existing certificate lineage and renewal mechanism with `sudo`, then repair or renew in place when it belongs to the named domain. Prefer the existing certificate and built-in system tooling; do not add dependencies or change unrelated certificates. If an existing certificate is valid and reusable, retain it. After changes, validate with `sudo nginx -t`, reload only after a successful test, and verify the project-local endpoint and the named domain separately.

Report project deployment and domain cutover as separate states: project deployment succeeds when the project-local service is healthy; domain cutover succeeds only after the related Nginx, certificate, and domain path are independently verified. Never let an unrelated Nginx or certificate issue block reporting a healthy project deployment.

### Docker Services

List services only from the verified project's Compose file:

```bash
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/docker-services.sh"
```

Never enumerate all host containers or restart a container by guessed name. Use only services declared by the verified Compose file.

### Port Audit

Check published ports only from the verified project's Compose file:

```bash
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/port-check.sh"
```

### Nginx Domain Mappings

Nginx reverse-proxy inspection is authorized only after the project, domain, and matching configuration file have been identified. Read only that file, then validate the complete Nginx configuration before reload:

```bash
ssh cee-server 'bash -s -- /etc/nginx/sites-enabled/<project>.conf' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/nginx-domains.sh"
ssh cee-server 'sudo nginx -t'
```

Use the actual verified configuration path and domain; do not use `nginx -T` for routine inspection because it expands unrelated host configuration. Do not use a guessed domain or alter unrelated server blocks.

### Firewall

Firewall state may be inspected when relevant to the named project deployment:

```bash
ssh cee-server 'sudo ufw status numbered'
```

Do not add, remove, or alter UFW rules based only on a general deployment request. If a firewall change is required, request explicit approval for the exact port, protocol, direction, and rule scope. Docker ports bound to `127.0.0.1` to bypass Docker's iptables override of ufw. Public-facing ports must be explicitly allowed in ufw.

## Domain / Nginx Notes

This skill is a server operations guide, not a source of truth for which product owns which domain.

Use the domain explicitly provided by the user, verify that its Nginx server block points to the verified project's endpoint, and run `sudo nginx -t` before any reload. Reuse the existing certificate when it matches the named domain; otherwise use the server's existing renewal mechanism and do not add dependencies. Verify the project-local endpoint first, then the named domain after Nginx and certificate changes.

### Cloudflare Operations

For any requested Cloudflare-level operations (DNS records, SSL settings, WAF rules, Workers, Pages, Tunnel), use the **<cloudflare> plugin** through its available skills and tools. The plugin is optional and may be disabled by the user. Before depending on it, check whether the relevant capabilities are exposed in the current session; an installed plugin or a reference in this document does not establish availability, authentication, or authorization for a particular account or zone.

If the required capabilities are unavailable, report that limitation without assuming the plugin was deliberately disabled. Do not enable, install, or reconfigure the plugin, search for credentials, or bypass it through direct API, CLI, or browser operations unless the user explicitly authorizes that alternative. Identify the exact pending Cloudflare operation and ask the user to enable the plugin or choose an authorized alternative only when that operation is needed to proceed. If capabilities are exposed but access fails, report the access failure rather than treating it as proof that the plugin is disabled.

Continue independently authorized project-local deployment, health checks, and related Nginx/certificate work that does not depend on the pending Cloudflare operation. Keep dependent changes pending, preserve the named project/domain scope, and report server deployment and Cloudflare/domain cutover separately. Do not claim a Cloudflare change or successful cutover without verification. Server-only tasks do not require the plugin.

## Watchdog

Host cron script runs every 3 minutes:
- Script: `/home/cee/scripts/goclaw-watchdog.sh`
- Log: `/home/cee/logs/goclaw-watchdog.log` (logrotate daily, 7 days)
- Auto-restart: 3 consecutive health failures (~9 min) → `docker compose restart`

## Scripts (execute via SSH with a verified project path)

| Script | Purpose |
|---|---|
| `scripts/server-status.sh` | Project disk and Compose service status |
| `scripts/docker-services.sh` | Compose services for the specified project |
| `scripts/port-check.sh` | Published ports declared by the specified Compose project |
| `scripts/nginx-domains.sh` | Reads the specified authorized Nginx site file only; it does not enumerate host configuration |

## Reference Files (read when needed)

- **`references/server-spec.md`** — Hardware specs, OS, firewall rules, sudo workaround, SSH legacy entries

## ⚠️ CRITICAL SECURITY WARNING
**The cee-server (64.90.11.148) is a SHARED machine; lackeys-server (64.90.13.82) is the dedicated Agent machine.**

The user has authorized us to operate on `/home/cee/` projects and the related Nginx reverse-proxy and certificate configuration for explicitly named project domains. All unrelated projects, processes, containers, domains, certificates, and host configuration remain out of scope.

**Rules:**
1. Verify the target host before every operation: `/home/cee/` project paths belong to `cee-server`; `/home/lackeys/` Agent paths belong to `lackeys-server`.
2. Restrict Docker operations to services declared by that host's verified Compose file.
3. Restrict Nginx and certificate work to the explicitly named project's matching domain/server block and certificate lineage.
4. Preserve the shared server's Codex, cc-switch, and Orca resources; do not grant the dedicated Agent host access to `/home/orca`.
5. Do not inspect, modify, restart, or delete unrelated resources.
