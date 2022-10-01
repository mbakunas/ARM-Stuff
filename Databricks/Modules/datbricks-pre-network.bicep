targetScope = 'resourceGroup'

param vnetName string
param vnetLocation string
param vnetAddressSpace string = '10.0.0.0/21'
param subnetBastionAddressSpace string = '10.0.0.128/26'
param subnetPrivateLinkName string = 'PrivateLink'
param subnetPrivateLinkAddressSpace string = '10.0.1.0/24'
param subnet1Name string = 'CorpNet'
param subnet1AddressSpace string = '10.0.2.0/24'

resource nsgPrivateLink 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: '${subnetPrivateLinkName}-NSG'
}

resource nsgSubnet1 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: '${subnet1Name}-NSG'
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: subnetBastionAddressSpace
        }
      }
      {
        name: subnetPrivateLinkName
        properties: {
          addressPrefix: subnetPrivateLinkAddressSpace
          networkSecurityGroup: {
            id: nsgPrivateLink.id
          }
        }
      }
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1AddressSpace
          networkSecurityGroup: {
            id: nsgSubnet1.id
          }
        }
      }
    ]
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'AzureBastionSubnet'
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: '${vnetName}-Bastion'
  location: vnetLocation
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: bastionIp.id
          }
          subnet: {
            id: bastionSubnet.id
          }
        }
      }
    ]
  }
}

resource bastionIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${vnetName}-Bastion-IP'
  location: vnetLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azuredatabricks.net'
  location: 'global'
}

resource privateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDns
  name: uniqueString(privateDns.id, vnet.id)
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
