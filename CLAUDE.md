# Laboratorio SOC Wazuh en Azure (USS – Defensa Operativa en Ciberseguridad)

Proyecto autocontenido. Responde siempre en español (el informe es para una universidad chilena).
Enunciado: `docs/Prueba1.pdf` (resumen en `docs/enunciado-resumen.md`). Decisiones: `docs/decisiones.md`.

## Qué es
Opción B del enunciado: VNet + NSG + 2 VMs en Azure, definidas en Bicep. El estado deseado vive en `infra/`; para cambiar algo se edita ahí y se re-aplica.

## Estado
Infraestructura DESPLEGADA (26-sep-2026). Detalle, IPs y próximos pasos: `docs/estado-actual.md`. Región mexicocentral, VMs `Standard_B2as_v2` (B2ms/B2s no disponibles; ver `docs/decisiones.md`).

## Órdenes frecuentes del usuario -> qué hacer
- "despliega la infraestructura": `scripts/deploy.sh whatif`, mostrar resumen + costo/hora, **esperar confirmación explícita**, luego `scripts/deploy.sh apply`.
- "revisa el estado": `scripts/status.sh`.
- "apaga las VMs" / "enciéndelas": `scripts/deallocate.sh` / `scripts/start.sh`.
- "destruye todo": `scripts/destroy.sh` (borra el RG completo; confirmar antes; pide escribir el nombre del RG).
- "deja la VM linux/windows como nueva" / "vuelve al estado inicial sin instalación": `scripts/reset-vm.sh linux|windows` (borra VM + disco de sistema y la recrea desde infra/, mismas IPs/NSG; confirmar antes).
- Si cambió la IP pública del usuario (no puede entrar por SSH/RDP): volver a correr `scripts/deploy.sh apply` (detecta la IP y actualiza el NSG).
- "dale acceso a X" / nueva IP de equipo: agregar la línea en `infra/equipo-acceso.txt` (formato en el propio archivo) y correr `scripts/deploy.sh apply`. Documentar en `docs/equipo-acceso.md`.

## Reglas
- Nunca crear/modificar recursos facturables sin mostrar el plan y recibir confirmación explícita.
- Los scripts registran cada comando y su salida en `logs/log-instalacion-azure.md` (por fase, para el informe). Comandos manuales relevantes deben agregarse allí también.
- Secretos en `infra/.secrets/` (clave SSH y contraseña de Windows; ignorados por git). Usuario admin: `socadmin`.
- Suscripción "Azure for Students" (cuota: 4 vCPU serie B por región, Dsv5 = 0). No hay margen para una tercera VM B2.
- NSG: nunca abrir 22/3389/443 a 0.0.0.0/0; 1514/1515 solo desde 10.0.1.0/24.
- Fecha límite de entrega del informe: 03-oct-2026 23:59.
