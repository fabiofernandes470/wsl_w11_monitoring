# MikroTik + SNMP

## Papel do MikroTik nesta stack

O Zabbix coleta por SNMP dados como disponibilidade, interfaces, tráfego RX/TX, erros, descartes e outras métricas expostas pelo RouterOS.

Para acompanhar o **consumo do link**, identifique a interface WAN correta após a descoberta automática e acompanhe os itens de entrada/saída dessa interface.

## SNMPv2c para evento

SNMPv2c é simples, mas a community não é criptografada. Use em rede controlada e restrinja a origem autorizada.

No RouterOS:

```routeros
/snmp set enabled=yes
/snmp community add name=event-monitor address=IP_OU_REDE_DO_MONITORAMENTO read-access=yes write-access=no security=none
```

Exemplo:

```routeros
/snmp community add name=event-monitor address=192.168.50.0/24 read-access=yes write-access=no security=none
```

Evite liberar community para `0.0.0.0/0`.

## Teste a partir do WSL

```bash
./scripts/test-device.sh 192.168.50.1 event-monitor
```

Teste manual:

```bash
ping -c 3 192.168.50.1
snmpget -v2c -c event-monitor 192.168.50.1 1.3.6.1.2.1.1.5.0
```

## Adicionar ao Zabbix

1. Abra **Data collection > Hosts**.
2. Crie o host, por exemplo `MK-EVENTO-GW01`.
3. Adicione interface do tipo **SNMP** no IP de gerenciamento do MikroTik.
4. Use porta `161` e SNMPv2.
5. Informe a community.
6. Vincule o template oficial **MikroTik by SNMP** ou o template específico do modelo, quando aplicável.
7. Aguarde a descoberta das interfaces.

## Encontrar a WAN e o consumo

1. Abra **Monitoring > Latest data**.
2. Selecione o MikroTik.
3. Filtre pelo nome da interface WAN.
4. Localize os itens de bits/bytes recebidos e enviados.
5. Monte um dashboard com RX, TX e utilização.
6. Se houver dois links, acompanhe cada WAN separadamente.

## Alertas úteis em evento

Evite alertar por qualquer oscilação. Comece com poucos sinais:

- host indisponível;
- WAN indisponível;
- utilização sustentada acima de um limite operacional;
- erros/descartes crescendo;
- perda de pacotes ou latência anormal.

O objetivo é chamar atenção para falhas acionáveis, não produzir ruído.
