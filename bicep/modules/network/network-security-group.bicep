@description('Network security group name')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Security rules: [{ name, properties: { priority, direction, access, protocol, ... } }]. Empty keeps only the Azure default rules (which already deny inbound from the Internet).')
param securityRules array = []

@description('Resource tags')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

@description('Network security group resource ID')
output nsgId string = nsg.id

@description('Network security group name')
output nsgName string = nsg.name
