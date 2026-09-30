// Parámetros del laboratorio. Editar aquí para cambiar región, nombres o tamaños y volver a aplicar con scripts/deploy.sh.
// Los valores sensibles o dinámicos vienen de variables de entorno que exporta scripts/deploy.sh.
using 'main.bicep'

// --- Decisiones (ver docs/decisiones.md) ---
param location = 'mexicocentral'
param resourceGroupName = 'RG-LAB-SOC'

// --- Red (exigida por el enunciado) ---
param vnetPrefix = '10.0.0.0/16'
param subnetName = 'subnet-lab'
param subnetPrefix = '10.0.1.0/24'

// --- VMs ---
param adminUsername = 'socadmin'
param linuxVmName = 'vm-soc-linux'
param linuxVmSize = 'Standard_B2as_v2' // B2ms/B2s sin capacidad y D2s_v5 con cuota 0 en las regiones permitidas (ver docs/decisiones.md)
param linuxDiskSizeGB = 64
param windowsVmName = 'vm-soc-windows'
param windowsVmSize = 'Standard_B2as_v2'

// --- Dinámicos: los exporta scripts/deploy.sh ---
// allowedAdminIps = [IP propia detectada automáticamente] + IPs de infra/equipo-acceso.txt
param allowedAdminIps = json(readEnvironmentVariable('ALLOWED_ADMIN_IPS_JSON'))
param sshPublicKey = readEnvironmentVariable('SSH_PUBLIC_KEY')
param windowsAdminPassword = readEnvironmentVariable('WINDOWS_ADMIN_PASSWORD')

param tags = {
  proyecto: 'lab-soc-wazuh'
  curso: 'defensa-operativa-ciberseguridad'
}
