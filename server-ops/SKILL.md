---
name: server-ops
description: "Operate authorized projects on the shared server (64.90.13.184): use SSH alias cee-server for business projects as cee, or lackeys-server for the dedicated Agent runtime as lackeys. Covers deployment, restart, health and disk checks, and project-related Nginx and certificates."
---

# Server Operations

## Select the account and project

Both SSH aliases connect to the **same machine**, currently `64.90.13.184`:

| SSH alias | Remote user | Scope |
|---|---|---|
| `cee-server` | `cee` | Business projects under `/home/cee/` |
| `lackeys-server` | `lackeys` | Dedicated Agent runtime under `/home/lackeys/` |

Use `ssh cee-server` for business operations and `ssh lackeys-server` for Agent operations. Keep their credentials, paths, backups, and runtime ownership separate. Sudo access does not authorize work outside the requested project. Do not add `lackeys` to the Docker group.

Before the first remote operation in a task, check the selected alias's effective configuration locally (`ssh -G cee-server` or `ssh -G lackeys-server`; inspect `hostname`, `user`, and `port`). Then confirm remote identity with `id -un` and `hostname`. Resolve mismatches before mutations; do not rewrite SSH configuration as part of a project deployment.

Verify the canonical project directory, deployment configuration, and target service. For Compose, identify the actual Compose file(s), project name, profiles, and environment-file options used by the deployment, and retain those options throughout. Do not guess container names or enumerate host-wide containers. For non-Compose projects, identify the project-owned service or process manager before operating it.

## Authorization and boundaries

The requested deploy, restart, inspect, or update authorizes necessary operations for the named project in the selected account's scope. This includes project-owned files, environment, application services, and required related Nginx/certificate work for an explicitly named domain. Proceed within that scope without repeated approval.

- Restrict Docker commands to the verified project's Compose configuration and declared services. Use authorized `sudo` for business Docker operations.
- Restrict Nginx edits to the project's matching server block and certificate work to the named domain's certificate lineage. Preserve unrelated configuration.
- If a required project, service, or domain cannot be identified from the request and project configuration, ask for that identifier before dependent changes.
- Do not inspect, modify, restart, or delete unrelated users, projects, containers, domains, certificates, or host configuration.
- Follow the user's destructive-action authorization boundary. Preserve a recoverable copy before replacing configuration or data.

Verify the active account's sudo policy before non-interactive commands. Use an interactive prompt or protected stdin when needed; never store passwords in this skill, logs, or source control. When streaming a script with `bash -s`, stdin contains the script and must not also carry a sudo password.

## Deploy and verify

1. Inspect the project's existing deployment procedure and current state. Record enough of the current version and configuration to recover from a failed change. Read only relevant environment keys; avoid exposing secrets.
2. Apply the requested change through the existing deployment mechanism. Validate configuration before restarting the affected service.
3. Check the target service's health and project-local endpoint. Inspect bounded, relevant service logs if it fails. Do not repeat a failing restart without diagnosing the cause.
4. If domain routing is part of the request, verify that domain separately after the project-local endpoint works.

Report deployment and domain cutover separately: a healthy local application proves deployment, while cutover requires the named domain's routing, TLS, and expected application response to be verified. Report failed or unverified parts explicitly.

## Nginx, certificates, and firewall

Identify the named domain's matching Nginx configuration and upstream before editing. Read only the relevant file; avoid `nginx -T` for routine inspection because it expands unrelated configuration. Common `sites-enabled` entries are symlinks into `sites-available`; verify the resolved target belongs to the intended project.

After changes, run `sudo nginx -t` and reload only on success. Verify the local upstream and public domain independently.

Inspect the existing certificate lineage and renewal configuration with `sudo`. Reuse a valid certificate for the named domain. Renew or repair that lineage using the existing Certbot installation; a new domain without a certificate requires issuance, because `certbot renew` cannot create one. Preserve the existing root-owned `certbot.timer` and unrelated certificates. Read [host details](references/lackeys-server.md) when certificate or bootstrap context is needed; recorded versions and health results are historical and require live verification when relevant.

Inspect `sudo ufw status numbered` when relevant. A general deployment request does not authorize host firewall changes; obtain authorization for the exact port, protocol, direction, and scope if needed. Bind private application/database ports to loopback or an appropriate private network. Docker-published ports can bypass UFW filtering, so verify the actual bind address rather than relying on UFW alone.

## Project-scoped helper scripts

These read-only helpers target **business projects as `cee`** and a single Compose file. Use the project's existing commands directly for multi-file Compose deployments, extra deployment options, or Agent operations.

Set `SERVER_OPS_SKILL_DIR` to the absolute directory containing the loaded `SKILL.md`, rather than the working directory or a fixed installation path. Replace example paths with verified paths.

| Script | Purpose |
|---|---|
| `scripts/server-status.sh` | Filesystem capacity containing the project and Compose service status; does not measure project disk usage |
| `scripts/docker-services.sh` | Compose service status for the specified project |
| `scripts/port-check.sh` | Published ports of running services in the specified Compose project |
| `scripts/nginx-domains.sh` | First 240 lines of one authorized Nginx site file; does not enumerate mappings or validate configuration |

```bash
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/server-status.sh"
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/docker-services.sh"
ssh cee-server 'bash -s -- /home/cee/<project> /home/cee/<project>/compose.yml' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/port-check.sh"
ssh cee-server 'bash -s -- /etc/nginx/sites-enabled/<project>.conf' < "${SERVER_OPS_SKILL_DIR:?Set to the directory containing the loaded SKILL.md}/scripts/nginx-domains.sh"
```

## Cloudflare operations

For requested Cloudflare DNS, SSL, WAF, Workers, Pages, or Tunnel work, prefer the available Cloudflare plugin's skills and tools. Check current capability availability and account/zone access; installation alone proves neither.

If unavailable, report the exact pending operation. Do not enable, install, reconfigure, search for credentials, or bypass the plugin through another interface without the user's authorization for that alternative. Ask for an enabled capability or authorized alternative only when required to proceed. An access failure does not prove the plugin is disabled.

Continue authorized server work that does not depend on the pending operation. Report server deployment and Cloudflare/domain cutover separately, and claim completion only for verified operations. Server-only tasks do not require the plugin.

## References and existing automation

- [Business server specification](references/server-spec.md): SSH aliases, sudo, firewall, and path ownership.
- [Host bootstrap details](references/lackeys-server.md): dated host inventory and Agent runtime conventions. New Agent production paths use `/home/lackeys/apps/{cee-lackeys,cumora,cumora-byoa,codex,cc-switch}` and `/home/lackeys/data/{cumora,codex,cc-switch,cee-wiki}` without `pilot`.
- Existing GoClaw watchdog: `/home/cee/scripts/goclaw-watchdog.sh`, log `/home/cee/logs/goclaw-watchdog.log`; recorded schedule every 3 minutes, restarting after 3 consecutive health failures, with daily log rotation and 7-day retention. Inspect or change it only for a GoClaw task, and verify its current configuration before relying on these recorded settings.
