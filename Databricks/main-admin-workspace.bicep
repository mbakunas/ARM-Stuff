/*
  This template deploys the necessary Azure resources for the Databricks central metastore

  - A "central" Databricks workspace:
    - Injected to a VNet
    - with both private endpoints (the browser authN and workspace_ui_api)
  
  - A data lake storage account with blob and dfs private endpoints

  - RBAC assignment of Storage Blob Data Contributor on the data lake to an existing Databricks Access Connector
  
  - The "private" and "public" subnets (OK if they already exist)
  - The NSG and attach it to the "private" and "public" subnets
  - Delegate the "private" and "public" subnets to Microsoft.Databricks/workspaces

  Assumes:
  - VNet has already been deployed 
  - An existing Access Connector for Databricks was deployed via the Azure Portal
*/

targetScope = 'subscription'

param workspace_location string = deployment().location

param workspace_resourceGroupName string
param workspace_VNet_resourceGroup string

param workspace_name string
param workspace_vnetName string
param workspace_privateSubnetName string
param workspace_privateSubnetAddressSpace string
param workspace_publicSubnetName string
param workspace_publicSubnetAddressSpace string

param privateDnsZone_subscriptionId string = subscription().subscriptionId
param endpoint_subnetName string
param endpoint_privateDnsZoneResourceGroup string


var deploymentName = deployment().name
var workspace_managedResourceGroupName = 'databricks-rg-${workspace_name}-${uniqueString(workspace_name, workspace_resourceGroupName)}'
var workspace_customVirtualNetworkId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks', workspace_vnetName)
var endpoint_subnetId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', workspace_vnetName, endpoint_subnetName)
var workspace_privateDnsZoneId = resourceId(privateDnsZone_subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')


// resource groups
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

// network prerequisites: subnets & delegation, and nsg (assumes VNet already deployed)
module network 'Modules/databricks-network.bicep' = {
  name: '${deploymentName}-Network'
  scope: rgNetwork
  params: {
    location: workspace_location
    nsgName: '${workspace_name}-NSG'
    privateSubnetName: workspace_privateSubnetName
    privateSubnetAddressSpace: workspace_privateSubnetAddressSpace
    publicSubnetName: workspace_publicSubnetName
    publicSubnetAddressSpace: workspace_publicSubnetAddressSpace
    vnetName: workspace_vnetName
  }
}

// databricks 'admin' workspace
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


// browser_authentication endpoint
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
    privateDnsZoneId: workspace_privateDnsZoneId
  }
}

// databricks_ui_api endpoint
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
    privateDnsZoneId: workspace_privateDnsZoneId
  }
}
