targetScope = 'subscription'

param vnets array = [
  {
    rgName: 'InfraNetwork'
    name: 'Hub-EastUS2-01'
    location: 'eastus2'
    addressSpace: '10.1.0.0/23'
    subnets: [
      {
        name: 'GatewaySubnet'
        addressSpace: '10.1.0.0/27'
        ////nsgRules: 'GatewaySubnet'
      }
      {
        name: 'AzureFirewallSubnet'
        addressSpace: '10.1.0.64/26'
      }
      {
        name: 'AzureBastionSubnet'
        addressSpace: '10.1.0.128/26'
        //nsgRules: 'AzureBastionSubnet'
      }
      {
        name: 'PrivateDnsResolver'
        addressSpace: '10.1.0.192/26'
        //nsgRules: 'PrivateDnsResolver'
      }
      {
        name: 'Infra-DC'
        addressSpace: '10.1.1.0/27'
        nsgRules: 'DomainControllers'
      }
    ]
  }
]


var nsgRuleSets = loadJsonContent('nsgRuleSets.json')


// hub vnet

resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: vnets[0].rgName
  location: vnets[0].location
}

module hubVirtualNetwork 'Modules/vnet.bicep' = {
  scope: hubResourceGroup
  name: vnets[0].name
  params: {
    vnetAddressSpace: vnets[0].addressSpace
    vnetLocation: vnets[0].location
    vnetName: vnets[0].name
    vnetSubnets: vnets[0].subnets
    vnetSubnetsNsgRuleSets: nsgRuleSets
  }
}






// spoke vnet(s)





