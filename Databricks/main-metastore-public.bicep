targetScope = 'subscription'

param workspace_location string = deployment().location

param workspace_resourceGroupName string

param metastore_name string
param databricksConnector_Name string


var deploymentName = deployment().name

// resource groups
resource rgWorkspace 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: workspace_resourceGroupName
  location: workspace_location
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

// metastore container
module container 'Modules/container.bicep' = {
  dependsOn: [
    dataLake
  ]
  scope: rgWorkspace
  name: '${deploymentName}-dataLake-container'
  params: {
    storageAccountName: metastore_name
  }
}

module databricksConnector 'Modules/databricksAccessConnector.bicep' = {
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
    principalId: databricksConnector.outputs.databricksAccessConnectorPrincipalID
    roleDefinitionId: rbacRole_storageBlobDataContributorID
  }
}
