#!/usr/bin/env bash
# Uso: scripts/setup-entorno.sh
#
# Prepara una cuenta/equipo nuevo para poder ejecutar scripts/deploy.sh:
#   1. Verifica (o instala, con confirmación) Azure CLI.
#   2. Verifica sesión activa (az login) y suscripción.
#   3. Registra los resource providers necesarios (Microsoft.Compute, Microsoft.Network).
#   4. Genera la clave SSH y la contraseña de Windows en infra/.secrets/.
#   5. Crea infra/equipo-acceso.txt desde la plantilla si no existe.
#
# No crea ni modifica ningún recurso facturable (VMs, IPs, etc.) — eso lo hace
# scripts/deploy.sh, que siempre debe ejecutarse aparte y con confirmación explícita.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

echo "== Preparación del entorno para el laboratorio SOC Wazuh =="
echo

# --- 1. Azure CLI -----------------------------------------------------------
if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) no está instalado."
  if command -v brew >/dev/null 2>&1; then
    read -r -p "¿Instalar con 'brew install azure-cli' ahora? [s/N] " resp
    if [[ "$resp" =~ ^[sSyY]$ ]]; then
      run "brew install azure-cli" || { echo "Falló la instalación. Instálalo manualmente: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
    else
      echo "Instálalo manualmente y vuelve a correr este script: https://learn.microsoft.com/cli/azure/install-azure-cli"
      exit 1
    fi
  else
    echo "Homebrew no está disponible. Instala Azure CLI manualmente: https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
  fi
else
  echo "✔ Azure CLI ya está instalado ($(az version --query '\"azure-cli\"' -o tsv 2>/dev/null))."
fi
echo

# --- 2. Sesión y suscripción -------------------------------------------------
if ! az account show >/dev/null 2>&1; then
  echo "No hay sesión activa. Se abrirá el navegador para 'az login'."
  run "az login" || { echo "Falló el login."; exit 1; }
else
  echo "✔ Ya hay una sesión activa como: $(az account show --query user.name -o tsv 2>/dev/null)"
fi
echo

echo "Suscripción configurada en infra/config.env: \"$AZ_SUBSCRIPTION\""
if az account show --subscription "$AZ_SUBSCRIPTION" >/dev/null 2>&1; then
  echo "✔ Esa suscripción existe y es accesible."
  run "az account set --subscription '$AZ_SUBSCRIPTION'"
else
  echo "No se encontró/no es accesible esa suscripción. Suscripciones disponibles:"
  az account list --query '[].{Nombre:name, Id:id, Estado:state}' -o table
  echo
  echo "Edita AZ_SUBSCRIPTION en infra/config.env con el nombre exacto de la suscripción a usar y vuelve a correr este script."
  exit 1
fi
echo

# --- 3. Resource providers ---------------------------------------------------
echo "Verificando resource providers necesarios (Microsoft.Compute, Microsoft.Network)..."
NEED_REGISTER=()
for provider in Microsoft.Compute Microsoft.Network; do
  estado="$(az provider show -n "$provider" --query registrationState -o tsv 2>/dev/null || echo "Desconocido")"
  echo "  $provider: $estado"
  [ "$estado" = "Registered" ] || NEED_REGISTER+=("$provider")
done
if [ "${#NEED_REGISTER[@]}" -gt 0 ]; then
  echo
  echo "Providers pendientes de registrar en la suscripción: ${NEED_REGISTER[*]}"
  echo "(Esto no crea recursos facturables, solo habilita los tipos de recurso en la suscripción.)"
  read -r -p "¿Registrarlos ahora? [s/N] " resp
  if [[ "$resp" =~ ^[sSyY]$ ]]; then
    for provider in "${NEED_REGISTER[@]}"; do
      run "az provider register --namespace $provider"
    done
    echo "Registro solicitado. Puede tardar unos minutos en completarse (verifica con: az provider show -n <nombre> --query registrationState)."
  else
    echo "Omitido. El despliegue fallará si algún provider sigue sin registrar."
  fi
else
  echo "✔ Todos los providers necesarios ya están registrados."
fi
echo

# --- 4. Secretos (clave SSH + contraseña Windows) ---------------------------
echo "Generando secretos locales (si no existen ya)..."
generate_secrets
echo "✔ Listo: $ROOT/infra/.secrets/ (id_ed25519, id_ed25519.pub, windows_password.txt)"
echo

# --- 5. Acceso de equipo -----------------------------------------------------
if [ ! -f "$ROOT/infra/equipo-acceso.txt" ]; then
  cp "$ROOT/infra/equipo-acceso.example.txt" "$ROOT/infra/equipo-acceso.txt"
  echo "✔ Creado infra/equipo-acceso.txt desde la plantilla (edítalo si necesitas agregar IPs de compañeros de equipo)."
else
  echo "✔ infra/equipo-acceso.txt ya existe."
fi
echo

echo "== Entorno listo =="
echo "Siguiente paso: revisa infra/main.bicepparam e infra/config.env, luego ejecuta:"
echo "  scripts/deploy.sh whatif   # revisa el plan (no crea nada)"
echo "  scripts/deploy.sh apply    # aplica, previa confirmación tuya"
