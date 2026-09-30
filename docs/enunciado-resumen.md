# Resumen del enunciado (Prueba1.pdf) — Opción B: Azure

Módulo: Defensa Operativa en Ciberseguridad (Magíster en Ciberseguridad, USS).
Entrega: sábado 03-oct-2026, 23:59:59, informe PDF en Blackboard. El PDF original está en `docs/Prueba1.pdf`.

## Requisitos de infraestructura (Opción B)
- VNet `10.0.0.0/16`, subred dedicada `10.0.1.0/24`, NSG.
- NSG: SSH 22, RDP 3389, HTTPS 443 **solo desde la IP pública del estudiante**; TCP 1514 y 1515 solo entre las VMs (interno).
- VM 1 Linux: `Standard_B2ms` o `Standard_D2s_v5` (servidor Wazuh All-in-One).
- VM 2 Windows: `Standard_B2s` o `Standard_D2s_v5` (endpoint monitoreado).

## Fases
1. Conectividad: ICMP/nombres bidireccional entre ambas VMs.
2. Wazuh All-in-One en Linux (Indexer, Server, Dashboard) en `active (running)`; acceso HTTPS al Dashboard.
3. Agente Wazuh (MSI) en Windows apuntando a la IP privada del servidor; estado Active en Dashboard.
4. Pruebas: eventos 4625/4624 (logon fallido/exitoso), FIM en `C:\PII_Data` (`realtime="yes"`, reglas 550/554), PowerShell/certutil (MITRE T1059).

## Entregables del informe
Ficha técnica (IPs, hostname, SO, versión Wazuh, aislamiento) + diagrama; memoria de instalación (comandos, servicios, `ossec.conf`); 4 capturas con fecha y hostname visibles (conectividad, agente Active, eventos 4624/4625, alerta FIM); análisis normativo (ISO 27001 A.8.15/A.8.16, Ley 21.663, plazo 72 h).
