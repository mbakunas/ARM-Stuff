/*
  This template deploys a Databricks workspace:
    - Injected to a VNet
    - with one or both private endpoints: browser_authentication (optional) and workspace_ui_api

  Assumes:
  - VNet has already been deployed 
  - The "private" and "public" subnets have also been deployed
  - A single NSG (or an NSG per subnet) have been deployed and attached to the "private" and "public" subnets
  - The "private" and "public" subnets have been delegated to Microsoft.Databricks/workspaces
*/

targetScope = 'resourceGroup'

param workspace_location string = resourceGroup().location
param workspace_deploy_browserAuth bool = false

param workspace_VNet_subscriptionId string = subscription().subscriptionId
param workspace_VNet_resourceGroup string
param workspace_name string
param workspace_vnetName string
param workspace_privateSubnetName string
param workspace_publicSubnetName string

param endpoint_privateDnsZone_subscriptionId string = subscription().subscriptionId  //subscriptionID of the subscription where the privatelink.azuredatabricks.net DNS zone lives
param endpoint_subnetName string
param endpoint_privateDnsZoneResourceGroup string


var deploymentName = deployment().name
var workspace_managedResourceGroupName = 'databricks-rg-${workspace_name}-${uniqueString(workspace_name, resourceGroup().name)}'
var workspace_managedResourceGroupId = subscriptionResourceId('Microsoft.Resources/resourceGroups', workspace_managedResourceGroupName)
var workspace_customVirtualNetworkId = resourceId(workspace_VNet_subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks', workspace_vnetName)
var endpoint_subnetId = resourceId(workspace_VNet_subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', workspace_vnetName, endpoint_subnetName)
var workspace_privateDnsZoneId = resourceId(endpoint_privateDnsZone_subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')


// databricks 'admin' workspace
module workspace 'Modules/databricks.bicep' = {
  name: '${deploymentName}-workspace'
  params: {
    customVirtualNetworkId: workspace_customVirtualNetworkId
    location: workspace_location
    managedResourceGroupId: workspace_managedResourceGroupId
    name: workspace_name
    privateSubnetName: workspace_privateSubnetName
    publicSubnetName: workspace_publicSubnetName
  }
}


// databricks_ui_api endpoint
module privateEndpointUi 'Modules/privateEndpoint.bicep' = {
  dependsOn: [
    workspace
  ]
  name: '${deploymentName}-endpoint-ui'
  params: {
    groupId: 'databricks_ui_api'
    location: workspace_location
    privateEndpointName: '${workspace_name}-endpoint-ui'
    privateLinkServiceId: workspace.outputs.workspaceId
    subnetId: endpoint_subnetId
    privateDnsZoneId: workspace_privateDnsZoneId
  }
}

// browser_authentication endpoint
module privateEndpointAuth 'Modules/privateEndpoint.bicep' = if (workspace_deploy_browserAuth) {
  dependsOn: [
    privateEndpointUi
  ]
  name: '${deploymentName}-endpoint-auth'
  params: {
    groupId: 'browser_authentication'
    location: workspace_location
    privateEndpointName: '${workspace_name}-endpoint-auth'
    privateLinkServiceId: workspace.outputs.workspaceId
    subnetId: endpoint_subnetId
    privateDnsZoneId: workspace_privateDnsZoneId
  }
}
