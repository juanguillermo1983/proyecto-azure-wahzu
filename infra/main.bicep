// Laboratorio SOC con Wazuh - punto de entrada (ámbito: suscripción).
// Crea el grupo de recursos y delega red + VMs en resources.bicep.
// Despliegue: scripts/deploy.sh   |   Destrucción: scripts/destroy.sh
targetScope = 'subscription'

@description('Región de Azure (decidida en docs/decisiones.md).')
param location string

@description('Nombre del grupo de recursos.')
param resourceGroupName string

@description('Lista de IPs/CIDR autorizadas a administración (propia + equipo). La arma scripts/deploy.sh a partir de infra/equipo-acceso.txt.')
param allowedAdminIps array

@description('Prefijo de la VNet.')
param vnetPrefix string

@description('Nombre de la subred.')
param subnetName string

@description('Prefijo de la subred.')
param subnetPrefix string

@description('Usuario administrador de ambas VMs.')
param adminUsername string

@description('Clave pública SSH para la VM Linux (la entrega scripts/deploy.sh).')
param sshPublicKey string

@secure()
@description('Contraseña del administrador Windows (la genera scripts/deploy.sh).')
param windowsAdminPassword string

param linuxVmName string
param linuxVmSize string
param windowsVmName string
param windowsVmSize string

@description('Tamaño en GB del disco de sistema Linux (Wazuh All-in-One necesita espacio para el Indexer).')
param linuxDiskSizeGB int

param tags object

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module lab 'resources.bicep' = {
  name: 'lab-soc'
  scope: rg
  params: {
    location: location
    allowedAdminIps: allowedAdminIps
    vnetPrefix: vnetPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    windowsAdminPassword: windowsAdminPassword
    linuxVmName: linuxVmName
    linuxVmSize: linuxVmSize
    windowsVmName: windowsVmName
    windowsVmSize: windowsVmSize
    linuxDiskSizeGB: linuxDiskSizeGB
    tags: tags
  }
}

output linuxPublicIp string = lab.outputs.linuxPublicIp
output linuxPrivateIp string = lab.outputs.linuxPrivateIp
output windowsPublicIp string = lab.outputs.windowsPublicIp
output windowsPrivateIp string = lab.outputs.windowsPrivateIp
