targetScope = 'resourceGroup'

// VNet
param vnet_Name string
param vnet_AddressSpace string
param vnet_Location string

// Subnets
param subnet_gatewaySubnet_AddressSpace string
param subnet_azureFirewallSubnet_AddressSpace string
param subnet_azureBastionSubnet_AddressSpace string
param subnet_subnet1_Name string
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
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_AddressSpace
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: subnet_gatewaySubnet_AddressSpace
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: subnet_azureFirewallSubnet_AddressSpace
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: subnet_azureBastionSubnet_AddressSpace
        }
      }
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
    securityRules: []
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
