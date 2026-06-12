@description('Private endpoint name')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Subnet resource ID the private endpoint is placed in')
param subnetId string

@description('Resource ID of the target service (vault, storage account, registry, ...)')
param targetResourceId string

@description('Sub-resource / group ID, e.g. vault, blob, registry')
param groupId string

@description('Private DNS zone ID to register the endpoint A record in (empty = none)')
param privateDnsZoneId string = ''

@description('Resource tags')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (!empty(privateDnsZoneId)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: groupId
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('Private endpoint resource ID')
output privateEndpointId string = privateEndpoint.id
