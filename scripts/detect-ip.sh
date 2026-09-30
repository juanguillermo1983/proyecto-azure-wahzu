#!/usr/bin/env bash
# Imprime la IP pública actual en formato CIDR (x.x.x.x/32) para el NSG.
set -euo pipefail
ip="$(curl -fsS https://api.ipify.org || curl -fsS https://ifconfig.me)"
[[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "No se pudo detectar la IP pública" >&2; exit 1; }
echo "$ip/32"
