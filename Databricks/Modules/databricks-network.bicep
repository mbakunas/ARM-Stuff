targetScope = 'resourceGroup'

param name string
param location string
param vnetName string
param privateSubnetName string
param privateSubnetPrefix string
param publicSubnetName string
param publicSubnetPrefix string

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: '${name}-NSG'
  location: location
}

resource privateSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${vnetName}/${privateSubnetName}'
  properties: {
    addressPrefix: privateSubnetPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
    delegations: [
      {
        name: 'databricks-private-delegation'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
}

resource publicSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  dependsOn: [
    privateSubnet
  ]
  name: '${vnetName}/${publicSubnetName}'
  properties: {
    addressPrefix: publicSubnetPrefix
    networkSecurityGroup:  {
      id: nsg.id
    }
    delegations: [
      {
        name: 'databricks-public-delegation'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
}
