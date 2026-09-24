# Troubleshooting

## Docker não aparece dentro do Ubuntu

Teste:

```bash
docker version
docker compose version
```

Se falhar:

1. abra Docker Desktop no Windows;
2. confirme o backend WSL2;
3. abra **Settings > Resources > WSL Integration**;
4. habilite a distribuição Ubuntu;
5. reabra o terminal Ubuntu.

Não instale um segundo Docker Engine dentro do WSL apenas para contornar esse problema.

## WSL não alcança o MikroTik

```bash
ip route
ping -c 3 IP_DO_MIKROTIK
```

Depois:

```bash
snmpget -v2c -c COMMUNITY IP_DO_MIKROTIK 1.3.6.1.2.1.1.5.0
```

Se ICMP funciona e SNMP não:

- confirme SNMP habilitado no RouterOS;
- confirme community;
- confira o endereço/rede permitido na community;
- confira firewall para UDP/161.

## Container não alcança o equipamento

Teste a partir do Zabbix:

```bash
docker exec -it event-monitor-zabbix-server ping -c 3 IP_DO_EQUIPAMENTO
```

Para SNMP, verifique os logs do Zabbix e os itens do host. O container usa a rede do Docker Desktop e deve conseguir iniciar conexões para a LAN se o host Windows/WSL tiver rota.

## Porta ocupada

Veja quem usa a porta no Windows ou mude no `.env`:

```env
ZABBIX_WEB_PORT=8081
UPTIME_KUMA_PORT=3002
NTFY_PORT=8086
```

Depois:

```bash
docker compose up -d
```

## Zabbix ainda não abriu

Na primeira inicialização o banco precisa ser preparado:

```bash
docker compose ps
docker compose logs -f --tail=100 zabbix-server zabbix-web
```

## Reset completo

ATENÇÃO: apaga banco e configurações.

```bash
docker compose down -v
docker compose up -d
```
