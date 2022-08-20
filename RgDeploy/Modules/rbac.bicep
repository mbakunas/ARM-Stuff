/*

    This template assignes the specified user the specified RBAC role on the resource group

*/

targetScope = 'resourceGroup'


@description('The object ID of the user to whom to assign permissions')
param rbac_userId string

@description('The ID of the role to be assigned')
param rbac_roleId string

var rbac_name = guid(resourceGroup().id, rbac_userId, rbac_roleId)  // create a unique identifier based on the RG, the user, and the role

resource rgRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: rbac_name
  scope: resourceGroup()
  properties: {
    principalId: rbac_userId
    roleDefinitionId: rbac_roleId
  }
} 
