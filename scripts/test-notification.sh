#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

NTFY_PORT="${NTFY_PORT:-8085}"
NTFY_TOPIC="${NTFY_TOPIC:-event-monitor}"
URL="http://localhost:${NTFY_PORT}/${NTFY_TOPIC}"

curl --fail --silent --show-error   -H "Title: Teste do monitoramento"   -H "Priority: 4"   -H "Tags: satellite,event"   -d "WSL W11 Monitoring está enviando notificações."   "$URL"

echo
echo "[OK] Mensagem publicada em $URL"
