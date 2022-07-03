targetScope = 'subscription'

param resourceGroup_location string // Azure region for all deployed resource groups

param dnsResourceGroup_name string
param dnsResourceGroup_tags object

param vnets array


// resrouce groups
// dns resource group
resource dnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: dnsResourceGroup_name
  location: resourceGroup_location
  tags: dnsResourceGroup_tags
}

// vnet resource group(s)
var RgList = [for vnet in vnets: {
  name: vnet.resourceGroup.name
  tags: vnet.resourceGroup.tags
}]
var uniqueRgList = union(RgList, RgList)  // make sure the list of resource groups is unique
resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in uniqueRgList: {
  name: rg.name
  location: resourceGroup_location
  tags: rg.tags
}]


// vnet
@description('VNets and subnets.  The first VNet is the hub.')
module deployVNets 'Modules/VNet.bicep' = [for (vnet, i) in vnets: {
  name: '${deployment().name}-VNet${i}'
  scope: resourceGroup(vnet.resourceGroup.name)
  dependsOn: resourceGroups
  params: {
    subnets: vnet.subnets
    vnet_AddressSpace: vnet.addressSpace
    vnet_Location: vnet.location
    vnet_Name: vnet.name
  }
}]

@description('NSGs')
module nsgs 'Modules/NSG.bicep' = [for (vnet, i) in vnets: {
  scope: resourceGroup(vnet.resourceGroup.name)
  name: '${deployment().name}-NSGs-for-VNet${i}'
  dependsOn: deployVNets
  params: {
    nsg_Location: vnet.location
    nsg_Subnets: vnet.subnets
    nsg_VNet: vnet.name
  }
}]

// bastion

// domain controllers

// private dns resolver

// member servers
