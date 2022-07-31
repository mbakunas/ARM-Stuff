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
var vnetRgList = [for vnet in vnets: {
  name: vnet.resourceGroup.name
  tags: vnet.resourceGroup.tags
}]
var uniqueVnetRgList = union(vnetRgList, vnetRgList)  // make sure the list of resource groups is unique
resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in uniqueVnetRgList: {
  name: rg.name
  location: resourceGroup_location
  tags: rg.tags
}]


// vnet and NSGs
@description('VNets and subnets.  The first VNet is the hub.')
module deployVNets 'Modules/VNet.bicep' = [for (vnet, i) in vnets: {
  name: '${deployment().name}-VNet${i}'
  scope: resourceGroup(vnet.resourceGroup.name)
  dependsOn: resourceGroups
  params: {
    vnet_subnets: vnet.subnets
    vnet_AddressSpace: vnet.addressSpace
    vnet_Location: vnet.location
    vnet_Name: vnet.name
  }
}]

// bastion
// assumes same resrouce group as its vnet
// I'm also cheating because I know the AzureBastionSubnet is the 2nd in the array
//  of the first VNet
// TODO: move this logic to services.bicep
//module bastion 'Modules/bastion.bicep' = [for (vnet, i) in vnets: if (contains(vnet.subnets[1], 'serviceBastion')) {
module bastion 'Modules/bastion.bicep' = {
scope: resourceGroup(vnets[0].resourceGroup.name)
  name: '${deployment().name}-Bastion'
  dependsOn: deployVNets
  params: {
    bastion_location: vnets[0].location
    bastion_name: vnets[0].subnets[1].serviceBastion.name
    bastion_vnetName: vnets[0].name
  }
}

// first domain controller

// private dns resolver

// hub member server

// second DC

// spoke member server
