# WSL W11 Monitoring

Stack portátil de monitoramento para notebook de evento usando **Windows 11 + WSL2 Ubuntu + Docker**.

O objetivo é subir rapidamente um pequeno NOC local para acompanhar:

- disponibilidade por **ICMP**;
- equipamentos por **SNMP**;
- tráfego/consumo das interfaces de **MikroTik**;
- estado de gateways, switches, APs e serviços;
- alertas via **ntfy**;
- painel simples de disponibilidade com **Uptime Kuma**;
- histórico e métricas detalhadas com **Zabbix**.

## Arquitetura

| Componente | Papel |
|---|---|
| Zabbix 7.4 | SNMP, ICMP, descoberta de interfaces, histórico e gráficos |
| PostgreSQL 16 | Banco do Zabbix |
| Uptime Kuma 2 | Painel simples de disponibilidade e testes ICMP/HTTP/TCP |
| ntfy | Barramento local de notificações |
| Docker Compose | Execução da stack dentro do Ubuntu/WSL2 |

A divisão é intencional: o Uptime Kuma fica simples para o operador do evento, enquanto o Zabbix concentra SNMP, métricas e análise de tráfego.

## Requisitos

- Windows 11;
- WSL2 com Ubuntu;
- acesso de rede do WSL aos equipamentos monitorados;
- internet na primeira instalação para baixar pacotes e imagens Docker.

Se o Ubuntu ainda não estiver instalado, abra **PowerShell como Administrador**:

```powershell
wsl --install -d Ubuntu
wsl --set-default-version 2
```

Depois abra o Ubuntu.

## Instalação rápida

Dentro do Ubuntu/WSL:

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/fabiofernandes470/wsl_w11_monitoring.git
cd wsl_w11_monitoring

chmod +x install.sh scripts/*.sh
./install.sh
```

O instalador:

1. instala dependências;
2. instala Docker Engine e Docker Compose Plugin se necessário;
3. cria o arquivo `.env`;
4. gera uma senha aleatória para o PostgreSQL;
5. inicia a stack;
6. mostra os endereços dos serviços.

## Interfaces locais

Depois de subir:

- **Zabbix:** http://localhost:8080
- **Uptime Kuma:** http://localhost:3001
- **ntfy:** http://localhost:8085
- **tópico padrão ntfy:** http://localhost:8085/event-monitor

### Primeiro acesso Zabbix

Usuário padrão:

```text
Admin
```

Senha padrão:

```text
zabbix
```

Troque essa senha no primeiro acesso.

O primeiro bootstrap do banco pode levar alguns minutos. Confira com:

```bash
docker compose ps
docker compose logs -f zabbix-server
```

## MikroTik — configuração mínima

Para um evento pequeno, SNMPv2c é simples e suficiente **desde que a community seja restrita ao IP/rede do monitoramento**. Para redes menos controladas, prefira SNMPv3.

No RouterOS:

```routeros
/snmp set enabled=yes
/snmp community add name=event-monitor address=SEU_IP_OU_REDE read-access=yes write-access=no security=none
```

Não use `0.0.0.0/0` em produção/evento.

Teste do WSL:

```bash
./scripts/test-device.sh 192.168.88.1 event-monitor
```

Mais detalhes em [docs/mikrotik.md](docs/mikrotik.md).

## Adicionando o MikroTik no Zabbix

1. Acesse **Data collection > Hosts**.
2. Crie um host.
3. Adicione uma interface **SNMP** apontando para o IP do MikroTik.
4. Use SNMPv2 e informe a community criada.
5. Vincule o template oficial **MikroTik by SNMP** ou o template específico do modelo quando disponível.
6. Aguarde a descoberta automática das interfaces.
7. Abra **Monitoring > Hosts > Latest data** para verificar RX/TX e utilização.

Os templates oficiais do Zabbix 7.4 incluem descoberta de interfaces e métricas via IF-MIB/MIKROTIK-MIB.

## Uptime Kuma

Use o Kuma para o painel operacional simples:

- MikroTik principal: Ping;
- gateway da operadora: Ping;
- switches críticos: Ping;
- AP/controlador: Ping ou HTTP;
- internet: HTTP/HTTPS para um endpoint externo;
- serviços locais: HTTP/TCP.

Configure notificações do Kuma apontando para o ntfy local:

```text
http://ntfy:80
```

Tópico sugerido:

```text
event-monitor
```

Dentro da rede Docker, o hostname do serviço é `ntfy`. No navegador do Windows, use `localhost:8085`.

## Testar notificação

```bash
./scripts/test-notification.sh
```

Ou:

```bash
curl -d "Teste do monitoramento do evento" http://localhost:8085/event-monitor
```

Abra o tópico no navegador e permita notificações.

## Operação no evento

Antes de iniciar:

```bash
./scripts/event-start.sh
```

Ver estado:

```bash
docker compose ps
```

Logs:

```bash
docker compose logs -f --tail=100
```

Parar:

```bash
docker compose down
```

Atualizar imagens:

```bash
docker compose pull
docker compose up -d
```

Os volumes persistentes preservam banco, dashboards e configurações.

## Segurança

Por padrão, as interfaces web ficam vinculadas a `127.0.0.1`, portanto acessíveis somente no próprio notebook.

Para disponibilizar os painéis na LAN, altere no `.env`:

```env
BIND_ADDRESS=0.0.0.0
```

e execute:

```bash
docker compose up -d
```

Só faça isso em uma rede confiável e troque as credenciais padrão antes.

## WSL e acesso à LAN

O WSL2 normalmente consegue iniciar conexões para equipamentos da LAN. Teste antes do evento:

```bash
ping -c 3 IP_DO_MIKROTIK
snmpget -v2c -c COMMUNITY IP_DO_MIKROTIK 1.3.6.1.2.1.1.5.0
```

Se o Windows/WSL não alcançar os dispositivos, consulte [docs/troubleshooting.md](docs/troubleshooting.md).

## Referências

- Zabbix 7.4: documentação oficial de instalação em containers e templates de rede.
- MikroTik RouterOS: documentação oficial SNMP.
- Uptime Kuma: imagem Docker série 2.
- ntfy: documentação oficial Docker/self-hosting.
