# Dedicated Agent server

Bootstrap checked 2026-09-23. SSH alias `lackeys-server`, IP `64.90.13.82`, port 22, user `lackeys`, hostname `ser978034649211`. Ubuntu 24.04 amd64; approximately 15 GiB RAM and 117 GiB root filesystem. Purchased configuration is 16 vCPU / 16 GB / 120 GB SSD / 25 Mbps peak; peak bandwidth is not a throughput guarantee.

Only the authorized local SSH key is installed for lackeys. Password and keyboard-interactive SSH are disabled, `AuthenticationMethods publickey`, `AllowUsers lackeys`, `PermitRootLogin no`. `lackeys` has passwordless full sudo through `/etc/sudoers.d/lackeys`; it belongs to sudo but not docker. Full sudo is administrative authority, not a hard isolation boundary from this host's databases.

Docker 29.8.1 and Compose 5.5.1 installed. Nginx 1.24.0, Certbot 2.9.0, and `python3-certbot-nginx` are installed; `nginx.service` and `certbot.timer` are enabled, `nginx -t` passes, and `certbot renew --dry-run` completes with no certificates currently due. Docker local logs rotate at 10 MB × 3. UFW enabled with TCP 22, 80, and 443 allowed; application/database ports must remain private. Port 80 is retained for HTTP-01 ACME challenges. Timezone Asia/Shanghai with NTP enabled; application/event timezones require separate verification, because host timezone alone does not determine Calendar correctness.

Use production names without pilot under `/home/lackeys/apps` and `/home/lackeys/data`. Application runtimes, Node version, databases, backup destination, and migration remain deployment tasks; bootstrap does not prove Agent readiness. VM work is deferred. Preserve cee-server's Codex, cc-switch and Orca; do not migrate Orca data, create a gateway, or grant access to /home/orca.
