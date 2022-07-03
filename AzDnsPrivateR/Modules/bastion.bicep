targetScope = 'resourceGroup'

param bastion_name string
param bastion_location string
param bastion_vnetName string

var bastion_sku = 'Standard'
var bastion_subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', bastion_vnetName, 'AzureBastionSubnet')
var bastion_scaleUnits = 2
var bastion_disableCopyPaste = false
var bastion_enableFileCopy = true

// public ip address
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${bastion_name}-IP'
  tags: resourceGroup().tags
  location: bastion_location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// bastion
resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastion_name
  location: bastion_location
  tags: resourceGroup().tags
  sku: {
    name: bastion_sku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConfig'
        properties: {
          subnet: {
            id: bastion_subnetId
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
    scaleUnits: bastion_scaleUnits
    disableCopyPaste: bastion_disableCopyPaste
    enableFileCopy: bastion_enableFileCopy
  }
}
