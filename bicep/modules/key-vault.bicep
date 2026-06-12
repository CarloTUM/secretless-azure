@description('Key vault name (3-24 characters, alphanumeric and hyphens, globally unique)')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Days a soft-deleted vault is retained')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection. Cannot be disabled once enabled.')
param enablePurgeProtection bool = true

@description('Public network access. Disabled means the vault is reachable only through a private endpoint.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Log Analytics workspace for audit diagnostics (empty = no diagnostic settings)')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object = {}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'audit-to-law'
  scope: vault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('Key vault name')
output vaultName string = vault.name

@description('Key vault URI, e.g. https://myvault.vault.azure.net/')
output vaultUri string = vault.properties.vaultUri

@description('Key vault resource ID')
output vaultId string = vault.id
