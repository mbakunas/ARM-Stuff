targetScope = 'resourceGroup'

param nsgName string
param nsgRuleSet array
param subnetAddressSpace string

var destinationAddressPrefix = {
  destinationAddressPrefix: subnetAddressSpace
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-07-01' existing = {
  name: nsgName
}

resource nsgRules 'Microsoft.Network/networkSecurityGroups/securityRules@2022-07-01' = [for rule in nsgRuleSet: {
  name: rule.name
  parent: networkSecurityGroup
  properties: union(rule.properties, destinationAddressPrefix)
}]
