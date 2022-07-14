targetScope = 'resourceGroup'

param azureRegion string = resourceGroup().location

param hubVNet_name string
param hubVNet_addressSpace string
param hubVNet_gwSubnet_addressSpace string
param hubVNet_dcSubnet_name string
param hubVNet_dcSubnet_addressSpace string
param hubVNet_privateEndpointSubnet_name string
param hubVNet_privateEndpointSubnet_addressSpace string

param devSpokeVNet_name string
param devSpokeVNet_addressSpace string
param devSpokeVNet_appGw_name string
param devSpokeVNet_appGw_addressSpace string
param devSpokeVNet_app1subnet_name string
param devSpokeVNet_app1subnet_addressSpace string

param uatSpokeVNet_name string
param uatSpokeVNet_addressSpace string
param uatSpokeVNet_appGw_name string
param uatSpokeVNet_appGw_addressSpace string
param uatSpokeVNet_app1subnet_name string
param uatSpokeVNet_app1subnet_addressSpace string

param prodSpokeVNet_name string
param prodSpokeVNet_addressSpace string
param prodSpokeVNet_appGw_name string
param prodSpokeVNet_appGw_addressSpace string
param prodSpokeVNet_app1subnet_name string
param prodSpokeVNet_app1subnet_addressSpace string

resource hubVNet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: hubVNet_name
  location: azureRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVNet_addressSpace
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: hubVNet_gwSubnet_addressSpace
        }
      }
      {
        name: hubVNet_dcSubnet_name
        properties: {
          addressPrefix: hubVNet_dcSubnet_addressSpace
        }
      }
      {
        name: hubVNet_privateEndpointSubnet_name
        properties: {
          addressPrefix: hubVNet_privateEndpointSubnet_addressSpace
        }
      }
    ]
  }
}

resource devSpokeVNet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: devSpokeVNet_name
  location: azureRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        devSpokeVNet_addressSpace
      ]
    }
    subnets: [
      {
        name: devSpokeVNet_appGw_name
        properties: {
          addressPrefix: devSpokeVNet_appGw_addressSpace
        }
      }
      {
        name: devSpokeVNet_app1subnet_name
        properties: {
          addressPrefix: devSpokeVNet_app1subnet_addressSpace
        }
      }
    ]
  }
}

resource peeringDevSpoke2Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: devSpokeVNet
  name: hubVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: hubVNet.properties.addressSpace.addressPrefixes
    }
  }
}

resource peeringHub2DevSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: hubVNet
  name: devSpokeVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: devSpokeVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: devSpokeVNet.properties.addressSpace.addressPrefixes
    }
  }
}

resource uatSpokeVNet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: uatSpokeVNet_name
  location: azureRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        uatSpokeVNet_addressSpace
      ]
    }
    subnets: [
      {
        name: uatSpokeVNet_appGw_name
        properties: {
          addressPrefix: uatSpokeVNet_appGw_addressSpace
        }
      }
      {
        name: uatSpokeVNet_app1subnet_name
        properties: {
          addressPrefix: uatSpokeVNet_app1subnet_addressSpace
        }
      }
    ]
  }
}

resource peeringUatSpoke2Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: uatSpokeVNet
  name: hubVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: hubVNet.properties.addressSpace.addressPrefixes
    }
  }
}

resource peeringUat2DevSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: hubVNet
  name: uatSpokeVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: uatSpokeVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: uatSpokeVNet.properties.addressSpace.addressPrefixes
    }
  }
}

resource prodSpokeVNet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: prodSpokeVNet_name
  location: azureRegion
  properties: {
    addressSpace: {
      addressPrefixes: [
        prodSpokeVNet_addressSpace
      ]
    }
    subnets: [
      {
        name: prodSpokeVNet_appGw_name
        properties: {
          addressPrefix: prodSpokeVNet_appGw_addressSpace
        }
      }
      {
        name: prodSpokeVNet_app1subnet_name
        properties: {
          addressPrefix: prodSpokeVNet_app1subnet_addressSpace
        }
      }
    ]
  }
}

resource peeringProdSpoke2Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: prodSpokeVNet
  name: hubVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: hubVNet.properties.addressSpace.addressPrefixes
    }
  }
}

resource peeringProd2DevSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: hubVNet
  name: prodSpokeVNet.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: prodSpokeVNet.id
    }
    remoteAddressSpace: {
      addressPrefixes: prodSpokeVNet.properties.addressSpace.addressPrefixes
    }
  }
}
