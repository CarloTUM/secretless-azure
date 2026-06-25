@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment: dev or prod')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Short prefix for the globally unique key vault name, e.g. company or project abbreviation')
@minLength(2)
@maxLength(8)
param namePrefix string

@description('VNet address space')
param vnetAddressPrefixes array = [
  '10.20.0.0/16'
]

@description('Address prefix for the private endpoint subnet')
param privateEndpointSubnetPrefix string = '10.20.0.0/24'

@description('Address prefix for the workload subnet')
param workloadSubnetPrefix string = '10.20.1.0/24'

@description('Allow public network access on the key vault (false = private endpoint only)')
param allowPublicNetworkAccess bool = false

@description('Enable Microsoft Defender for Cloud plans on the subscription')
param enableDefenderForCloud bool = false

@description('Defender for Cloud plans to enable when enableDefenderForCloud = true')
param defenderPlans array = [
  'KeyVaults'
  'Arm'
  'AppServices'
]

@description('Log Analytics retention in days')
@minValue(30)
@maxValue(730)
param logRetentionDays int = 90

@description('Daily Log Analytics ingestion cap in GB (-1 = no cap). Use a low value in dev to bound cost.')
param logDailyQuotaGb int = -1

@description('Enable purge protection on the key vault (recommended for prod, cannot be disabled later)')
param kvPurgeProtection bool = true

@description('Resource tags')
param tags object = {}

var publicAccess = allowPublicNetworkAccess ? 'Enabled' : 'Disabled'
var peSubnetId = '${network.outputs.vnetId}/subnets/private-endpoints'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

module law '../../modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: '${environment}-law-platform'
    location: location
    retentionDays: logRetentionDays
    dailyQuotaGb: logDailyQuotaGb
    tags: tags
  }
}

module peNsg '../../modules/network/network-security-group.bicep' = {
  name: 'privateEndpointsNsg'
  params: {
    name: '${environment}-nsg-private-endpoints'
    location: location
    tags: tags
  }
}

module workloadNsg '../../modules/network/network-security-group.bicep' = {
  name: 'workloadNsg'
  params: {
    name: '${environment}-nsg-workload'
    location: location
    securityRules: [
      {
        name: 'DenyInboundFromInternet'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
    tags: tags
  }
}

module network '../../modules/network/virtual-network.bicep' = {
  name: 'network'
  params: {
    name: '${environment}-vnet-platform'
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnets: [
      {
        name: 'private-endpoints'
        addressPrefix: privateEndpointSubnetPrefix
        networkSecurityGroupId: peNsg.outputs.nsgId
      }
      {
        name: 'workload'
        addressPrefix: workloadSubnetPrefix
        networkSecurityGroupId: workloadNsg.outputs.nsgId
      }
    ]
    tags: tags
  }
}

module vaultDns '../../modules/network/private-dns-zone.bicep' = {
  name: 'vaultDnsZone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    vnetId: network.outputs.vnetId
    tags: tags
  }
}

module kv '../../modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    name: '${namePrefix}-${environment}-kv'
    location: location
    enablePurgeProtection: kvPurgeProtection
    publicNetworkAccess: publicAccess
    logAnalyticsWorkspaceId: law.outputs.workspaceId
    tags: tags
  }
}

module kvPe '../../modules/network/private-endpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  params: {
    name: '${environment}-pe-kv'
    location: location
    subnetId: peSubnetId
    targetResourceId: kv.outputs.vaultId
    groupId: 'vault'
    privateDnsZoneId: vaultDns.outputs.zoneId
    tags: tags
  }
}

module identity '../../modules/managed-identity.bicep' = {
  name: 'platformIdentity'
  params: {
    name: '${environment}-id-platform'
    location: location
    tags: tags
  }
}

module kvSecretsUser '../../modules/security/role-assignment.bicep' = {
  name: 'identityKvSecretsUser'
  params: {
    principalId: identity.outputs.principalId
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

module defender '../../modules/security/defender-for-cloud.bicep' = if (enableDefenderForCloud) {
  name: 'defenderForCloud'
  scope: subscription()
  params: {
    plans: defenderPlans
    tier: 'Standard'
  }
}

output logAnalyticsWorkspaceId string = law.outputs.workspaceId
output vnetId string = network.outputs.vnetId
output keyVaultName string = kv.outputs.vaultName
output keyVaultUri string = kv.outputs.vaultUri
output platformIdentityId string = identity.outputs.identityId
output platformIdentityClientId string = identity.outputs.clientId
output platformIdentityPrincipalId string = identity.outputs.principalId
