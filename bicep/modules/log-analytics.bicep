@description('Log Analytics workspace name')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Retention in days')
@minValue(30)
@maxValue(730)
param retentionDays int = 90

@description('Daily ingestion cap in GB (-1 = no cap)')
param dailyQuotaGb int = -1

@description('Resource tags')
param tags object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: retentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: dailyQuotaGb > 0 ? { dailyQuotaGb: dailyQuotaGb } : null
  }
}

@description('Resource ID of the workspace')
output workspaceId string = law.id

@description('Workspace name')
output workspaceName string = law.name
