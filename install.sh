#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

[[ "${EUID}" -ne 0 ]] || die "Execute como usuário normal; o script usa sudo apenas para pacotes Linux."

if [[ ! -r /etc/os-release ]]; then
  die "Não foi possível identificar a distribuição."
fi

# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "Instalador projetado para Ubuntu no WSL. Detectado: ${PRETTY_NAME:-desconhecido}"

if grep -qi microsoft /proc/version 2>/dev/null; then
  ok "WSL detectado."
else
  warn "WSL não foi detectado. O alvo deste projeto é Ubuntu no WSL2."
fi

info "Instalando utilitários de rede/SNMP..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y   ca-certificates curl git jq openssl snmp fping

command -v docker >/dev/null 2>&1 || die "Comando docker não encontrado no Ubuntu. No Docker Desktop, habilite Settings > Resources > WSL Integration para esta distribuição."

docker version >/dev/null 2>&1 || die "Docker Desktop não está acessível pelo WSL. Inicie o Docker Desktop e habilite a integração WSL para o Ubuntu."

docker compose version >/dev/null 2>&1 || die "Docker Compose v2 não está disponível via Docker Desktop."

ok "Docker Desktop acessível pelo WSL."
docker version --format 'Docker Server: {{.Server.Version}}'
docker compose version

if [[ ! -f .env ]]; then
  cp .env.example .env
  DB_PASSWORD="$(openssl rand -hex 24)"
  sed -i "s/CHANGE_ME_GENERATED_BY_INSTALLER/$DB_PASSWORD/" .env
  chmod 600 .env
  ok ".env criado com senha PostgreSQL aleatória."
else
  ok ".env existente preservado."
fi

chmod +x install.sh scripts/*.sh zabbix/alertscripts/*.sh 2>/dev/null || true

info "Validando Docker Compose..."
docker compose config >/dev/null

info "Baixando imagens..."
docker compose pull

info "Subindo stack..."
docker compose up -d

printf '\n'
docker compose ps
printf '\n'

ok "Stack iniciada."
cat <<'EOF'

Acessos no notebook:
  Zabbix      http://localhost:8080
  Uptime Kuma http://localhost:3001
  ntfy        http://localhost:8085
  tópico ntfy http://localhost:8085/event-monitor

Zabbix inicial:
  usuário: Admin
  senha:   zabbix

Troque a senha padrão do Zabbix no primeiro acesso.

Teste um MikroTik:
  ./scripts/test-device.sh IP COMMUNITY

Teste o ntfy:
  ./scripts/test-notification.sh
EOF
