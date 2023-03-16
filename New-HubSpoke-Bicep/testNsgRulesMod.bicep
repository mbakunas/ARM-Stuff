var nsgRuleSets = {
    DomainControllers: [
        {
            name: 'W32Time'
            properties: {
                protocol: 'udp'
                sourcePortRange: '49152-65535'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationPortRange: '123'
                destinationAddressPrefix: '*'
                access: 'Allow'
                direction: 'Inbound'
                priority: 1000
            }
        }
        {
            name: 'LDAP'
            properties: {
                protocol: '*'
                sourcePortRange: '49152-65535'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationPortRange: '389'
                destinationAddressPrefix: '*'
                access: 'Allow'
                direction: 'Inbound'
                priority: 1010
            }
        }
    ]

}

var subnetCidr = '10.1.0.0/24'
var destinationAddressPrefix = {
  destinationAddressPrefix: subnetCidr
}

var nsgRules = [for rule in nsgRuleSets.DomainControllers: {
  name: rule.name
  properties: union(rule.properties, destinationAddressPrefix)
}]

output rules array = nsgRules
output destinationAddressPrefix object = destinationAddressPrefix
