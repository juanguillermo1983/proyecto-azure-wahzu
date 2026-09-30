# Inicio rápido: conectar Azure CLI y preparar el entorno

Esta guía es para partir **desde cero** en una cuenta/suscripción de Azure distinta (por ejemplo, otra cuenta Azure for Students), antes de tocar `scripts/deploy.sh`. Cubre desde instalar la herramienta de línea de comandos de Azure hasta dejar todo listo para que los scripts del repositorio orquesten el despliegue.

## 1. Qué es Azure CLI y por qué se necesita

Todo este proyecto (los scripts en `scripts/`, las plantillas en `infra/`) asume que el comando `az` está instalado y autenticado en la máquina donde se ejecuta. `az` es la CLI oficial de Azure: permite crear/leer/borrar recursos (VMs, redes, etc.) desde la terminal, que es exactamente lo que hacen `scripts/deploy.sh`, `scripts/status.sh`, etc. por debajo.

No hace falta usar el Portal de Azure para nada de este laboratorio — todo se orquesta desde la terminal.

## 2. Instalar Azure CLI

**macOS (Homebrew):**
```bash
brew install azure-cli
```

**Linux (Debian/Ubuntu):**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Windows:** descargar el instalador MSI desde [learn.microsoft.com/cli/azure/install-azure-cli-windows](https://learn.microsoft.com/cli/azure/install-azure-cli-windows).

Verificar instalación:
```bash
az version
```

> El script `scripts/setup-entorno.sh` (ver sección 5) hace esta verificación automáticamente y ofrece instalarlo por ti si usas Homebrew.

## 3. Iniciar sesión (`az login`)

```bash
az login
```

Esto abre el navegador para autenticarte con tu cuenta Microsoft/Azure. Si estás en un entorno sin navegador (ej. una VM remota o WSL sin interfaz gráfica), usa:

```bash
az login --use-device-code
```

y sigue el código que te muestra en pantalla (vas a `https://microsoft.com/devicelogin` desde cualquier navegador, en cualquier equipo).

## 4. Elegir y confirmar la suscripción correcta

Una cuenta puede tener varias suscripciones (ej. "Azure for Students", "Pay-As-You-Go", una del trabajo, etc.). Es crítico apuntar a la correcta, porque ahí es donde se van a crear (y cobrar) los recursos.

```bash
# Listar todas las suscripciones visibles para tu cuenta
az account list --query '[].{Nombre:name, Id:id, Estado:state}' -o table

# Ver cuál está activa/seleccionada por defecto ahora mismo
az account show --query '{Nombre:name, Id:id}' -o table

# Fijar la que vas a usar para este laboratorio
az account set --subscription "Azure for Students"
```

Luego edita `infra/config.env` y asegúrate de que `AZ_SUBSCRIPTION` tenga **exactamente** el mismo nombre (o el Id) que aparece en `az account list`:

```bash
AZ_SUBSCRIPTION="Azure for Students"
```

Todos los scripts del repositorio leen este valor y lo pasan a `az account set` antes de cada operación, así que si no coincide, fallarán con un error claro en vez de operar sobre la suscripción equivocada.

### Cuotas: revisa antes de desplegar

Las suscripciones educativas/gratuitas suelen tener cuotas bajas de cómputo (ej. 4 vCPU en la serie B por región). Revisa la tuya antes de elegir tamaños de VM:

```bash
az vm list-usage --location mexicocentral -o table
```

Ver `docs/decisiones.md` para el criterio usado en este proyecto (región y tamaño de VM) frente a esas restricciones — puede que en tu suscripción convenga otra región o tamaño, y en ese caso se ajusta en `infra/main.bicepparam`.

## 5. Registrar los resource providers necesarios

Una suscripción nueva a veces no tiene habilitados los "resource providers" de cómputo y redes (esto no cuesta nada, es solo una activación a nivel de suscripción):

```bash
az provider show -n Microsoft.Compute --query registrationState -o tsv
az provider show -n Microsoft.Network --query registrationState -o tsv

# Si alguno no dice "Registered":
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
```

El registro puede tardar unos minutos. Si el `deploy.sh whatif` falla con un error tipo `MissingSubscriptionRegistration`, es esto.

## 6. Dejar todo listo con un solo script

En vez de hacer los pasos 3–5 y la generación de secretos a mano, este repositorio incluye un script que automatiza todo lo anterior (excepto instalar `az`, que requiere confirmación tuya la primera vez):

```bash
scripts/setup-entorno.sh
```

Este script:
- Verifica que `az` esté instalado (y ofrece instalarlo vía Homebrew si falta).
- Verifica que haya una sesión activa (`az login` si no la hay).
- Confirma que la suscripción de `infra/config.env` exista y la deja seleccionada.
- Revisa y, con tu confirmación explícita, registra los resource providers `Microsoft.Compute` y `Microsoft.Network`.
- Genera la clave SSH y la contraseña de Windows en `infra/.secrets/` (si no existen ya).
- Crea `infra/equipo-acceso.txt` desde la plantilla si no existe.

**No crea ningún recurso facturable** (ninguna VM, IP pública, etc.) — eso solo ocurre al correr `scripts/deploy.sh apply`, que siempre muestra el plan (`whatif`) primero y pide confirmación aparte.

## 7. Siguiente paso

Con el entorno preparado:

```bash
# Revisar/ajustar región y tamaño de VM según tu cuota
$EDITOR infra/main.bicepparam

# Ver el plan sin crear nada
scripts/deploy.sh whatif

# Aplicar (crea los recursos)
scripts/deploy.sh apply
```

Luego sigue `docs/guia-instalacion.md` para instalar Wazuh y ejecutar las pruebas de verificación.
