targetScope = 'resourceGroup'

param name string
param location string
param pricingTier string = 'premium'
param customVirtualNetworkId string
param privateSubnetName string
param publicSubnetName string
param managedResourceGroupId string

param enableNoPublicIp bool = true
param publicNetworkAccess string = 'Disabled'
param requiredNsgRules string = 'NoAzureDatabricksRules'

resource workspace 'Microsoft.Databricks/workspaces@2022-04-01-preview' = {
  name: name
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      enableNoPublicIp: {
        value: enableNoPublicIp
      }
      customVirtualNetworkId: {
        value: customVirtualNetworkId
      }
      customPublicSubnetName: {
        value: privateSubnetName
      }
      customPrivateSubnetName: {
        value: publicSubnetName
      }
    }
    publicNetworkAccess: publicNetworkAccess
    requiredNsgRules: requiredNsgRules
  }
}

output workspaceId string = workspace.id
