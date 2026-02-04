# ✅ CHECKLIST PRODUCTION - AZURE API MANAGEMENT

## 🎯 ACTIONS OBLIGATOIRES AVANT PRODUCTION

### 1. Sécurité réseau - VNet (CRITIQUE)

**Fichier:** `infra/main.tf`

```hcl
# Ajouter avant les ressources APIM

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-api-portal-prod-frc"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  
  tags = var.tags
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = "snet-apim"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Modifier APIM Premium
resource "azurerm_api_management" "apim_premium" {
  # ...configs existantes...
  virtual_network_type = "Internal"  # ou "External"
  
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }
}
```

---

### 2. Azure Key Vault (CRITIQUE)

**Fichiers:** `infra/main.tf`, `infra/variables.tf`

```hcl
# Ajouter dans main.tf

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "kv-api-portal-prod-1161"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [var.admin_ip]
    virtual_network_subnet_ids = [azurerm_subnet.apim_subnet.id]
  }
  
  tags = var.tags
}

# Stocker l'instrumentation key
resource "azurerm_key_vault_secret" "appi_key" {
  name         = "appi-instrumentation-key"
  value        = azurerm_application_insights.appi.instrumentation_key
  key_vault_id = azurerm_key_vault.kv.id
}

# Managed Identity pour APIM
resource "azurerm_api_management" "apim_premium" {
  # ...configs existantes...
  
  identity {
    type = "SystemAssigned"
  }
}

# RBAC pour que APIM lise Key Vault
resource "azurerm_role_assignment" "apim_kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.apim_premium.identity[0].principal_id
}
```

**Variables à ajouter:**
```hcl
# Dans variables.tf
variable "admin_ip" {
  description = "IP administrateur pour Key Vault"
  type        = string
}
```

---

### 3. Multi-région (CRITIQUE)

**Fichier:** `infra/main.tf`

```hcl
# Modifier APIM Premium
resource "azurerm_api_management" "apim_premium" {
  # ...configs existantes...
  
  # Ajouter région secondaire
  additional_location {
    location = "westeurope"
    capacity = 1
    zones    = ["1", "2", "3"]
    
    virtual_network_configuration {
      subnet_id = azurerm_subnet.apim_subnet_westeurope.id
    }
  }
}

# Créer subnet dans West Europe
resource "azurerm_subnet" "apim_subnet_westeurope" {
  name                 = "snet-apim-westeurope"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_westeurope.name
  address_prefixes     = ["10.1.1.0/24"]
}
```

---

### 4. Backup automatique (CRITIQUE)

**Fichier:** Nouveau `scripts/backup-apim.ps1`

```powershell
#Requires -Version 7.0

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-api-portal-prod",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimName = "apim-premium-prod-1161",
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName = "stapimbackup$(Get-Date -Format 'yyyyMMdd')"
)

$ErrorActionPreference = "Stop"

# Créer storage account si n'existe pas
$sa = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName 2>$null
if (-not $sa) {
    az storage account create `
        --name $StorageAccountName `
        --resource-group $ResourceGroupName `
        --location francecentral `
        --sku Standard_GRS `
        --kind StorageV2
}

# Créer container
az storage container create `
    --name apim-backups `
    --account-name $StorageAccountName

# Backup APIM
$backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
az apim backup create `
    --resource-group $ResourceGroupName `
    --service-name $ApimName `
    --storage-account-name $StorageAccountName `
    --storage-account-container apim-backups `
    --backup-name $backupName

Write-Host "✅ Backup créé: $backupName" -ForegroundColor Green
```

**Automatisation avec Azure Automation:**
```hcl
# Dans main.tf
resource "azurerm_automation_account" "aa" {
  name                = "aa-api-portal-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
  
  tags = var.tags
}

resource "azurerm_automation_schedule" "daily_backup" {
  name                    = "DailyAPIMBackup"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  frequency               = "Day"
  interval                = 1
  start_time              = timeadd(timestamp(), "24h")  # Démarre demain à 02:00 UTC
}
```

---

### 5. Availability Zones (IMPORTANT)

**Fichier:** `infra/main.tf`

```hcl
resource "azurerm_api_management" "apim_premium" {
  # ...configs existantes...
  zones = ["1", "2", "3"]  # Distribuer sur 3 zones
}
```

---

### 6. RBAC (IMPORTANT)

**Fichier:** `infra/main.tf`

```hcl
# Variables pour les principaux
variable "devops_team_principal_id" {
  description = "Principal ID de l'équipe DevOps"
  type        = string
}

variable "developers_group_principal_id" {
  description = "Principal ID du groupe développeurs"
  type        = string
}

# RBAC pour APIM
resource "azurerm_role_assignment" "apim_contributor" {
  scope                = azurerm_api_management.apim_premium.id
  role_definition_name = "API Management Service Contributor"
  principal_id         = var.devops_team_principal_id
}

resource "azurerm_role_assignment" "apim_reader" {
  scope                = azurerm_api_management.apim_premium.id
  role_definition_name = "API Management Service Reader"
  principal_id         = var.developers_group_principal_id
}

# RBAC pour Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.devops_team_principal_id
}
```

---

### 7. Optimisation monitoring (RECOMMANDÉ)

**Fichier:** `infra/main.tf`, `infra/variables.tf`

```hcl
# Dans variables.tf
variable "sampling_percentage" {
  description = "Pourcentage de sampling Application Insights"
  type        = number
  default     = 10.0  # Production: 10%, Dev: 100%
}

variable "environment" {
  description = "Environnement (dev, prod)"
  type        = string
  default     = "prod"
}

# Dans main.tf - Diagnostics APIM
resource "azurerm_api_management_diagnostic" "apim_premium_diag" {
  # ...
  sampling_percentage = var.sampling_percentage
}
```

---

### 8. WAF - Web Application Firewall (RECOMMANDÉ)

**Fichier:** `infra/main.tf`

```hcl
# Public IP pour Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-api-portal-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.tags
}

# Application Gateway avec WAF
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-api-portal-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }
  
  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }
  
  frontend_port {
    name = "https-port"
    port = 443
  }
  
  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }
  
  backend_address_pool {
    name  = "apim-backend-pool"
    fqdns = [azurerm_api_management.apim_premium.gateway_url]
  }
  
  backend_http_settings {
    name                  = "apim-backend-https"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }
  
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
  }
  
  request_routing_rule {
    name                       = "apim-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "apim-backend-pool"
    backend_http_settings_name = "apim-backend-https"
    priority                   = 100
  }
  
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
  
  tags = var.tags
}
```

---

## 📋 CHECKLIST FINALE

Cocher avant mise en production:

### Obligatoire
- [ ] VNet configuré (Internal ou External)
- [ ] Azure Key Vault déployé et secrets migrés
- [ ] Multi-région configuré (min 2 régions)
- [ ] Availability Zones activées
- [ ] Backup automatique quotidien
- [ ] RBAC configuré pour équipes
- [ ] Monitoring optimisé (sampling 5-20%)
- [ ] Backend Terraform activé (Azure Storage)
- [ ] Documentation mise à jour

### Recommandé
- [ ] WAF (Application Gateway)
- [ ] DDoS Protection Standard
- [ ] Azure Policy pour gouvernance
- [ ] OAuth 2.0 / OpenID Connect
- [ ] Rate limiting par produit
- [ ] IP filtering
- [ ] Tests de charge validés
- [ ] DR Plan documenté
