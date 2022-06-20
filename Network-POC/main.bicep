targetScope = 'subscription'


param primaryRegion string = 'eastus2'
param resourceGroupRegion string = deployment().location
param vnets array


// var vnets_temp = [for vnet in vnets: {
//   subnets: vnet.subnets
// }]

// resource groups

// first, get the list of unique resource groups
var RGs = [for vnet in vnets: {
  name: vnet.resourceGroup.name
  tags: vnet.resourceGroup.tags
}]
var uRGs = union(RGs, RGs)

@description('Resource groups for all resources')
resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in uRGs: {
  name: rg.name
  location: resourceGroupRegion
  tags: rg.tags
}]


// VNets

@description('VNets and subnets.  The first VNet is the hub.')
module deployVNets 'Modules/VNet.bicep' = [for (vnet, i) in vnets: {
  name: '${deployment().name}-VNet${i}'
  scope: resourceGroup(vnet.resourceGroup.name)
  dependsOn: resourceGroups
  params: {
    subnets: vnet.subnets
    vnet_AddressSpace: vnet.addressSpace
    vnet_Location: primaryRegion
    vnet_Name: vnet.name
  }
}]

@description('NSGs')
module nsgs 'Modules/NSG.bicep' = [for (vnet, i) in vnets: {
  scope: resourceGroup(vnet.resourceGroup.name)
  name: '${deployment().name}-NSGs-for-VNet${i}'
  dependsOn: deployVNets
  params: {
    nsg_Location: primaryRegion
    nsg_Subnets: vnet.subnets
    nsg_VNet: vnet.name
  }
}]

// route tables



// peer VNets

@description('Spoke to hub peerings')
module hub2SpokePeer 'Modules/VnetPeer.bicep' = [for i in range(1, length(vnets)-1): {
  scope: resourceGroup(vnets[0].resourceGroup.name)  // resource group where the hub VNet lives
  name: '${deployment().name}-Peer-Outbound-${i}'
  dependsOn: nsgs
  params: {
    peer_LocalVnetName: vnets[0].name  // hub VNet is first one deployed
    peer_ForeignVnetName: vnets[i].name
    peer_ForeighVnetResourceGroup: vnets[i].resourceGroup.name
    peer_allowGatewayTransit: false
    peer_useRemoteGateways: false
  }
}]

@description('Hub to spoke peerings')
module spoke2HubPeer 'Modules/VnetPeer.bicep' = [for i in range(1, length(vnets)-1): {
  scope: resourceGroup(vnets[i].resourceGroup.name)  // resource group where the specific spoke VNet lives
  name: '${deployment().name}-Peer-Inbound-${i}'
  dependsOn: nsgs
  params: {
    peer_LocalVnetName: vnets[i].name
    peer_ForeignVnetName: vnets[0].name  // hub VNet is first one deployed
    peer_ForeighVnetResourceGroup: vnets[0].resourceGroup.name
    peer_allowGatewayTransit: false
    peer_useRemoteGateways: false
  }
}]
