targetScope = 'subscription'

param workspace_location string = deployment().location

param workspace_resourceGroupName string

param metastore_name string


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

