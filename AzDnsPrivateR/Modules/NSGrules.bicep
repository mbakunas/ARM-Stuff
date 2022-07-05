targetScope = 'resourceGroup'

param nsg_Subnets array


// rules for application gateway
resource appGWnsgRule1 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = [for (subnet, i) in nsg_Subnets: if (contains(subnet, 'appGWservice')) {
  name: contains(subnet, 'nsgName') ? '${subnet.nsgName}/AppGW_Allow_65200-65535' : 'appGWnsgRule1/appGWnsgRule1${i}'  
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
}]

resource appGWnsgRule2 'Microsoft.Network/networkSecurityGroups/securityRules@2021-08-01' = [for (subnet, i) in nsg_Subnets: if (contains(subnet, 'appGWservice')) {
  name: contains(subnet, 'nsgName') ? '${subnet.nsgName}/Allow_http_https_from_Internet' : 'appGWnsgRule2/appGWnsgRule2${i}' 
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '80'
      '443'
    ]
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: subnet.addressSpace
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}]
