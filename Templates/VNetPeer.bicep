targetScope = 'resourceGroup'

param localVNet_Name string
param localVNet_isHub bool
param remoteVNet_Name string
param remoteVNet_Id string
param remoteVNet_AddressSpace string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${localVNet_Name}/${localVNet_Name}_to_${remoteVNet_Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: localVNet_isHub ? false : true
    useRemoteGateways: localVNet_isHub ? true : false
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
