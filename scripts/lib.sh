#!/usr/bin/env bash
# Utilidades comunes: carga config y registra cada comando + salida en logs/log-instalacion-azure.md
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/infra/config.env"
LOG="$ROOT/logs/log-instalacion-azure.md"

log_fase() { printf '\n## %s\n' "$1" >> "$LOG"; echo "== $1 =="; }

# run "<comando>": lo ejecuta, lo muestra y lo deja en el log (con fecha y código de salida)
run() {
  local cmd="$*" out rc
  out="$(eval "$cmd" 2>&1)"; rc=$?
  printf '\n**%s** — `%s`\n\n```\n%s\n```\nCódigo de salida: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$cmd" "$out" "$rc" >> "$LOG"
  echo "$out"
  return $rc
}
