@description('Virtual network name')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Address space, e.g. ["10.20.0.0/16"]')
param addressPrefixes array

@description('Subnets: [{ name, addressPrefix, delegations?, privateEndpointNetworkPolicies? }]')
param subnets array

@description('Resource tags')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
        delegations: subnet.?delegations ?? []
      }
    }]
  }
}

@description('Virtual network resource ID')
output vnetId string = vnet.id

@description('Virtual network name')
output vnetName string = vnet.name
