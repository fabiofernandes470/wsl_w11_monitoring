#!/usr/bin/env sh
set -eu

TOPIC="${1:-event-monitor}"
TITLE="${2:-Zabbix}"
MESSAGE="${3:-Evento do Zabbix}"
PRIORITY="${4:-default}"

wget -qO-   --header="Title: $TITLE"   --header="Priority: $PRIORITY"   --post-data="$MESSAGE"   "http://ntfy/$TOPIC"
