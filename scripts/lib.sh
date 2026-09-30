#!/usr/bin/env bash
# Utilidades comunes: carga config y registra cada comando + salida en logs/log-instalacion-azure.md
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/infra/config.env"
LOG="$ROOT/logs/log-instalacion-azure.md"
mkdir -p "$ROOT/logs"

log_fase() { printf '\n## %s\n' "$1" >> "$LOG"; echo "== $1 =="; }

# run "<comando>": lo ejecuta, lo muestra y lo deja en el log (con fecha y código de salida)
run() {
  local cmd="$*" out rc
  out="$(eval "$cmd" 2>&1)"; rc=$?
  printf '\n**%s** — `%s`\n\n```\n%s\n```\nCódigo de salida: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$cmd" "$out" "$rc" >> "$LOG"
  echo "$out"
  return $rc
}

# generate_secrets: crea (si no existen) el par de llaves SSH y la contraseña de Windows
# en infra/.secrets/. Idempotente: si ya existen, no los toca. Usado por deploy.sh y setup-entorno.sh.
generate_secrets() {
  local secrets="$ROOT/infra/.secrets"
  mkdir -p "$secrets"; chmod 700 "$secrets"
  if [ ! -f "$secrets/id_ed25519" ]; then
    ssh-keygen -q -t ed25519 -N "" -f "$secrets/id_ed25519" -C "$ADMIN_USER@lab-soc"
    echo "Generada clave SSH: $secrets/id_ed25519 (privada) / .pub (pública)"
  fi
  if [ ! -f "$secrets/windows_password.txt" ]; then
    # 20 caracteres con mayúscula, minúscula, dígito y símbolo (cumple política de contraseñas de Windows)
    { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 18; echo 'aZ9!'; } | tr -d '\n' > "$secrets/windows_password.txt"
    chmod 600 "$secrets/windows_password.txt"
    echo "Generada contraseña de Windows: $secrets/windows_password.txt"
  fi
}
