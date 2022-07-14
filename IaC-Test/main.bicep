targetScope = 'resourceGroup'

param storageAccount_name string
param storageAccount_azureRegion string
param storageAccount_skuName string
param storageAccount_accountKind string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccount_name
  location: storageAccount_azureRegion
  sku: {
    name: storageAccount_skuName
  }
  kind: storageAccount_accountKind
}
