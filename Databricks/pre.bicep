targetScope = 'subscription'

param resourceGroup_name string
param resourceGroup_location string

param vnetName string
param vnetAddressSpace string
param subnetBastionAddressSpace string
param subnetPrivateLinkName string = 'PrivateLink'
param subnetPrivateLinkAddressSpace string
param subnet1Name string = 'CorpNet'
param subnet1AddressSpace string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroup_name
  location: resourceGroup_location
}

module prerequisites 'Modules/datbricks-pre-network.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-prerequisites'
  params: {
    vnetLocation: resourceGroup_location
    vnetName: vnetName
    vnetAddressSpace: vnetAddressSpace
    subnetBastionAddressSpace: subnetBastionAddressSpace
    subnetPrivateLinkName: subnetPrivateLinkName
    subnetPrivateLinkAddressSpace: subnetPrivateLinkAddressSpace
    subnet1Name: subnet1Name
    subnet1AddressSpace: subnet1AddressSpace
  }
} 
