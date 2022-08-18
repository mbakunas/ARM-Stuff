/*

    Template to deploy an empty Azure Data Factory instance connected to the
    specified VNet/subnet via a private endpoint.  This template does NOT
    configure a source control repo.

*/

targetScope = 'resourceGroup'

@description('Name of the Data Factory instance')
param dataFactory_name string

@description('Azure region where the Data Factory instance will be deployed')
param dataFactory_location string


@description('Name of the VNet where the private endpoint will be attached')
param privateEndpoint_vnetName string

@description('Name of the subnet to which the private endpoint will be attached')
param privateEndpoint_subnetName string

@description('Name of the resource group where the private endpoint VNet resides')
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
    publicNetworkAccess: 'Disabled'  // set to disabled to use the private endpoint
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
