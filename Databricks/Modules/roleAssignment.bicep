targetScope = 'resourceGroup'

param roleDefinitionId string
param principalId string
param dataLakeName string

var rbac_assignmentName = guid(principalId, dataLakeName)

resource dataLake 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: dataLakeName
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: rbac_assignmentName
  scope: dataLake
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
