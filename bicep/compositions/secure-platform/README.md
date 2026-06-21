# secure-platform

## Purpose

Deploys a **secure baseline platform**, once per environment (dev / prod). Everything is
private and identity-only by default: no public endpoints, no account keys, no secrets in
the templates.

- Log Analytics workspace (`<env>-law-platform`), 90+ day retention
- Virtual network (`<env>-vnet-platform`) with a `private-endpoints` and a `workload` subnet,
  plus the private DNS zone for Key Vault, linked to the VNet
- A network security group per subnet (`<env>-nsg-private-endpoints`, `<env>-nsg-workload`);
  the workload NSG denies inbound traffic from the Internet on top of the default rules
- Key Vault (`<namePrefix>-<env>-kv`): RBAC, soft delete, purge protection, `Deny` network ACL,
  public access off, reachable only through a private endpoint
- User-assigned managed identity (`<env>-id-platform`) with `Key Vault Secrets User`
- Audit/diagnostic settings on the vault to the workspace
- Optional Microsoft Defender for Cloud plans on the subscription

---

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `environment` | string | (required) | `dev` or `prod` |
| `namePrefix` | string | (required) | Short prefix (2-8 chars) for the globally unique vault name |
| `location` | string | `resourceGroup().location` | Azure region |
| `vnetAddressPrefixes` | array | `['10.20.0.0/16']` | VNet address space |
| `privateEndpointSubnetPrefix` | string | `'10.20.0.0/24'` | Private endpoint subnet |
| `workloadSubnetPrefix` | string | `'10.20.1.0/24'` | Workload subnet |
| `allowPublicNetworkAccess` | bool | `false` | `true` relaxes the vault to public access |
| `enableDefenderForCloud` | bool | `false` | Enable Defender plans on the subscription |
| `defenderPlans` | array | KeyVaults, Arm, AppServices | Plans to enable |
| `logRetentionDays` | int | `90` | Log Analytics retention |
| `kvPurgeProtection` | bool | `true` | Key vault purge protection (cannot be disabled later) |
| `tags` | object | `{}` | Tags for all resources |

Per-environment values live in `main.dev.parameters.json` and `main.prod.parameters.json`.

> The deploying service connection needs `Contributor` plus `Role Based Access Control
> Administrator` (the composition creates a role assignment). Enabling Defender additionally
> requires `Security Admin` on the subscription, since `Microsoft.Security/pricings` is
> deployed at subscription scope.

---

## Deployment

Entry-point pipelines: `pipelines/deployments/platform-dev.yml` and `platform-prod.yml`
(security scan → resource group → what-if validate → deploy).
