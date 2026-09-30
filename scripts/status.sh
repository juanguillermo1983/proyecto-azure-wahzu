#!/usr/bin/env bash
# Estado de la infraestructura: VMs (estado de energía), IPs públicas y privadas.
source "$(dirname "$0")/lib.sh"
log_fase "Estado"
run "az vm list -g $RESOURCE_GROUP -d --query '[].{VM:name,Tamano:hardwareProfile.vmSize,Estado:powerState,IPPrivada:privateIps,IPPublica:publicIps}' -o table"
