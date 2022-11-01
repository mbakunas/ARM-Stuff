targetScope = 'resourceGroup'

param nsgName string
param location string
param vnetName string
param privateSubnetName string
param privateSubnetAddressSpace string
param publicSubnetName string
param publicSubnetAddressSpace string

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: nsgName
  location: location
}

resource privateSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${vnetName}/${privateSubnetName}'
  properties: {
    addressPrefix: privateSubnetAddressSpace
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
    addressPrefix: publicSubnetAddressSpace
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
