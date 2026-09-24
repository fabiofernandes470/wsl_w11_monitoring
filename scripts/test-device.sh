#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <ip> <community>"
  echo "Exemplo: $0 192.168.88.1 event-monitor"
  exit 2
fi

IP="$1"
COMMUNITY="$2"

echo "== ICMP: $IP =="
if ping -c 3 -W 2 "$IP"; then
  echo "[OK] ICMP respondeu."
else
  echo "[WARN] Sem resposta ICMP. O equipamento pode bloquear ping."
fi

echo
echo "== SNMP sysName: $IP =="
if snmpget -v2c -c "$COMMUNITY" -t 2 -r 1 "$IP" 1.3.6.1.2.1.1.5.0; then
  echo "[OK] SNMP respondeu."
else
  echo "[ERRO] SNMP não respondeu. Verifique community, origem permitida e UDP/161."
  exit 1
fi

echo
echo "== Interfaces (primeiras 30) =="
snmpwalk -v2c -c "$COMMUNITY" -t 2 -r 1 "$IP" 1.3.6.1.2.1.2.2.1.2 | head -n 30
