targetScope = 'resourceGroup'
// VNet
param vnet_Name string
param vnet_AddressSpace string
param vnet_Location string

// Subnets
param subnet_subnet1_Name string  // Assumes app gateway subnet
param subnet_subnet1_AddressSpace string
param subnet_subnet2_Name string
param subnet_subnet2_AddressSpace string

// NSGs
param nsg_subnet1_Name string
param nsg_subnet2_Name string

// Route Table
param routeTable_Id string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnet_Name
  location: vnet_Location
  tags: resourceGroup().tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_AddressSpace
      ]
    }
    subnets: [
      {
        name: subnet_subnet1_Name
        properties: {
          addressPrefix: subnet_subnet1_AddressSpace
          networkSecurityGroup: {
            id: networkSecurityGroup1.id
          }
          routeTable: {
            id: routeTable_Id
          }
        }
      }
      {
        name: subnet_subnet2_Name
        properties: {
          addressPrefix: subnet_subnet2_AddressSpace
          networkSecurityGroup: {
            id: networkSecurityGroup2.id
          }
          routeTable: {
            id: routeTable_Id
          }
        }
      }
    ]
  }
}

resource networkSecurityGroup1 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg_subnet1_Name
  location: vnet_Location
  properties: {
    securityRules: [
      {
        //NSG rule necessary to attach app gateway to this subnet
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
          //sourcePortRanges: []
          //destinationPortRanges: []
          //sourceAddressPrefixes: []
          //destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource networkSecurityGroup2 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg_subnet2_Name
  location: vnet_Location
  properties: {
    securityRules: []
  }
}

output VNet_Id string = virtualNetwork.id
