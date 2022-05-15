targetScope = 'resourceGroup'

param bastion_VNet_Name string
param bastion_Location string
@allowed([
  'Basic'
  'Standard'
])
param bastion_SKU string = 'Basic'


resource bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: '${bastion_VNet_Name}-Bastion'
  location: bastion_Location
  tags: resourceGroup().tags
  sku: {
    name: bastion_SKU
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', bastion_VNet_Name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${bastion_VNet_Name}-Bastion-IP'
  location: bastion_Location
  tags: resourceGroup().tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
