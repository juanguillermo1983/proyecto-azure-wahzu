#!/usr/bin/env bash
# Vuelve una VM a su condición inicial (SO limpio, sin lo instalado): borra la VM y su disco
# de sistema, conservando red/NSG/IPs, y la vuelve a crear desde la imagen original con Bicep.
# Uso: scripts/reset-vm.sh linux|windows
source "$(dirname "$0")/lib.sh"
VM="${1:?Uso: scripts/reset-vm.sh linux|windows}"
case "$VM" in
  linux)   NAME="$VM_LINUX" ;;
  windows) NAME="$VM_WINDOWS" ;;
  *) echo "Debe ser 'linux' o 'windows'"; exit 2 ;;
esac

read -r -p "Esto borra TODO lo instalado en '$NAME' (vuelve al SO recién creado). Escribe el nombre de la VM para confirmar: " r
[ "$r" = "$NAME" ] || { echo "Cancelado."; exit 1; }

log_fase "Reset de $NAME a condición inicial"
DISK_ID="$(az vm show -g "$RESOURCE_GROUP" -n "$NAME" --query storageProfile.osDisk.managedDisk.id -o tsv)"
run "az vm delete -g $RESOURCE_GROUP -n $NAME --yes"
run "az disk delete --ids '$DISK_ID' --yes"
echo "VM y disco eliminados. Recreando desde infra/ (misma IP, NSG y red)..." | tee -a "$LOG" >/dev/null
"$ROOT/scripts/deploy.sh" apply
