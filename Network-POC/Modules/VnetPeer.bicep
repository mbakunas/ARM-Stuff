targetScope = 'resourceGroup'

param peer_LocalVnetName string
param peer_ForeignVnetName string
param peer_ForeighVnetResourceGroup string
param peer_allowGatewayTransit bool
param peer_useRemoteGateways bool

resource foreignVNet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: peer_ForeignVnetName
  scope: resourceGroup(peer_ForeighVnetResourceGroup)
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${peer_LocalVnetName}/${peer_ForeignVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: peer_allowGatewayTransit
    useRemoteGateways: peer_useRemoteGateways
    remoteVirtualNetwork: {
      id: foreignVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: foreignVNet.properties.addressSpace.addressPrefixes
    }
  }
}

