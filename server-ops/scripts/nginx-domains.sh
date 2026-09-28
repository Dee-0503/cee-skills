#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=${1:-}
if [[ -z "$CONFIG_FILE" ]]; then
  echo "usage: $0 /etc/nginx/sites-enabled/<project>.conf" >&2
  exit 2
fi

CONFIG_FILE=$(realpath -e -- "$CONFIG_FILE") || {
  echo "Nginx configuration file does not exist: ${1}" >&2
  exit 2
}
case "$CONFIG_FILE" in
  /etc/nginx/sites-enabled/*|/etc/nginx/conf.d/*) ;;
  *) echo "configuration file must be an authorized Nginx site file: $CONFIG_FILE" >&2; exit 2 ;;
esac

sudo sed -n '1,240p' "$CONFIG_FILE"
printf '\nRun `sudo nginx -t` before any reload.\n'
