targetScope = 'resourceGroup'

param dataFactory_name string
param dataFactory_location string

param privateEndpoint_vnetName string
param privateEndpoint_subnetName string
param privateEndpoint_vnetRg string


var privateEndpoint_name = '${dataFactory_name}-PE'
var privateEndpoint_NICname = '${privateEndpoint_name}-NIC'
var privateEndpoint_subnetId = resourceId(privateEndpoint_vnetRg, 'Microsoft.Network/virtualNetworks/subnets', privateEndpoint_vnetName, privateEndpoint_subnetName)
var privateEndpoint_groupId = 'datafactory'


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactory_name
  location: dataFactory_location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpoint_name
  location: dataFactory_location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoint_name
        properties: {
          privateLinkServiceId: dataFactory.id
          groupIds: [
            privateEndpoint_groupId
          ]
        }
      }
    ]
    subnet: {
      id: privateEndpoint_subnetId
    }
    customNetworkInterfaceName: privateEndpoint_NICname
  }
}
