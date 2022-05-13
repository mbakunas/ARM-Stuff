targetScope = 'resourceGroup'

param localVNet_Name string
param remoteVNet_Name string
param remoteVNet_Id string
param remoteVNet_AddressSpace string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${localVNet_Name}/${localVNet_Name}_to_${remoteVNet_Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: remoteVNet_Id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        remoteVNet_AddressSpace
      ]
    }
  }
}
