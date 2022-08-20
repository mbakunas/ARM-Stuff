/*

    This template deploys a resource group and assigns
    the specified user Owner on the deployed RG

*/

targetScope = 'subscription'

@description('Name of the resource group to be deployed')
param rg_name string

/*
@description('Azure region where the resource group will be deployed')
param rg_location string
*/

@description('Resouce tags to be applied to the resource grouop')
param rg_tags object


@description('The object ID of the user to whom to assign permissions')
param rgRbac_userId string


var ownerRoleDefinitionId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rg_name
  location: deployment().location
  tags: rg_tags
}

module rbac 'Modules/rbac.bicep' = {
  scope: rg
  name: '${deployment().name}-RBAC'
  params: {
    rbac_roleId: ownerRoleDefinitionId
    rbac_userId: rgRbac_userId
  }
}
