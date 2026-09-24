#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker version >/dev/null 2>&1 || {
  echo "[ERRO] Docker Desktop não está acessível pelo WSL."
  echo "Inicie o Docker Desktop e confira Settings > Resources > WSL Integration."
  exit 1
}

docker compose up -d
docker compose ps

cat <<'EOF'

Painéis:
  Zabbix      http://localhost:8080
  Uptime Kuma http://localhost:3001
  ntfy        http://localhost:8085/event-monitor
  Portainer   https://localhost:9443
EOF
