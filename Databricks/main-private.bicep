targetScope = 'subscription'

param workspace_name string
param workspace_location string
param workspace_resourceGroupName string
param workspace_VNet_Name string
param workspace_VNet_resourceGroup string
param workspace_privateSubnetName string
param workspace_privateSubnetPrefix string
param workspace_publicSubnetName string
param workspace_publicSubnetPrefix string


param endpoint_subnetName string
param endpoint_privateDnsZoneResourceGroup string


var deploymentName = deployment().name
var workspace_managedResourceGroupName = 'databricks-rg-${workspace_name}-${uniqueString(workspace_name, workspace_resourceGroupName)}'
var workspace_customVirtualNetworkId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks', workspace_VNet_Name)
//var endpoint_name = '${workspace_name}-endpoint'
var endpoint_subnetId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', workspace_VNet_Name, endpoint_subnetName)
var privateDnsZoneId = resourceId(subscription().subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')

resource rgWorkspace 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: workspace_resourceGroupName
  location: workspace_location
}

resource rgManaged 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workspace_managedResourceGroupName
}

resource rgNetwork 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workspace_VNet_resourceGroup
}

module network 'Modules/databricks-network.bicep' = {
  scope: rgNetwork
  name: '${deploymentName}-network'
  params: {
    location: workspace_location
    nsgName: '${workspace_name}-NSG'
    privateSubnetName: workspace_privateSubnetName
    publicSubnetName: workspace_publicSubnetName
    vnetName: workspace_VNet_Name
    privateSubnetAddressSpace: workspace_privateSubnetPrefix
    publicSubnetAddressSpace: workspace_publicSubnetPrefix
  }
}

module workspace 'Modules/databricks.bicep' = {
  dependsOn: [
    network
  ]
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

module privateEndpointUi 'Modules/privateEndpoint.bicep' = {
  dependsOn: [
    workspace
  ]
  scope: rgWorkspace
  name: '${deploymentName}-endpoint-ui'
  params: {
    groupId: 'databricks_ui_api'
    location: workspace_location
    privateEndpointName: '${workspace_name}-endpoint-ui'
    privateLinkServiceId: workspace.outputs.workspaceId
    subnetId: endpoint_subnetId
    privateDnsZoneId: privateDnsZoneId
  }
}

module privateEndpointAuth 'Modules/privateEndpoint.bicep' = {
  dependsOn: [
    privateEndpointUi
  ]
  scope: rgWorkspace
  name: '${deploymentName}-endpoint-auth'
  params: {
    groupId: 'browser_authentication'
    location: workspace_location
    privateEndpointName: '${workspace_name}-endpoint-auth'
    privateLinkServiceId: workspace.outputs.workspaceId
    subnetId: endpoint_subnetId
    privateDnsZoneId: privateDnsZoneId
  }
}
