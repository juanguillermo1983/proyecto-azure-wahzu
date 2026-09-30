#!/usr/bin/env bash
# Uso: scripts/deploy.sh [validate|whatif|apply]   (por defecto: whatif, que NO crea nada)
set -uo pipefail
source "$(dirname "$0")/lib.sh"
MODE="${1:-whatif}"
SECRETS="$ROOT/infra/.secrets"; mkdir -p "$SECRETS"; chmod 700 "$SECRETS"

# Clave SSH y contraseña Windows: se generan una vez y se reutilizan (no van al repositorio)
[ -f "$SECRETS/id_ed25519" ] || ssh-keygen -q -t ed25519 -N "" -f "$SECRETS/id_ed25519" -C "$ADMIN_USER@lab-soc"
if [ ! -f "$SECRETS/windows_password.txt" ]; then
  # 20 caracteres con mayúscula, minúscula, dígito y símbolo (cumple política de Windows)
  { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 18; echo 'aZ9!'; } | tr -d '\n' > "$SECRETS/windows_password.txt"
  chmod 600 "$SECRETS/windows_password.txt"
fi

export MY_IP_CIDR="$("$ROOT/scripts/detect-ip.sh")"
export SSH_PUBLIC_KEY="$(cat "$SECRETS/id_ed25519.pub")"
export WINDOWS_ADMIN_PASSWORD="$(cat "$SECRETS/windows_password.txt")"

# Lista de IPs autorizadas al NSG: la propia (detectada) + las del equipo (infra/equipo-acceso.txt, sin comentarios)
TEAM_IPS="$(grep -oE '^[0-9.]+/[0-9]+' "$ROOT/infra/equipo-acceso.txt" 2>/dev/null || true)"
export ALLOWED_ADMIN_IPS_JSON="$(printf '%s\n%s\n' "$MY_IP_CIDR" "$TEAM_IPS" | grep -v '^$' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))')"

log_fase "Despliegue ($MODE)"
run "az account set --subscription '$AZ_SUBSCRIPTION'" || exit 1
echo "IPs autorizadas en el NSG: $ALLOWED_ADMIN_IPS_JSON" | tee -a "$LOG" >/dev/null
COMMON="--location $AZ_LOCATION --template-file $ROOT/infra/main.bicep --parameters $ROOT/infra/main.bicepparam"
case "$MODE" in
  validate) run "az deployment sub validate --name lab-soc $COMMON" ;;
  whatif)   run "az deployment sub what-if  --name lab-soc $COMMON" ;;
  apply)
    run "az deployment sub create --name lab-soc $COMMON --query properties.outputs -o json" || exit 1
    "$ROOT/scripts/status.sh" ;;
  *) echo "Modo inválido: $MODE"; exit 2 ;;
esac
