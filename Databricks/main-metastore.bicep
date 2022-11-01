/*
  This template deploys the necessary Azure resources for the Databricks central metastore
  
  - A "central" Databricks workspace:
    - Injected to a VNet
    - with both private endpoints (the browser authN and workspace_ui_api)
  
  - A data lake storage account with blob and dfs private endpoints

  - The Databricks Access Connector
    - RBAC assignment of Storage Blob Data Contributor to the data lake

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

param metastore_name string
param databricksConnector_Name string


var deploymentName = deployment().name
var workspace_managedResourceGroupName = 'databricks-rg-${workspace_name}-${uniqueString(workspace_name, workspace_resourceGroupName)}'
var workspace_customVirtualNetworkId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks', workspace_vnetName)
var endpoint_subnetId = resourceId(subscription().subscriptionId, workspace_VNet_resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', workspace_vnetName, endpoint_subnetName)
var workspace_privateDnsZoneId = resourceId(privateDnsZone_subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
var datalake_privateDnsZoneId_blob = resourceId(privateDnsZone_subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')
var datalake_privateDnsZoneId_dfs = resourceId(privateDnsZone_subscriptionId, endpoint_privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')

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

// data lake storage
module dataLake 'Modules/dataLake.bicep' = {
  scope: rgWorkspace
  name: '${deploymentName}-dataLake'
  params: {
    storageAccount_location: workspace_location
    storageAccount_name: metastore_name

  }
}

// blob endpoint
module privateEndpointBlob 'Modules/privateEndpoint.bicep' = {
  dependsOn: [
    dataLake
    network
  ]
  scope: rgWorkspace
  name: '${deploymentName}-endpoint-blob'
  params: {
    groupId: 'blob'
    location: workspace_location
    privateEndpointName: '${metastore_name}-endpoint-blob'
    privateLinkServiceId: dataLake.outputs.datalakeID
    subnetId: endpoint_subnetId
    privateDnsZoneId: datalake_privateDnsZoneId_blob
  }
}

// dfs endpoint
module privateEndpointDfs 'Modules/privateEndpoint.bicep' = {
  dependsOn: [
    privateEndpointBlob
  ]
  scope: rgWorkspace
  name: '${deploymentName}-endpoint-dfs'
  params: {
    groupId: 'blob'
    location: workspace_location
    privateEndpointName: '${metastore_name}-endpoint-dfs'
    privateLinkServiceId: dataLake.outputs.datalakeID
    subnetId: endpoint_subnetId
    privateDnsZoneId: datalake_privateDnsZoneId_dfs
  }
}

// databricks access connector
module databricksConnector 'Modules/databricksAccessConnector.bicep' = {
  dependsOn: [
    workspace
  ]
  scope: rgWorkspace
  name: '${deploymentName}-databricksConnector'
  params: {
    accessConnector_location: workspace_location
    accessConnector_Name: databricksConnector_Name
  }
}

// RBAC assignment - databricks access connector gets storage blob data contributor 
var rbacRole_storageBlobDataContributorID = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

module rbac_assignment 'Modules/roleAssignment.bicep' = {
  dependsOn: [
    databricksConnector
    dataLake
  ]
  scope: rgWorkspace
  name: '${deploymentName}-rbacAssignment'
  params: {
    dataLakeName: metastore_name
    principalId: databricksConnector.outputs.databricksAccessConnectorID
    roleDefinitionId: rbacRole_storageBlobDataContributorID
  }
}
