targetScope = 'resourceGroup'

param routeTable_Name string
param routeTable_RouteName string = 'AzureCloudServices'
param routeTable_Location string

resource routeTable 'Microsoft.Network/routeTables@2021-08-01' = {
  name: routeTable_Name
  location: routeTable_Location
  tags: resourceGroup().tags
  properties: {
    routes: [
      {
        name: routeTable_RouteName
        properties: {
          addressPrefix: 'AzureCloud'
          nextHopType: 'Internet'
        }
      }
    ]
    disableBgpRoutePropagation: true
  }
}

output routeTable_Id string = routeTable.id
