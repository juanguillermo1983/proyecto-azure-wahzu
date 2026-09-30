// Red, NSG y las dos VMs del laboratorio (ámbito: grupo de recursos).
targetScope = 'resourceGroup'

param location string
@description('Lista de IPs/CIDR autorizadas a administración (la propia + compañeros de equipo). Ver infra/equipo-acceso.txt.')
param allowedAdminIps array
param vnetPrefix string
param subnetName string
param subnetPrefix string
param adminUsername string
param sshPublicKey string
@secure()
param windowsAdminPassword string
param linuxVmName string
param linuxVmSize string
param windowsVmName string
param windowsVmSize string
param linuxDiskSizeGB int
param tags object

// ---------- NSG ----------
// Gestión (22/3389/443) solo desde las IPs autorizadas (estudiante + equipo); agente Wazuh (1514/1515) e ICMP solo dentro de la subred.
// Ninguna regla usa 0.0.0.0/0 como origen.
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-lab-soc'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-Admin-From-MyIP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: allowedAdminIps
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [ '22', '3389', '443' ]
        }
      }
      {
        name: 'Allow-WazuhAgent-Internal'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: subnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrefix
          destinationPortRanges: [ '1514', '1515' ]
        }
      }
      {
        name: 'Allow-ICMP-Internal'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Icmp'
          sourceAddressPrefix: subnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrefix
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// ---------- VNet + subred ----------
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-lab'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ vnetPrefix ] }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: { id: nsg.id }
        }
      }
    ]
  }
}

var subnetId = '${vnet.id}/subnets/${subnetName}'

// ---------- IPs públicas (Standard, estáticas) ----------
resource pipLinux 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${linuxVmName}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource pipWindows 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${windowsVmName}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// ---------- NICs ----------
resource nicLinux 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${linuxVmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pipLinux.id }
        }
      }
    ]
  }
}

resource nicWindows 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${windowsVmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pipWindows.id }
        }
      }
    ]
  }
}

// ---------- VM Linux (Ubuntu 24.04 LTS) ----------
resource vmLinux 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: linuxVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: linuxVmSize }
    osProfile: {
      computerName: linuxVmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: linuxDiskSizeGB
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: { networkInterfaces: [ { id: nicLinux.id } ] }
  }
}

// ---------- VM Windows (Server 2022) ----------
resource vmWindows 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: windowsVmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: windowsVmSize }
    osProfile: {
      computerName: take(windowsVmName, 15) // límite NetBIOS de Windows
      adminUsername: adminUsername
      adminPassword: windowsAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: { networkInterfaces: [ { id: nicWindows.id } ] }
  }
}

output linuxPublicIp string = pipLinux.properties.ipAddress
output windowsPublicIp string = pipWindows.properties.ipAddress
output linuxPrivateIp string = nicLinux.properties.ipConfigurations[0].properties.privateIPAddress
output windowsPrivateIp string = nicWindows.properties.ipConfigurations[0].properties.privateIPAddress
