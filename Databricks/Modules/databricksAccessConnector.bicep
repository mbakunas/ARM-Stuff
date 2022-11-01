targetScope = 'resourceGroup'

param accessConnector_Name string
param accessConnector_location string

resource databricksAccessConnector 'Microsoft.Databricks/accessConnectors@2022-04-01-preview' = {
  name: accessConnector_Name
  location: accessConnector_location
  identity: {
    type: 'SystemAssigned'
  }
}

output databricksAccessConnectorID string = databricksAccessConnector.id
