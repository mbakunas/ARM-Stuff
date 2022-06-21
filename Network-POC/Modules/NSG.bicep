targetScope = 'resourceGroup'

param nsg_Location string
param nsg_Subnets array
param nsg_VNet string


resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: nsg_VNet
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = [for (subnet, i) in nsg_Subnets: if (contains(subnet, 'nsgName')) {
  name: contains(subnet, 'nsgName') ? subnet.nsgName : 'Foo${i}'
  location: nsg_Location
  tags: resourceGroup().tags
  properties: {
    securityRules: []
  }
}]

resource appGWnsgRule1 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = [for subnet in nsg_Subnets: if (contains(subnet, 'appGWservice')) {
  name: '${subnet.nsgName}/AppGW_Allow_65200-65535'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '65200-65535'
    sourceAddressPrefix: 'GatewayManager'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 4010
    direction: 'Inbound'    
  }
}]

resource appGWnsgRule2 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = [for subnet in nsg_Subnets: if (contains(subnet, 'appGWservice')) {
  name: '${subnet.nsgName}/Allow_http_https_from_Internet'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '80'
      '443'
    ]
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: subnet.addressSpace
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}]

@batchSize(1)
resource nsgSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = [for (subnet, i) in nsg_Subnets: if (contains(subnet, 'nsgName')) {
  name: contains(subnet, 'nsgName') ? subnet.name : 'Bar${i}'
  parent: vnet
  dependsOn: [appGWnsgRule1, appGWnsgRule2]
  properties: {
    addressPrefix: subnet.addressSpace
    networkSecurityGroup: {
      id: networkSecurityGroup[i].id
    }
  }
}]
