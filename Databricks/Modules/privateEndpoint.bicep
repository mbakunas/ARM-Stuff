targetScope = 'resourceGroup'

param privateEndpointName string
param privateLinkServiceId string
param groupId string
param location string
param subnetId string
param privateDnsZoneId string

var privateEndpointConnectionName = '${privateEndpointName}-${uniqueString(privateLinkServiceId, groupId, subnetId)}'


resource endpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointConnectionName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
    customNetworkInterfaceName: '${privateEndpointName}-NIC'
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: endpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output nicId string = endpoint.properties.networkInterfaces[0].id
