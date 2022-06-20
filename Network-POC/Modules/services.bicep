targetScope = 'resourceGroup'

param vnet object

// loop through all the VNet's subnets to see if there are any services to be deployed

// get info about the VNet
// resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
//   name: vnet.name
// }

var vnet_location = reference(resourceId('Microsoft.Network/virtualNetworks', vnet.name)).location

// appGW
module appGW 'appGW.bicep' = [for subnet in vnet.subnets: if (contains(subnet, 'appGWservice')) {
  name: 'appGW-${subnet.name}'
  scope: resourceGroup(vnet.resourceGroup.name)
  params: {
    appGateway_name: subnet.appGWservice.name
    appGateway_backendAddressPools_Name: subnet.appGWservice.backendAddressPoolsName
    appGateway_VNet_Name: vnet.name
    appGateway_location: vnet_location
    appGateway_Subnet_Name: subnet.name
    appGateway_VNet_ResourceGroup: vnet.resourceGroup.Name
  }
}]
