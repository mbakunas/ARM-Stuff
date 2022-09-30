targetScope = 'subscription'

param workspace_name string
param workspace_location string
param workspace_resourceGroupName string
param workspace_VNet_Name string
param workspace_VNet_resourceGroup string
param workspace_privateSubnetName string
param workspace_publicSubnetName string


param endpoint_subnetName string
param endpoint_privateDnsZoneResourceGroup string


var deploymentName = deployment().name
var workspace_managedResourceGroupName = 'databricks-rg-${workspace_name}-${uniqueString(workspace_name, workspace_resourceGroupName)}'
var workspace_customVirtualNetworkId = resourceId(subscription().id, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks', workspace_VNet_Name)
var endpoint_name = '${workspace_name}-endpoint'
var endpoint_subnetId = resourceId(subscription().id, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', workspace_VNet_Name, endpoint_subnetName)
var privateDnsZoneId = resourceId(subscription().id, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')

resource rgWorkspace 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: workspace_resourceGroupName
  location: workspace_location
}

resource rgManaged 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: workspace_managedResourceGroupName
  location: workspace_location
}

resource rgNetwork 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workspace_VNet_resourceGroup
}

module workspace 'Modules/databricks.bicep' = {
  scope: rgWorkspace
  name: '${deploymentName}-databricks'
  params: {
    customVirtualNetworkId: workspace_customVirtualNetworkId
    location: workspace_location
    managedResourceGroupId: rgManaged.id
    name: workspace_name
    privateSubnetName: workspace_privateSubnetName
    publicSubnetName: workspace_publicSubnetName
  }
}

module network 'Modules/databricks-network.bicep' = {
  scope: rgNetwork
  name: '${deploymentName}-network'
  params: {
    location: workspace_location
    name: workspace_name
    privateSubnetName: workspace_privateSubnetName
    publicSubnetName: workspace_publicSubnetName
    vnetName: workspace_VNet_Name
  }
}

module privateEndpoint 'Modules/privateEndpoint.bicep' = {
  scope: rgWorkspace
  name: '${deploymentName}-endpoint'
  params: {
    groupId: 'databricks_ui_api'
    location: workspace_location
    privateEndpointName: endpoint_name
    privateLinkServiceId: workspace.outputs.workspaceId
    subnetId: endpoint_subnetId
    privateDnsZoneId: privateDnsZoneId
  }
}
