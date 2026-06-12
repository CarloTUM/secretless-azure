targetScope = 'subscription'

@description('Defender for Cloud plans to enable on the subscription')
param plans array = [
  'StorageAccounts'
  'KeyVaults'
  'Containers'
  'Arm'
  'AppServices'
]

@description('Pricing tier for the listed plans')
@allowed([
  'Free'
  'Standard'
])
param tier string = 'Standard'

resource pricing 'Microsoft.Security/pricings@2023-01-01' = [for plan in plans: {
  name: plan
  properties: {
    pricingTier: tier
  }
}]
