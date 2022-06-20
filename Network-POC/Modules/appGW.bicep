targetScope = 'resourceGroup'

param appGateway_name string
param appGateway_location string
param appGateway_VNet_Name string
param appGateway_Subnet_Name string
param appGateway_VNet_ResourceGroup string
param appGateway_backendAddressPools_Name string

var gatewayIPConfigurations_Name  = 'appGatewayIpConfig'
var frontendIPConfigurations_Name = 'appGwPublicFrontendIp'
var frontendPorts_Name = 'port_80'
var backendHttpSettingsCollection_Name = 'HTTP'
var httpListeners_Name = 'PublicHTTP'
var requestRoutingRules_Name = 'Public_to_Web'
var requestRoutingRules_Priority = 1000


resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${appGateway_name}-IP'
  location: appGateway_location
  tags: resourceGroup().tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  // Required for appGW v2
    dnsSettings: {
      domainNameLabel: toLower(appGateway_name)
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: appGateway_name
  location: appGateway_location
  tags: resourceGroup().tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: gatewayIPConfigurations_Name
        properties: {
          subnet: {
            id: resourceId(appGateway_VNet_ResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', appGateway_VNet_Name, appGateway_Subnet_Name)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurations_Name
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
        name: frontendPorts_Name
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGateway_backendAddressPools_Name
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsCollection_Name
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
        name: httpListeners_Name
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
        name: requestRoutingRules_Name
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGateway_name, 'PublicHTTP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGateway_name, 'Web')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGateway_name, 'HTTP')
          }
          priority: requestRoutingRules_Priority
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      requestBodyCheck: true
      maxRequestBodySize: 128
      fileUploadLimitInMb: 100
    }
  }
}

// NSG Rules for appGW

// First, get the the subnet into which the appGW will be deployed so we get the NSG
resource appGW_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${appGateway_VNet_Name}/${appGateway_Subnet_Name}'
}

// Next, get the NSG for that subnet so we can add the rules
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' existing = {
  name: appGW_subnet.properties.networkSecurityGroup.name
}

resource nsgRule1 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: nsg
  name: 'Allow_http_https_from_Internet'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '80'
      '443'
    ]
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: appGW_subnet.properties.addressPrefix
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}

resource nsgRule2 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = {
  parent: nsg
  name: 'AppGW_Allow_65200-65535'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '65200-65535'
    sourceAddressPrefix: 'GatewayManager'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 4010
    direction: 'Inbound'    
  }
}

output appGW_Id string = applicationGateway.id
output appGW_fqdn string = publicIPAddress.properties.dnsSettings.fqdn
