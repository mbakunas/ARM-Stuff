/*

    This template assignes the specified user the specified RBAC role on the resource group

*/

targetScope = 'resourceGroup'

param rbac_userId string
param rbac_roleId string

var rbac_name = guid(resourceGroup().id, rbac_userId, rbac_roleId)

resource rgRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: rbac_name
  scope: resourceGroup()
  properties: {
    principalId: rbac_userId
    roleDefinitionId: rbac_roleId
  }
} 
