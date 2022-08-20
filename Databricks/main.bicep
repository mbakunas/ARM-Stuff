/*

  Template that deploys a data bricks workspace with a private endpoint

  Prior to deployment, a resource group for the Data Bricks resources deployed
  within the workspace (e.g., compute clusters) needs to be created

*/


targetScope = 'resourceGroup'

param virtualNetworks_Spoke_IAM_Dev_NON_PROD_EastUS_externalid string = '/subscriptions/49f7b216-0dd7-411f-b7fb-ad3fa4ba76af/resourceGroups/rg_infra_iam_dev_nonprod_eastus/providers/Microsoft.Network/virtualNetworks/Spoke_IAM_Dev_NON_PROD_EastUS'

param workspace_name string  //iam-dev-databricks-ws
param workspace_location string
param workspace_managedRgId string // the resource id of the databricks managed RG
param workspace_VNetName string
param workspace_subnetName string
param workspace_vnetRg string
param workspace_principalId string //'9a74af6f-d153-4348-988a-e2672920bee9' who is this?

param workspaceParams_customPrivateSubnetName string //'SN-EXDBKS-100.74.144.0-21'


param workspace_storageName string
param workspace_storageSku string
param workspace_storageKind string

param storage_peVNetName string
param storage_peSubnetName string
param storage_peVNetRg string


var storage_peName = '${workspace_name}-storage'
var storage_peGroupId = 'blob'
var storage_peSubnetId = resourceId(storage_peVNetRg, 'Microsoft.Network/virtualNetworks/subnets', storage_peVNetName, storage_peSubnetName)
var storage_peNicName = '${storage_peName}-NIC'
var workspaceParams_customVirtualNetworkId = resourceId(workspace_vnetRg, 'Microsoft.Network/virtualNetworks/subnets', workspace_VNetName, workspace_subnetName)
var contributorRoleDefId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'


// UDR


// storage account + private endpoint
resource workspaceStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: workspace_storageName
  location: workspace_location
  sku: {
    name: workspace_storageSku
  }
  kind: workspace_storageKind
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: storage_peName
  location: workspace_location
  properties: {
    privateLinkServiceConnections: [
      {
        name: storage_peName
        properties: {
          privateLinkServiceId: workspaceStorage.id
          groupIds: [
            storage_peGroupId
          ]
        }
      }
    ]
    subnet: {
      id: storage_peSubnetId
    }
    customNetworkInterfaceName: storage_peNicName
  }
}


// databricks workspace
resource workspace 'Microsoft.Databricks/workspaces@2022-04-01-preview' = {
  name: workspace_name
  location: workspace_location
  sku: {
    name: 'premium'
  }
  properties: {
    authorizations: [
      {
        principalId: workspace_principalId
        roleDefinitionId:  contributorRoleDefId
      }
    ]
    managedResourceGroupId: workspace_managedRgId
    parameters: {
      customPrivateSubnetName: {
        value: workspaceParams_customPrivateSubnetName
      }
      customVirtualNetworkId: {
        value: workspaceParams_customVirtualNetworkId
      }
      enableNoPublicIp: {
        value: true
      }
      prepareEncryption: {
        value: false
      }
      requireInfrastructureEncryption: {
        value: true
      }
      storageAccountName: {
        value: workspaceStorage.name
      }
      storageAccountSkuName: {
        value: workspace_storageSku
      }
      vnetAddressPrefix: {
        value: '10.139'         // assume 'managed VNet' is not connected to any other VNet, so it doesn't matter what we put here
      }
      
    }
  }
}



// subnet



// private endpoint


