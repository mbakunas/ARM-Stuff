targetScope = 'resourceGroup'

param dataLake_name string
param dataLake_azureRegion string
param dataLake_skuName string
param dataLake_accountKind string

resource dataLake 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: dataLake_name
  location: dataLake_azureRegion
  sku: {
    name: dataLake_skuName
  }
  kind: dataLake_accountKind
}
