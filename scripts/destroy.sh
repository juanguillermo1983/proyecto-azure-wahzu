#!/usr/bin/env bash
# Borra TODO el laboratorio (el grupo de recursos completo). Irreversible: pide confirmación escrita.
source "$(dirname "$0")/lib.sh"
read -r -p "Se borrará el grupo '$RESOURCE_GROUP' con todas sus VMs y discos. Escribe el nombre para confirmar: " r
[ "$r" = "$RESOURCE_GROUP" ] || { echo "Cancelado."; exit 1; }
log_fase "Destrucción"
run "az group delete -n $RESOURCE_GROUP --yes"
