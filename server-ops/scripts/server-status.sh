#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=${1:-}
COMPOSE_FILE=${2:-}
if [[ -z "$PROJECT_DIR" ]]; then
  echo "usage: $0 /home/cee/<project> [/home/cee/<project>/compose.yml]" >&2
  exit 2
fi

PROJECT_DIR=$(realpath -e -- "$PROJECT_DIR") || {
  echo "project directory does not exist: $1" >&2
  exit 2
}
case "$PROJECT_DIR" in
  /home/cee/*) ;;
  *) echo "project directory must resolve under /home/cee/: $PROJECT_DIR" >&2; exit 2 ;;
esac

COMPOSE_FILE=${COMPOSE_FILE:-$PROJECT_DIR/compose.yml}
COMPOSE_FILE=$(realpath -e -- "$COMPOSE_FILE") || {
  echo "compose file does not exist: ${2:-$PROJECT_DIR/compose.yml}" >&2
  exit 2
}
case "$COMPOSE_FILE" in
  "$PROJECT_DIR"/*) ;;
  *) echo "compose file must resolve inside the project directory: $COMPOSE_FILE" >&2; exit 2 ;;
esac

echo "=== PROJECT DISK ==="
df -h "$PROJECT_DIR" | tail -1 | awk '{print "total=" $2, "used=" $3, "avail=" $4, "use%=" $5}'

echo ""
echo "=== PROJECT SERVICES ==="
sudo docker compose -f "$COMPOSE_FILE" ps
