#!/usr/bin/env bash
# Apaga y desasigna las VMs (dejan de cobrar cómputo; los discos siguen cobrando poco).
source "$(dirname "$0")/lib.sh"
log_fase "Apagado de VMs"
run "az vm deallocate -g $RESOURCE_GROUP -n $VM_LINUX --no-wait"
run "az vm deallocate -g $RESOURCE_GROUP -n $VM_WINDOWS --no-wait"
