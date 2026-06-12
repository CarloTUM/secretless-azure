@description('Private DNS zone name, e.g. privatelink.vaultcore.azure.net')
param name string

@description('Virtual network ID the zone is linked to')
param vnetId string

@description('Resource tags')
param tags object = {}

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: zone
  name: '${replace(name, '.', '-')}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

@description('Private DNS zone resource ID')
output zoneId string = zone.id

@description('Private DNS zone name')
output zoneName string = zone.name
