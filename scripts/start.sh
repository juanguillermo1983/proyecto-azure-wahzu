#!/usr/bin/env bash
# Enciende las VMs. Las IPs públicas son estáticas y se conservan.
source "$(dirname "$0")/lib.sh"
log_fase "Encendido de VMs"
run "az vm start -g $RESOURCE_GROUP -n $VM_LINUX --no-wait"
run "az vm start -g $RESOURCE_GROUP -n $VM_WINDOWS --no-wait"
