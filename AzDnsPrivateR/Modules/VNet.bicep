targetScope = 'resourceGroup'

// VNet
param vnet_Name string
param vnet_AddressSpace string
param vnet_Location string

// Subnets
param vnet_subnets array
/*
Format the array like this:
  {
    name: 'AzureBastionSubnet'
    addressSpace: '10.0.0.128/26'
  }
  {
    name: 'CorpNet'
    addressSpace: '10.0.1.0/24'
  }
]
*/

// because we can't pass id:null to networkSecurityGroup, we have to build the json manually
//var nsgJson = [for i in range(0, length(vnet_subnets)) : contains(vnet_subnets[i], 'nsgName') ? json('{\'id: ${vnet_subnets[i].nsgName}\'}') : null]

// create any NSGs
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = [for (subnet, i) in vnet_subnets: if (contains(subnet, 'nsgName')) {
  name: contains(subnet, 'nsgName') ? subnet.nsgName : 'networkSecurityGroup${i}'
  location: vnet_Location
  tags: resourceGroup().tags
  properties: {
    securityRules: []
  }
}]

// create the VNet
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnet_Name
  location: vnet_Location
  tags: resourceGroup().tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_AddressSpace
      ]
    }
    subnets: [for (subnet, i) in vnet_subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressSpace
        networkSecurityGroup: !(contains(subnet, 'nsgName')) ? null : {
          id: networkSecurityGroup[i].id
        }
      }
    }]
  }
}
