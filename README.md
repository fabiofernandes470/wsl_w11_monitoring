# WSL W11 Monitoring

Stack portátil para transformar um notebook de evento em um pequeno NOC usando **Windows 11 + WSL2 Ubuntu + Docker Desktop**.

## O que monitora

- disponibilidade via **ICMP**;
- equipamentos via **SNMP**;
- tráfego RX/TX e utilização de interfaces de **MikroTik**;
- gateways, switches, APs e serviços;
- alertas locais via **ntfy**;
- disponibilidade simples via **Uptime Kuma**;
- histórico, descoberta e métricas detalhadas via **Zabbix**.

## Arquitetura

| Componente | Função |
|---|---|
| Zabbix 7.4 | SNMP, ICMP, descoberta de interfaces, histórico, gráficos e triggers |
| PostgreSQL 16 | Banco do Zabbix |
| Uptime Kuma 2 | Painel operacional simples e testes Ping/HTTP/TCP |
| ntfy | Notificações no notebook |
| Portainer CE | Gestão visual dos containers, logs, volumes e stack |
| Docker Desktop | Engine Docker compartilhado com o Ubuntu via WSL2 |
| Docker Compose | Sobe e mantém a stack |

**Decisão de arquitetura:** o Kuma não tenta substituir o Zabbix. Kuma mostra rapidamente "está vivo ou caiu"; Zabbix responde "quanto está passando no link, qual interface está saturando e o que mudou".

## Pré-requisitos

Este repositório assume que você **já possui**:

- Windows 11;
- WSL2 com Ubuntu;
- Docker Desktop;
- integração do Docker Desktop habilitada para o Ubuntu.

No Ubuntu, confirme:

```bash
docker version
docker compose version
```

Se `docker` não estiver disponível, abra Docker Desktop:

**Settings > Resources > WSL Integration > Ubuntu**

e habilite a distribuição.

> Não instale um segundo Docker Engine dentro do Ubuntu/WSL. O projeto usa o engine do Docker Desktop.

## Instalação

No Ubuntu/WSL:

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/fabiofernandes470/wsl_w11_monitoring.git
cd wsl_w11_monitoring

chmod +x install.sh
./install.sh
```

O instalador apenas:

1. instala utilitários Linux de rede/SNMP;
2. valida Docker Desktop e Docker Compose;
3. cria `.env`;
4. gera senha aleatória do PostgreSQL;
5. baixa as imagens;
6. sobe a stack.

Ele **não instala nem altera o Docker Desktop**.

## Endereços

Depois de subir:

| Serviço | URL |
|---|---|
| Zabbix | http://localhost:8080 |
| Uptime Kuma | http://localhost:3001 |
| ntfy | http://localhost:8085 |
| tópico de alertas | http://localhost:8085/event-monitor |
| Portainer | https://localhost:9443 |

### Primeiro acesso Zabbix

```text
Usuário: Admin
Senha:   zabbix
```

Troque a senha no primeiro acesso.

### Primeiro acesso Uptime Kuma

No primeiro acesso, crie o usuário administrador solicitado pelo Kuma.

### Primeiro acesso Portainer

Abra `https://localhost:9443`. O navegador pode alertar sobre o certificado HTTPS local; confirme a exceção apenas neste notebook. Crie o usuário administrador e selecione o ambiente Docker local.

> O Portainer monta `/var/run/docker.sock`, o que lhe dá alto privilégio sobre o engine Docker. Por isso a porta fica vinculada a `127.0.0.1` por padrão.

## Teste rápido

Estado dos containers:

```bash
docker compose ps
```

Teste do ntfy:

```bash
./scripts/test-notification.sh
```

Teste de um MikroTik:

```bash
./scripts/test-device.sh 192.168.88.1 event-monitor
```

## MikroTik

Exemplo mínimo de SNMPv2c:

```routeros
/snmp set enabled=yes
/snmp community add name=event-monitor address=SEU_IP_OU_REDE read-access=yes write-access=no security=none
```

Restrinja `address` à máquina/rede de gerenciamento. Não exponha uma community SNMPv2c para `0.0.0.0/0`.

Documentação completa:

- [MikroTik + SNMP](docs/mikrotik.md)

## Consumo de link no MikroTik

No Zabbix:

1. **Data collection > Hosts > Create host**;
2. adicione a interface **SNMP** com IP do MikroTik;
3. configure SNMPv2 e a community;
4. vincule **MikroTik by SNMP** ou o template oficial adequado;
5. aguarde a descoberta das interfaces;
6. em **Monitoring > Latest data**, filtre pela WAN;
7. acompanhe RX/TX e utilização;
8. crie um dashboard para as interfaces de internet.

Para eventos com dois links, mantenha gráficos separados para WAN1 e WAN2.

## Uptime Kuma

Sugestão de monitores:

- MikroTik principal — Ping;
- gateway da operadora — Ping;
- switches críticos — Ping;
- controlador/AP — Ping ou HTTP;
- serviço de internet — HTTP/HTTPS;
- sistemas locais relevantes — HTTP/TCP.

Para ntfy dentro da stack:

```text
Servidor: http://ntfy
Tópico:   event-monitor
```

Assim, quando um monitor cair, o alerta pode aparecer no notebook.

## Zabbix -> ntfy

A stack inclui um alert script para que triggers do Zabbix também possam publicar no ntfy.

Veja:

- [Configurar Zabbix -> ntfy](docs/zabbix-ntfy.md)

## Operação durante o evento

Subir/verificar:

```bash
./scripts/event-start.sh
```

Estado:

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

Os dados persistem em volumes Docker.

## Atualização

```bash
git pull
docker compose pull
docker compose up -d
```

## Segurança

As interfaces web vêm vinculadas a:

```text
127.0.0.1
```

Portanto, por padrão, somente o próprio notebook acessa os painéis.

Se outro computador da equipe precisar acessar, altere no `.env`:

```env
BIND_ADDRESS=0.0.0.0
```

e rode:

```bash
docker compose up -d
```

Faça isso somente em uma LAN confiável e depois de trocar credenciais padrão.

O arquivo `.env` não entra no Git.

## Diagnóstico

```bash
docker version
docker compose version
docker compose ps
ping -c 3 IP_DO_MIKROTIK
snmpget -v2c -c COMMUNITY IP_DO_MIKROTIK 1.3.6.1.2.1.1.5.0
```

Problemas comuns:

- [Troubleshooting](docs/troubleshooting.md)

## Estrutura

```text
.
├── compose.yaml
├── install.sh
├── .env.example
├── scripts/
│   ├── event-start.sh
│   ├── test-device.sh
│   └── test-notification.sh
├── zabbix/
│   └── alertscripts/
│       └── ntfy.sh
└── docs/
    ├── mikrotik.md
    ├── zabbix-ntfy.md
    └── troubleshooting.md
```

## Licença

MIT.
