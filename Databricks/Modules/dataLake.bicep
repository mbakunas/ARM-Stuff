targetScope = 'resourceGroup'

param storageAccount_name string
param storageAccount_location string

param storageAccount_kind string = 'StorageV2'
param storageAccount_skuName string = 'Standard_ZRS'
param storageAccount_accessTier string = 'Hot'
param storageAccount_minimumTlsVersion string = 'TLS1_2'
param storageAccount_supportsHttpsTrafficOnly bool = true
param storageAccount_publicNetworkAccess string = 'Disabled'
param storageAccount_allowBlobPublicAccess bool = false
param storageAccount_allowSharedKeyAccess bool = false
param storageAccount_defaultOAuth bool = true
param storageAccount_isHnsEnabled bool = true 
param storageAccount_keySource string = 'Microsoft.Storage'
param storageAccount_encryptionEnabled bool = true
param storageAccount_requireInfrastructureEncryption bool = true



resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccount_name
  location: storageAccount_location
  tags: resourceGroup().tags

  kind: storageAccount_kind
  sku: {
    name:  storageAccount_skuName
  }
  properties: {
    accessTier: storageAccount_accessTier
    minimumTlsVersion: storageAccount_minimumTlsVersion
    supportsHttpsTrafficOnly: storageAccount_supportsHttpsTrafficOnly
    publicNetworkAccess: storageAccount_publicNetworkAccess
    allowBlobPublicAccess: storageAccount_allowBlobPublicAccess
    allowSharedKeyAccess: storageAccount_allowSharedKeyAccess
    defaultToOAuthAuthentication: storageAccount_defaultOAuth
    isHnsEnabled: storageAccount_isHnsEnabled
    encryption: {
      keySource: storageAccount_keySource

      // the following parameters can only be configured at deploy time, so this
      // template is not idempotent
      services: {
        blob: {
          enabled: storageAccount_encryptionEnabled
          keyType: 'Account'
        }
        file: {
          enabled: storageAccount_encryptionEnabled
          keyType: 'Account'
        }
        table: {
          enabled: storageAccount_encryptionEnabled
          keyType: 'Account'
        }
        queue: {
          enabled: storageAccount_encryptionEnabled
          keyType: 'Account'
        }
      }
      requireInfrastructureEncryption: storageAccount_requireInfrastructureEncryption
    }
  }
}

output datalakeID string = storage.id
