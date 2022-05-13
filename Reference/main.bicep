targetScope = 'subscription'

//Ensure the primary and secondary regions support availability zones
//https://docs.microsoft.com/en-us/azure/availability-zones/az-overview#azure-regions-with-availability-zones
param primaryRegion string = 'eastus2'
param secondaryRegion string = 'centralus'

param networkResourceGroup_Name string
param networkResourceGroup_Tags object

param vmResourceGroup_Name string
param vmResourceGroup_Tags object

// Hub VNet, deployed to the primary Azure region
param hubVnet_Name string
param hubVnet_AddressSpace string
param hubVnet_gatewaySubnet_AddressSpace string
param hubVnet_azureFirewallSubnet_AddressSpace string
param hubVnet_azureBastionSubnet_AddressSpace string
param hubVnet_subnet1_Name string
param hubVnet_subnet1_AddressSpace string
param hubVnet_subnet2_Name string
param hubVnet_subnet2_AddressSpace string

// Spoke 1 VNet, deployed to the primary Azure region
param spoke1Vnet_Name string
param spoke1Vnet_AddressSpace string
param spoke1Vnet_subnet1_Name string
param spoke1Vnet_subnet1_AddressSpace string
param spoke1Vnet_subnet2_Name string
param spoke1Vnet_subnet2_AddressSpace string

// Spoke 2 VNet, deployed to the secondary Azure region
param spoke2Vnet_Name string
param spoke2Vnet_AddressSpace string
param spoke2Vnet_subnet1_Name string
param spoke2Vnet_subnet1_AddressSpace string
param spoke2Vnet_subnet2_Name string
param spoke2Vnet_subnet2_AddressSpace string

// Route tables
param routeTable_PrimaryRegion_name string
param routeTable_SecondaryRegion_name string

var nsgSuffix = '-NSG'


// Resource groups
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkResourceGroup_Name
  location: primaryRegion
  tags: networkResourceGroup_Tags
}

resource vmResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vmResourceGroup_Name
  location: primaryRegion
  tags: vmResourceGroup_Tags
}

// VNets
module hubVNet '../Templates/hubVNet.bicep' = {
  name: '${deployment().name}-HubVNet'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    routeTablePrimary
  ]
  params: {
    vnet_Name: hubVnet_Name
    vnet_AddressSpace: hubVnet_AddressSpace
    vnet_Location: primaryRegion

    subnet_gatewaySubnet_AddressSpace: hubVnet_gatewaySubnet_AddressSpace
    subnet_azureFirewallSubnet_AddressSpace: hubVnet_azureFirewallSubnet_AddressSpace
    subnet_azureBastionSubnet_AddressSpace: hubVnet_azureBastionSubnet_AddressSpace
    subnet_subnet1_Name: hubVnet_subnet1_Name
    subnet_subnet1_AddressSpace: hubVnet_subnet1_AddressSpace
    subnet_subnet2_Name: hubVnet_subnet2_Name
    subnet_subnet2_AddressSpace: hubVnet_subnet2_AddressSpace

    nsg_subnet1_Name: '${hubVnet_subnet1_Name}${nsgSuffix}'
    nsg_subnet2_Name: '${hubVnet_subnet2_Name}${nsgSuffix}'

    routeTable_Id: routeTablePrimary.outputs.routeTable_Id
  }
}

module spoke1VNet '../Templates/spokeVNet.bicep' = {
  name: '${deployment().name}-Spoke1VNet'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    routeTablePrimary
  ]
  params: {
    vnet_Name: spoke1Vnet_Name
    vnet_AddressSpace: spoke1Vnet_AddressSpace
    vnet_Location: primaryRegion

    subnet_subnet1_Name: spoke1Vnet_subnet1_Name
    subnet_subnet1_AddressSpace: spoke1Vnet_subnet1_AddressSpace
    subnet_subnet2_Name: spoke1Vnet_subnet2_Name
    subnet_subnet2_AddressSpace: spoke1Vnet_subnet2_AddressSpace

    nsg_subnet1_Name: '${spoke1Vnet_subnet1_Name}${nsgSuffix}'
    nsg_subnet2_Name: '${spoke1Vnet_subnet2_Name}${nsgSuffix}'

    routeTable_Id: routeTablePrimary.outputs.routeTable_Id
  }
}

module spoke2VNet '../Templates/spokeVNet.bicep' = {
  name: '${deployment().name}-Spoke2VNet'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    routeTableSecondary
  ]
  params: {
    vnet_Name: spoke2Vnet_Name
    vnet_AddressSpace: spoke2Vnet_AddressSpace
    vnet_Location: secondaryRegion

    subnet_subnet1_Name: spoke2Vnet_subnet1_Name
    subnet_subnet1_AddressSpace: spoke2Vnet_subnet1_AddressSpace
    subnet_subnet2_Name: spoke2Vnet_subnet2_Name
    subnet_subnet2_AddressSpace: spoke2Vnet_subnet2_AddressSpace

    nsg_subnet1_Name: '${spoke2Vnet_subnet1_Name}${nsgSuffix}'
    nsg_subnet2_Name: '${spoke2Vnet_subnet2_Name}${nsgSuffix}'

    routeTable_Id: routeTableSecondary.outputs.routeTable_Id
  }
}

// VNet Peerings
module VNetPeerHubSpoke1 '../Templates/VNetPeer.bicep' = {
  name: '${deployment().name}-VNetPeer-Hub-Spoke1'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    hubVNet
    spoke1VNet
  ]
  params: {
    localVNet_Name: hubVnet_Name
    remoteVNet_Name: spoke1Vnet_Name
    remoteVNet_Id: spoke1VNet.outputs.VNet_Id
    remoteVNet_AddressSpace: spoke1Vnet_AddressSpace
  }
}
module VNetPeerSpoke1Hub '../Templates/VNetPeer.bicep' = {
  name: '${deployment().name}-VNetPeer-Spoke1-Hub'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    hubVNet
    spoke1VNet
  ]
  params: {
    localVNet_Name: spoke1Vnet_Name
    remoteVNet_Name: hubVnet_Name
    remoteVNet_Id: hubVNet.outputs.VNet_Id
    remoteVNet_AddressSpace: hubVnet_AddressSpace
  }
}

module VNetPeerHubSpoke2 '../Templates/VNetPeer.bicep' = {
  name: '${deployment().name}-VNetPeer-Hub-Spoke2'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    hubVNet
    spoke2VNet
  ]
  params: {
    localVNet_Name: hubVnet_Name
    remoteVNet_Name: spoke2Vnet_Name
    remoteVNet_Id: spoke2VNet.outputs.VNet_Id
    remoteVNet_AddressSpace: spoke2Vnet_AddressSpace
  }
}
module VNetPeerSpoke2Hub '../Templates/VNetPeer.bicep' = {
  name: '${deployment().name}-VNetPeer-Spoke2-Hub'
  scope: resourceGroup(networkResourceGroup.name)
  dependsOn: [
    hubVNet
    spoke2VNet
  ]
  params: {
    localVNet_Name: spoke2Vnet_Name
    remoteVNet_Name: hubVnet_Name
    remoteVNet_Id: hubVNet.outputs.VNet_Id
    remoteVNet_AddressSpace: hubVnet_AddressSpace
  }
}

// Route Tables
module routeTablePrimary '../Templates/routeTable.bicep' = {
  name: '${deployment().name}-RouteTablePrimary'
  scope: resourceGroup(networkResourceGroup.name)
  params: {
    routeTable_Name: routeTable_PrimaryRegion_name
    routeTable_Location: primaryRegion

  }
}

module routeTableSecondary '../Templates/routeTable.bicep' = {
  name: '${deployment().name}-RouteTableSecondary'
  scope: resourceGroup(networkResourceGroup.name)
  params: {
    routeTable_Name: routeTable_SecondaryRegion_name
    routeTable_Location: secondaryRegion

  }
}
