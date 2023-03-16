targetScope = 'resourceGroup'

param vnet object = {
  name: 'Spoke-EastUS2-01'
  location: 'eastus2'
  addressSpace: '10.0.0.0/23'
  subnets: [
      {
          name: 'appGW'
          addressSpace: '10.0.0.0/24'
          nsgRules: 'appGW'
      }
      {
          name: 'app1'
          addressSpace: '10.0.1.0/26'
      }
      {
          name: 'app2'
          addressSpace: '10.0.1.64/26'
      }
      {
          name: 'app3'
          addressSpace: '10.0.1.128/26'
      }
    ]  
}

var nsgRuleSets = loadJsonContent('../nsgRuleSets.json')

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnet.name
  location: vnet.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.addressSpace
      ]
    }
    subnets: [for (subnet, i) in vnet.subnets: {
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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-07-01' = [for (subnet, i) in vnet.subnets: {
  name: '${subnet.name}-NSG'
  location: vnet.location
  properties: {
    securityRules: nsgRuleSets[subnet.nsgRules]
  }
}]
