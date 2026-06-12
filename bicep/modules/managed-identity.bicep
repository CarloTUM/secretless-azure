@description('Name of the user-assigned managed identity')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

@description('Resource ID of the identity')
output identityId string = identity.id

@description('Principal (object) ID of the identity')
output principalId string = identity.properties.principalId

@description('Client ID of the identity')
output clientId string = identity.properties.clientId
