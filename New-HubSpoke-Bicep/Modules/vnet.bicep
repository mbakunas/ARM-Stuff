targetScope = 'resourceGroup'

param vnetName string
param vnetLocation string
param vnetAddressSpace string
param vnetSubnets array
param vnetSubnetsNsgRuleSets object

//replace [subnet] with the local subnet address space



resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [for (subnet, i) in vnetSubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressSpace
        networkSecurityGroup: {
          id: networkSecurityGroup[i].id
        }
      }
    }]
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-07-01' = [for (subnet, i) in vnetSubnets: {
  name: '${subnet.name}-NSG'
  location: vnetLocation
}]

module nsgRules 'nsgRules.bicep' = {
  name: 
  params: {
    nsgName: 
    nsgRuleSet: 
    subnetAddressSpace: 
  }
}
