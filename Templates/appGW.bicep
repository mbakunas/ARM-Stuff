targetScope = 'resourceGroup'

param appGateway_name string
param appGateway_location string
param appGateway_VNet_Id string
param appGatewau_Subnet_Name string





resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${appGateway_name}-IP'
  location: appGateway_location
  tags: resourceGroup().tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}


resource applicationGateway 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: appGateway_name
  location: appGateway_location
  tags: resourceGroup().tags
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'name'
        properties: {
          subnet: {
            id: resourceId('Reference01', 'Microsoft.Network/virtualNetworks/subnets', appGateway_VNet_Id, appGatewau_Subnet_Name)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'DefaultBackendPool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'HTTP'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'PrivateHTTP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGateway_name, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGateway_name, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'Private_to_DefaultBackendPool'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGateway_name, 'PrivateHTTP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGateway_name, 'DefaultBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGateway_name, 'HTTP')
          }
          priority: 1000
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
  }
}
