#!/usr/bin/env sh
set -eu

TOPIC="${1:-event-monitor}"
TITLE="${2:-Zabbix}"
MESSAGE="${3:-Evento do Zabbix}"
PRIORITY="${4:-default}"

curl -fsS   -H "Title: $TITLE"   -H "Priority: $PRIORITY"   --data-binary "$MESSAGE"   "http://ntfy/$TOPIC"
