# Zabbix -> ntfy

A stack monta o script:

```text
/usr/lib/zabbix/alertscripts/ntfy.sh
```

dentro do container do Zabbix Server.

## Criar Media Type

No Zabbix:

1. Abra **Alerts > Media types**.
2. Crie um Media Type do tipo **Script**.
3. Script name: `ntfy.sh`.
4. Adicione os parâmetros nesta ordem:

```text
{ALERT.SENDTO}
{ALERT.SUBJECT}
{ALERT.MESSAGE}
high
```

Use `event-monitor` como destino (**Send to**) do usuário que receberá os alertas.

O script publica internamente em:

```text
http://ntfy/event-monitor
```

O navegador do notebook acessa:

```text
http://localhost:8085/event-monitor
```

## Teste

Primeiro valide o ntfy fora do Zabbix:

```bash
./scripts/test-notification.sh
```

Depois use a função de teste do Media Type no Zabbix.

## Uptime Kuma -> ntfy

No Uptime Kuma, adicione uma notificação **ntfy**.

Servidor dentro do Docker:

```text
http://ntfy
```

Tópico:

```text
event-monitor
```

Assim o Kuma cuida dos alertas simples de disponibilidade, enquanto o Zabbix pode alertar sobre métricas de SNMP e consumo de link.
