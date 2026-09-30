# Laboratorio SOC Wazuh en Azure

Infraestructura como código (Bicep) para desplegar un laboratorio de Defensa Operativa en Ciberseguridad en Azure: una VNet aislada con NSG restrictivo, una VM Linux con **Wazuh All-in-One** (Indexer + Server + Dashboard) y una VM Windows como endpoint monitoreado.

Pensado para desplegarse desde una cuenta **Azure for Students** (u otra suscripción con cuotas acotadas) usando exclusivamente `Standard_B2as_v2` — ver `docs/decisiones.md` para la justificación de región y tamaño de VM.

## Qué incluye este repositorio

- `infra/` — plantillas Bicep (VNet, NSG, VMs, IPs públicas) y parámetros.
- `scripts/` — despliegue, encendido/apagado, reseteo de una VM, destrucción total, gestión de accesos.
- `docs/decisiones.md` — comparación de regiones/tamaños de VM y por qué se eligió cada uno.
- `docs/inicio-rapido.md` — cómo instalar y conectar Azure CLI (`az login`, suscripción, resource providers) desde cero en una cuenta nueva, y `scripts/setup-entorno.sh` para automatizarlo.
- `docs/guia-instalacion.md` — guía paso a paso para instalar Wazuh, enrolar el agente Windows y ejecutar las pruebas de verificación (autenticación, FIM, MITRE T1059), incluyendo problemas reales encontrados y su solución.
- `docs/enunciado-resumen.md` — resumen de los requisitos técnicos que este proyecto satisface.

**No incluido** (deliberadamente, por ser específico de un despliegue o contener datos personales): capturas de evidencia, logs de ejecución, IPs/contraseñas generadas, y el enunciado original del curso.

## Prerrequisitos

- macOS/Linux con [Homebrew](https://brew.sh) (o gestor de paquetes equivalente).
- Una suscripción de Azure activa (ej. "Azure for Students").
- Azure CLI instalado y conectado (`az login` + suscripción correcta) — ver `docs/inicio-rapido.md` para la guía completa desde cero, o usar `scripts/setup-entorno.sh` (paso 1 abajo) para automatizarlo.

## Despliegue rápido

```bash
git clone git@github.com:juanguillermo1983/proyecto-azure-wahzu.git
cd proyecto-azure-wahzu

# 0. Instalar/conectar Azure CLI, registrar providers y generar secretos (ver docs/inicio-rapido.md)
scripts/setup-entorno.sh

# 1. Revisar/ajustar región y tamaños de VM si tu suscripción tiene otras cuotas disponibles
#    (ver docs/decisiones.md para el método de comparación usado)
$EDITOR infra/main.bicepparam
$EDITOR infra/config.env

# 2. (Opcional) agregar compañeros de equipo con acceso SSH/RDP
#    (scripts/setup-entorno.sh ya creó infra/equipo-acceso.txt desde la plantilla)
$EDITOR infra/equipo-acceso.txt

# 3. Ver el plan sin crear nada (por defecto)
scripts/deploy.sh whatif

# 4. Aplicar
scripts/deploy.sh apply
```

`scripts/setup-entorno.sh` genera un par de llaves SSH y una contraseña de Windows en `infra/.secrets/` (ignorado por git — nunca se sube); `scripts/deploy.sh` los reutiliza. El NSG solo permite SSH/RDP/HTTPS desde tu IP pública (detectada automáticamente) y desde las IPs que agregues en `infra/equipo-acceso.txt`.

Luego sigue `docs/guia-instalacion.md` para instalar Wazuh y ejecutar las pruebas de verificación.

## Operación diaria

```bash
scripts/status.sh        # ver estado/IPs de las VMs
scripts/deallocate.sh    # apagar (deja de cobrar cómputo)
scripts/start.sh         # encender
scripts/reset-vm.sh linux|windows   # volver una VM a su estado inicial (sin instalación)
scripts/destroy.sh       # borrar todo el grupo de recursos (irreversible)
```

## Seguridad

- El NSG nunca abre 22/3389/443 a `0.0.0.0/0`; los puertos del agente Wazuh (1514/1515) solo son accesibles dentro de la subred.
- Los secretos (clave SSH, contraseña de Windows, credenciales del Dashboard) se generan localmente y quedan en `infra/.secrets/`, excluido de git.
- Antes de compartir acceso con un compañero, comparte los archivos de `infra/.secrets/` por un canal seguro — nunca por email ni chat abierto.
