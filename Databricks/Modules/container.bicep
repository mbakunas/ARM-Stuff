targetScope = 'resourceGroup'

param storageAccountName string


resource storage 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' existing = {
  name: '${storageAccountName}/default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: storage
  name: 'metastore'
}
