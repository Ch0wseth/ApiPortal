# 📚 SOLUTION TECHNIQUE - PLATEFORME API MANAGEMENT AVEC API CENTER

**Date de création:** 2 février 2026  
**Projet:** API Portal - POC API Management Centralisé  
**Version:** 1.0.1  
**Auteur:** Équipe Infrastructure  
**Resource Group:** rg-api-portal-dev  
**Région Azure:** France Central

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble du projet](#1-vue-densemble-du-projet)
2. [Architecture technique](#2-architecture-technique)
3. [Infrastructure as Code (Terraform)](#3-infrastructure-as-code-terraform)
4. [Azure API Management](#4-azure-api-management)
5. [Azure API Center](#5-azure-api-center)
6. [Workspaces APIM](#6-workspaces-apim)
7. [APIs déployées](#7-apis-déployées)
8. [Monitoring et observabilité](#8-monitoring-et-observabilité)
9. [Sécurité et gouvernance](#9-sécurité-et-gouvernance)
10. [Portails développeur](#10-portails-développeur)
11. [Scripts d'automatisation](#11-scripts-dautomatisation)
12. [Guide d'utilisation](#12-guide-dutilisation)
13. [Troubleshooting](#13-troubleshooting)
14. [Bonnes pratiques](#14-bonnes-pratiques)
15. [Roadmap et évolutions](#15-roadmap-et-évolutions)
16. [Références et documentation](#16-références-et-documentation)

---

## 1. VUE D'ENSEMBLE DU PROJET

### 1.1 Objectif du projet

Ce projet vise à démontrer une **plateforme API Management centralisée** utilisant Azure API Management Premium avec workspaces, couplée à Azure API Center pour la gouvernance et la découverte des APIs.

#### Objectifs principaux :
- ✅ Déployer une architecture multi-APIM (Premium + Developer)
- ✅ Implémenter des workspaces pour l'isolation logique des équipes
- ✅ Centraliser la gouvernance des APIs avec API Center
- ✅ Mettre en place un monitoring centralisé avec Application Insights
- ✅ Créer des APIs de démonstration dans différents workspaces
- ✅ Configurer des portails développeur pour chaque environnement
- ✅ Automatiser le déploiement via Infrastructure as Code

### 1.2 Contexte métier

La plateforme répond aux besoins suivants :
- **Équipes multiples** : Team A, Team B, et Partenaires externes
- **Environnements séparés** : Production (Premium) et Développement (Developer)
- **Gouvernance centralisée** : Découverte et catalogage des APIs via API Center
- **Isolation** : Workspaces dédiés pour chaque équipe dans l'APIM Premium
- **Monitoring unifié** : Toutes les instances APIM loguent vers Application Insights

### 1.3 Scope du déploiement

#### Ressources Azure déployées :
| Ressource | Type | SKU | Région | Statut |
|-----------|------|-----|--------|--------|
| rg-api-portal-dev | Resource Group | - | France Central | ✅ Déployé |
| apim-premium-prod-1161 | API Management | Premium_1 | France Central | ✅ Déployé |
| apim-developer-dev-1161 | API Management | Developer_1 | France Central | ✅ Déployé |
| apic-portal-dev-1161 | API Center | Free | France Central | ✅ Déployé |
| appi-api-portal-dev-1161 | Application Insights | - | France Central | ✅ Déployé |
| law-api-portal-dev-1161 | Log Analytics Workspace | PerGB2018 | France Central | ✅ Déployé |

#### Workspaces APIM Premium :
- **workspace-team-a-prod** : APIs pour l'équipe A (3 APIs)
- **workspace-team-b-prod** : APIs pour l'équipe B (Analytics)
- **workspace-partners-prod** : APIs pour les partenaires externes

#### APIs créées :
- **Customer Management API** : Gestion des clients (Team A)
- **Partner Integration API** : Intégration partenaires
- **Analytics API** : Analytics et rapports (Team B)

---

## 2. ARCHITECTURE TECHNIQUE

### 2.1 Diagramme d'architecture global

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Insights                      │
│              + Log Analytics Workspace                      │
│           (Monitoring centralisé - 100% sampling)          │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼────────┐    ┌────────▼──────────┐
│ Azure API Center│    │  Metric Alerts    │
│  (Gouvernance)  │    │  (4 alertes)      │
│  - 3 APIs       │    │  - Error Rate     │
│  - Catalogue    │    │  - Latency        │
│  - Discovery    │    │  - Capacity       │
└─────────────────┘    └───────────────────┘
         │                       
         │ Registration
         │
┌────────▼─────────────────────────────────────────┐
│         APIM Premium (Production)                │
│         SKU: Premium_1                           │
│   ┌──────────────────────────────────────────┐   │
│   │ Workspace Team A (workspace-team-a-prod) │   │
│   │  - Customer Management API               │   │
│   │  - Produit: Team A Production            │   │
│   └──────────────────────────────────────────┘   │
│   ┌──────────────────────────────────────────┐   │
│   │ Workspace Partners (workspace-partners-) │   │
│   │  - Partner Integration API               │   │
│   │  - Produit: Partner Integration          │   │
│   └──────────────────────────────────────────┘   │
│   ┌──────────────────────────────────────────┐   │
│   │ Workspace Team B (workspace-team-b-prod) │   │
│   │  - Analytics API                         │   │
│   │  - Produit: Team B Analytics             │   │
│   └──────────────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
         │
         │ Gateway URL
         │ https://apim-premium-prod-1161.azure-api.net
         ▼
   ┌──────────┐
   │ Clients  │
   └──────────┘

┌──────────────────────────────────────────────────┐
│      APIM Developer (Development)                │
│         SKU: Developer_1                         │
│   - Environnement de développement               │
│   - Pas de workspaces (limitation SKU)          │
└──────────────────────────────────────────────────┘
         │
         │ Gateway URL
         │ https://apim-developer-dev-1161.azure-api.net
```

### 2.2 Flux de données

#### Flux d'appel API :
```
Client → APIM Gateway → Backend API → Response
  │                                      │
  └──────────────────┬──────────────────┘
                     │
                     ▼
          Application Insights
                     │
          ┌──────────┴──────────┐
          │                     │
    Log Analytics          Alertes
    (Requêtes KQL)      (Email/SMS)
```

#### Flux de gouvernance :
```
Développeur → Crée API dans APIM Workspace
                     │
                     ▼
              Script automation
                     │
                     ▼
           Enregistrement dans API Center
                     │
                     ▼
           Catalogue centralisé visible
```

### 2.3 Choix technologiques

| Composant | Technologie | Version | Justification |
|-----------|-------------|---------|---------------|
| IaC | Terraform | 1.6.0+ | Standard industrie, état déclaratif, modules réutilisables |
| Provider Azure | AzureRM | ~3.0 | Support complet APIM Premium et API Center |
| Automation | PowerShell | 7.0+ | Intégration native Windows, Azure CLI disponible |
| API Specification | OpenAPI | 3.0.0 | Standard industrie, support complet APIM |
| Monitoring | App Insights | - | Intégration native APIM, requêtes KQL puissantes |
| Logging | Log Analytics | PerGB2018 | Rétention 30 jours, coût optimisé |

### 2.4 Topologie réseau

```
┌──────────────────────────────────────────────┐
│  Virtual Network (Non implémenté - V2)       │
│                                              │
│  ┌────────────┐      ┌─────────────┐        │
│  │   Subnet   │      │   Subnet    │        │
│  │   APIM     │      │   Backend   │        │
│  └────────────┘      └─────────────┘        │
│                                              │
└──────────────────────────────────────────────┘

Configuration actuelle :
- Public Network Access: Enabled
- Virtual Network Type: None
- Exposition: Internet publique avec clés API
```

---

## 3. INFRASTRUCTURE AS CODE (TERRAFORM)

### 3.1 Structure du projet Terraform

```
infra/
├── main.tf                # Ressources principales
├── variables.tf           # Déclaration des variables
├── outputs.tf            # Outputs exposés
├── terraform.dev.tfvars  # Valeurs pour l'environnement dev
└── backend.tf            # Configuration backend (commenté)
```

### 3.2 Fichier main.tf - Ressources déployées

#### 3.2.1 Provider et configuration Terraform

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

#### 3.2.2 Resource Group

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

**Valeurs déployées:**
- Nom: `rg-api-portal-dev`
- Région: `francecentral`
- Tags: Environment=Development, Project=API Portal, ManagedBy=Terraform

#### 3.2.3 Log Analytics Workspace

```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}
```

**Configuration:**
- SKU: PerGB2018 (pay-as-you-go)
- Rétention: 30 jours
- Utilisation: Backend pour Application Insights

#### 3.2.4 Application Insights

```hcl
resource "azurerm_application_insights" "appi" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}
```

**Configuration:**
- Type: web
- Workspace: Lié au Log Analytics Workspace
- Instrumentation Key: Exposée via outputs

#### 3.2.5 API Management Premium

```hcl
resource "azurerm_api_management" "apim_premium" {
  name                = var.apim_premium_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Premium_1"
  
  tags = merge(var.tags, {
    Environment = "Production"
    Tier        = "Premium"
  })
}
```

**Caractéristiques:**
- SKU: Premium_1 (1 unité Premium)
- Capacité: Support multi-région, workspaces, VNet
- Temps de déploiement: ~45 minutes
- Coût estimé: ~2000€/mois

#### 3.2.6 API Management Developer

```hcl
resource "azurerm_api_management" "apim_developer" {
  name                = var.apim_developer_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"
  
  tags = merge(var.tags, {
    Environment = "Development"
    Tier        = "Developer"
  })
}
```

**Caractéristiques:**
- SKU: Developer_1 (1 unité Developer)
- Limitations: Pas de workspaces, pas de SLA production
- Temps de déploiement: ~30 minutes
- Coût estimé: Gratuit (non-production)

#### 3.2.7 Workspaces APIM Premium (ARM Template)

```hcl
resource "azurerm_resource_group_template_deployment" "apim_workspaces_prod" {
  name                = "apim-workspaces-prod-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  
  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters     = {}
    resources      = [
      {
        apiVersion = "2023-05-01-preview"
        name       = "${azurerm_api_management.apim_premium.name}/workspace-team-a-prod"
        type       = "Microsoft.ApiManagement/service/workspaces"
        properties = {
          displayName = "Team A Production Workspace"
          description = "Workspace de production pour l'équipe A"
        }
      },
      {
        apiVersion = "2023-05-01-preview"
        name       = "${azurerm_api_management.apim_premium.name}/workspace-team-b-prod"
        type       = "Microsoft.ApiManagement/service/workspaces"
        properties = {
          displayName = "Team B Production Workspace"
          description = "Workspace de production pour l'équipe B"
        }
      },
      {
        apiVersion = "2023-05-01-preview"
        name       = "${azurerm_api_management.apim_premium.name}/workspace-partners-prod"
        type       = "Microsoft.ApiManagement/service/workspaces"
        properties = {
          displayName = "Partners Production Workspace"
          description = "Workspace de production pour les APIs partenaires"
        }
      }
    ]
  })
  
  depends_on = [azurerm_api_management.apim_premium]
}
```

**Raison d'utilisation ARM Template:**
- Les workspaces APIM utilisent une API Preview (2023-05-01-preview)
- Le provider Terraform AzureRM ~3.0 ne supporte pas encore nativement les workspaces
- ARM Template permet d'utiliser les APIs Preview Azure

#### 3.2.8 Azure API Center (ARM Template)

```hcl
resource "azurerm_resource_group_template_deployment" "api_center" {
  name                = "api-center-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  
  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters     = {}
    resources      = [
      {
        type       = "Microsoft.ApiCenter/services"
        apiVersion = "2024-03-01"
        name       = var.api_center_name
        location   = azurerm_resource_group.rg.location
        sku        = { name = "Free" }
        properties = {}
        tags       = var.tags
      }
    ]
  })
}
```

**Configuration:**
- SKU: Free (jusqu'à 200 APIs)
- API Version: 2024-03-01 (GA)
- Fonctionnalités: Catalogue centralisé, métadonnées, découverte

#### 3.2.9 Loggers APIM (Application Insights)

```hcl
resource "azurerm_api_management_logger" "apim_premium_logger" {
  name                = "appi-logger-premium"
  api_management_name = azurerm_api_management.apim_premium.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appi.id
  
  application_insights {
    instrumentation_key = azurerm_application_insights.appi.instrumentation_key
  }
}

resource "azurerm_api_management_logger" "apim_developer_logger" {
  name                = "appi-logger-developer"
  api_management_name = azurerm_api_management.apim_developer.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appi.id
  
  application_insights {
    instrumentation_key = azurerm_application_insights.appi.instrumentation_key
  }
}
```

#### 3.2.10 Diagnostics APIM

```hcl
resource "azurerm_api_management_api_diagnostic" "apim_premium_diagnostic" {
  api_management_logger_id = azurerm_api_management_logger.apim_premium_logger.id
  api_management_name      = azurerm_api_management.apim_premium.name
  api_name                 = "echo-api"  # API par défaut
  resource_group_name      = azurerm_resource_group.rg.name
  identifier               = "applicationinsights"
  
  sampling_percentage       = 100.0
  always_log_errors        = true
  log_client_ip            = true
  verbosity                = "information"
  http_correlation_protocol = "W3C"
  
  frontend_request {
    body_bytes     = 8192
    headers_to_log = ["Accept", "Content-Type", "Authorization"]
  }
  
  frontend_response {
    body_bytes     = 8192
    headers_to_log = ["Content-Type", "Content-Length"]
  }
}
```

**Configuration du logging:**
- Sampling: 100% (tous les appels loggés)
- Corrélation: W3C Trace Context (standard)
- Verbosité: Information
- Headers loggés: Accept, Content-Type, Authorization
- Body: 8KB max (frontend request/response)

### 3.3 Variables Terraform

#### 3.3.1 variables.tf - Déclarations

```hcl
variable "resource_group_name" {
  description = "Nom du groupe de ressources Azure"
  type        = string
  default     = "rg-api-portal"
}

variable "location" {
  description = "Région Azure pour le déploiement des ressources"
  type        = string
  default     = "francecentral"
}

variable "apim_premium_name" {
  description = "Nom de l'instance API Management Premium (Production)"
  type        = string
  default     = "apim-premium-portal-prod"
}

variable "apim_developer_name" {
  description = "Nom de l'instance API Management Developer (Development)"
  type        = string
  default     = "apim-dev-portal-dev"
}

variable "api_center_name" {
  description = "Nom de l'instance Azure API Center"
  type        = string
  default     = "apic-portal"
}

variable "publisher_name" {
  description = "Nom de l'organisation pour APIM"
  type        = string
  default     = "Organisation Dev"
}

variable "publisher_email" {
  description = "Email de contact pour APIM"
  type        = string
  default     = "dev@votredomaine.com"
}

variable "tags" {
  description = "Tags à appliquer sur toutes les ressources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "API Portal"
    ManagedBy   = "Terraform"
    CostCenter  = "DEV"
  }
}

# Workspaces APIM Premium
variable "workspace1_name" {
  description = "Nom du premier workspace APIM Production"
  type        = string
  default     = "workspace-team-a-prod"
}

variable "workspace2_name" {
  description = "Nom du deuxième workspace APIM Production"
  type        = string
  default     = "workspace-team-b-prod"
}

variable "workspace3_name" {
  description = "Nom du troisième workspace APIM Production"
  type        = string
  default     = "workspace-partners-prod"
}
```

#### 3.3.2 terraform.dev.tfvars - Valeurs déployées

```hcl
resource_group_name            = "rg-api-portal-dev"
location                       = "francecentral"
apim_premium_name             = "apim-premium-prod-1161"
apim_developer_name           = "apim-developer-dev-1161"
api_center_name               = "apic-portal-dev-1161"
log_analytics_workspace_name  = "law-api-portal-dev-1161"
application_insights_name     = "appi-api-portal-dev-1161"

publisher_name  = "Organisation Dev"
publisher_email = "dev@votredomaine.com"

workspace1_name         = "workspace-team-a-prod"
workspace1_display_name = "Team A Production Workspace"
workspace1_description  = "Workspace de production pour l'équipe A"

workspace2_name         = "workspace-team-b-prod"
workspace2_display_name = "Team B Production Workspace"
workspace2_description  = "Workspace de production pour l'équipe B"

workspace3_name         = "workspace-partners-prod"
workspace3_display_name = "Partners Production Workspace"
workspace3_description  = "Workspace de production pour les APIs partenaires"

tags = {
  Environment = "Development"
  Project     = "API Portal"
  ManagedBy   = "Terraform"
  CostCenter  = "DEV"
}
```

### 3.4 Outputs Terraform

```hcl
output "apim_premium_gateway_url" {
  description = "URL de la gateway APIM Premium (Production)"
  value       = azurerm_api_management.apim_premium.gateway_url
  # Valeur: https://apim-premium-prod-1161.azure-api.net
}

output "apim_premium_portal_url" {
  description = "URL du portail développeur APIM Premium (Production)"
  value       = azurerm_api_management.apim_premium.developer_portal_url
  # Valeur: https://apim-premium-prod-1161.developer.azure-api.net
}

output "apim_developer_gateway_url" {
  description = "URL de la gateway APIM Developer (Development)"
  value       = azurerm_api_management.apim_developer.gateway_url
  # Valeur: https://apim-developer-dev-1161.azure-api.net
}

output "application_insights_instrumentation_key" {
  description = "Clé d'instrumentation Application Insights"
  value       = azurerm_application_insights.appi.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID du Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.workspace_id
}
```

### 3.5 Backend Terraform (State Management)

#### 3.5.1 Configuration backend.tf (commentée)

```hcl
# Commenté temporairement - utilisation du backend local
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "tfstateapiportal1161"
#     container_name       = "tfstate"
#     key                  = "api-portal.tfstate"
#   }
# }
```

**Raison du commentaire:**
- Problèmes d'authentification lors du déploiement initial
- Erreurs 403 Forbidden sur le storage account
- Solution temporaire: Backend local (`terraform.tfstate` dans le répertoire infra/)

#### 3.5.2 Script de configuration du backend Azure

**Fichier:** `scripts/setup-azure-backend.ps1`

Ce script crée le backend Azure pour Terraform state:
- Création du Resource Group `rg-terraform-state`
- Création du Storage Account `tfstateapiportal1161`
- Création du container `tfstate`
- Configuration des permissions appropriées

### 3.6 Commandes Terraform utilisées

```bash
# Initialisation
terraform init

# Validation de la syntaxe
terraform validate

# Aperçu des changements
terraform plan -var-file="terraform.dev.tfvars"

# Application
terraform apply -var-file="terraform.dev.tfvars" -auto-approve

# Affichage des outputs
terraform output

# Import de ressources existantes (utilisé pendant le déploiement)
terraform import azurerm_resource_group.rg /subscriptions/{id}/resourceGroups/rg-api-portal-dev
terraform import azurerm_api_management.apim_premium /subscriptions/{id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiManagement/service/apim-premium-prod-1161
```

### 3.7 Défis rencontrés et solutions

#### Problème 1: Déploiement APIM interrompu
**Symptôme:** Terraform apply annulé pendant le déploiement long (26+ minutes)  
**Cause:** Déploiement APIM Premium prend 45 minutes, interruption manuelle  
**Solution:** Import des ressources déjà créées dans Azure avec `terraform import`

#### Problème 2: Workspaces non supportés sur Developer SKU
**Symptôme:** Erreur `MethodNotAllowedInPricingTier` lors de la création de workspaces  
**Cause:** Les workspaces sont une fonctionnalité Premium uniquement  
**Solution:** Suppression des workspaces pour APIM Developer, maintien uniquement sur Premium

#### Problème 3: Provider Terraform ne supporte pas les workspaces
**Symptôme:** Pas de ressource `azurerm_api_management_workspace` disponible  
**Cause:** Workspaces utilisent une API Preview non encore supportée par le provider  
**Solution:** Utilisation d'ARM Template via `azurerm_resource_group_template_deployment`

#### Problème 4: Application Insights non actif immédiatement
**Symptôme:** Erreurs lors de la configuration des diagnostics juste après la création APIM  
**Cause:** Délai de propagation après le provisioning APIM  
**Solution:** Attente de 2 minutes avant la configuration des loggers et diagnostics

---

## 4. AZURE API MANAGEMENT

### 4.1 Instance Premium (Production)

#### Caractéristiques techniques
- **Nom:** apim-premium-prod-1161
- **SKU:** Premium_1 (1 unité de calcul)
- **Région:** France Central
- **Gateway URL:** https://apim-premium-prod-1161.azure-api.net
- **Portal URL:** https://apim-premium-prod-1161.developer.azure-api.net
- **Management URL:** https://apim-premium-prod-1161.management.azure-api.net
- **SCM URL:** https://apim-premium-prod-1161.scm.azure-api.net

#### Capacité et limites (Premium_1)
- **Débit max:** ~1000 requêtes/seconde
- **SLA:** 99.95%
- **Stockage cache:** 1 GB
- **Workspaces:** Illimité
- **Multi-région:** Supporté
- **VNet injection:** Supporté
- **Availability Zones:** Supporté

#### Fonctionnalités activées
| Fonctionnalité | Statut | Configuration |
|----------------|--------|---------------|
| Workspaces | ✅ Activé | 3 workspaces créés |
| Application Insights | ✅ Activé | Logger configuré, 100% sampling |
| Developer Portal | ✅ Activé | Accessible publiquement |
| Policies | ⚠️ À configurer | Templates par défaut |
| OAuth 2.0 | ❌ Non configuré | Planifié phase 2 |
| Client Certificates | ❌ Désactivé | Non requis pour POC |
| Virtual Network | ❌ Non configuré | Type: None (public) |

### 4.2 Instance Developer (Développement)

#### Caractéristiques techniques
- **Nom:** apim-developer-dev-1161
- **SKU:** Developer_1
- **Région:** France Central
- **Gateway URL:** https://apim-developer-dev-1161.azure-api.net
- **Portal URL:** https://apim-developer-dev-1161.developer.azure-api.net

#### Capacité et limites (Developer_1)
- **Débit max:** Non garanti (sans SLA)
- **SLA:** Aucun (environnement de développement)
- **Workspaces:** ❌ Non supporté
- **Multi-région:** ❌ Non supporté
- **Usage:** Développement et test uniquement

#### Limitations connues
- Pas de support workspaces
- Pas de SLA de production
- Pas de multi-région
- Capacité non garantie
- Ne devrait jamais être utilisé en production

### 4.3 Politiques APIM (Policies)

#### Politiques globales par défaut

**Inbound (Entrant):**
```xml
<policies>
    <inbound>
        <base />
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="X-AspNet-Version" exists-action="delete" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

#### Politiques recommandées (non implémentées)

**Rate Limiting:**
```xml
<rate-limit-by-key calls="100" renewal-period="60" 
    counter-key="@(context.Subscription.Id)" />
```

**JWT Validation:**
```xml
<validate-jwt header-name="Authorization">
    <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
    <audiences>
        <audience>api://apim-premium-prod-1161</audience>
    </audiences>
</validate-jwt>
```

**CORS:**
```xml
<cors allow-credentials="false">
    <allowed-origins>
        <origin>https://example.com</origin>
    </allowed-origins>
    <allowed-methods>
        <method>GET</method>
        <method>POST</method>
    </allowed-methods>
    <allowed-headers>
        <header>*</header>
    </allowed-headers>
</cors>
```

### 4.4 Produits configurés

| Produit ID | Nom | Workspaces ciblés | Souscription requise | Approbation requise |
|------------|-----|-------------------|----------------------|---------------------|
| team-a-prod | Team A Production | Team A | ✅ Oui | ⚠️ No (pour démo) |
| partners-prod | Partner Integration | Partners | ✅ Oui | ⚠️ No (pour démo) |
| team-b-prod | Team B Analytics | Team B | ✅ Oui | ⚠️ No (pour démo) |

**Note:** L'approbation manuelle est désactivée pour faciliter les tests. En production, elle devrait être activée.

### 4.5 Utilisateurs créés

| User ID | Email | Nom complet | Produit(s) | État |
|---------|-------|-------------|------------|------|
| dev-team-a | dev-team-a@example.com | Developer Team A | Team A Production | ✅ Actif |
| partner-user | partner@example.com | Partner External | Partner Integration | ✅ Actif |
| dev-team-b | dev-team-b@example.com | Developer Team B | Team B Analytics | ✅ Actif |

### 4.6 Souscriptions et clés API

| Souscription | Produit | Utilisateur | Clé primaire | État |
|--------------|---------|-------------|--------------|------|
| 698080704634611f8cb2c0b1 | team-a-prod | dev-team-a | 7594a5149d5b4e4c9bd1944050990aa6 | ✅ Active |
| 69808075217d2011dc7ac797 | partners-prod | partner-user | 9298c21db7de4dd8833e4ee2ed4aaac0 | ✅ Active |
| 6980807b217d2011dc7ac79a | team-b-prod | dev-team-b | e15acf3a9c5f47c88b8fad4cc15c188a | ✅ Active |

**⚠️ Sécurité:** Ces clés donnent un accès complet aux APIs. Ne jamais les partager ou les commiter dans Git.

---

## 5. AZURE API CENTER

### 5.1 Configuration

- **Nom:** apic-portal-dev-1161
- **SKU:** Free (jusqu'à 200 APIs)
- **Région:** France Central
- **Type de ressource:** Microsoft.ApiCenter/services
- **API Version:** 2024-03-01 (GA - General Availability)

### 5.2 APIs enregistrées

| API ID | Nom | Type | Workspace source | Enregistrement |
|--------|-----|------|------------------|----------------|
| customer-api | Customer Management API | REST | workspace-team-a-prod | ✅ Enregistrée |
| partner-api | Partner Integration API | REST | workspace-partners-prod | ✅ Enregistrée |
| analytics-api | Analytics API | REST | workspace-team-b-prod | ✅ Enregistrée |

### 5.3 Métadonnées des APIs

#### Customer Management API
```json
{
  "properties": {
    "title": "Customer Management API",
    "kind": "rest",
    "summary": "API pour la gestion des clients",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://apim-premium-prod-1161.azure-api.net/customers"
      }
    ]
  }
}
```

#### Partner Integration API
```json
{
  "properties": {
    "title": "Partner Integration API",
    "kind": "rest",
    "summary": "API pour l'intégration partenaires",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://apim-premium-prod-1161.azure-api.net/partners"
      }
    ]
  }
}
```

#### Analytics API
```json
{
  "properties": {
    "title": "Analytics API",
    "kind": "rest",
    "summary": "API pour les analytics et rapports",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://apim-premium-prod-1161.azure-api.net/analytics"
      }
    ]
  }
}
```

### 5.4 Fonctionnalités API Center

#### Catalogue centralisé
- **Découvrabilité:** Toutes les APIs visibles dans un catalogue unique
- **Recherche:** Recherche par nom, type, workspace
- **Métadonnées:** Description, documentation, propriétaire

#### Gouvernance
- **Cycle de vie:** Suivi des versions d'API
- **Compliance:** Standards et politiques d'API
- **Qualité:** Métriques de santé des APIs

#### Collaboration
- **Documentation:** Liens vers documentation externe
- **Ownership:** Attribution à des équipes
- **Communication:** Notifications de changements

---

## 6. WORKSPACES APIM

### 6.1 Concept des workspaces

Les workspaces APIM permettent l'**isolation logique** des APIs au sein d'une même instance APIM Premium:
- Séparation des équipes
- Gestion indépendante des API
- Isolation des politiques
- Facturation centralisée

### 6.2 Workspace Team A (Production)

#### Configuration
- **ID:** workspace-team-a-prod
- **Nom d'affichage:** Team A Production Workspace
- **Description:** Workspace de production pour l'équipe A
- **Instance APIM:** apim-premium-prod-1161

#### APIs déployées
- **Customer Management API** (customer-api)
  - Path: `/customers`
  - Méthodes: GET, POST, PUT, DELETE
  - Backend: https://api.example.com/customers (exemple)

#### Produit associé
- **team-a-prod:** Team A Production
  - Souscription requise: ✅
  - Limite: 100 souscriptions

### 6.3 Workspace Partners (Production)

#### Configuration
- **ID:** workspace-partners-prod
- **Nom d'affichage:** Partners Production Workspace
- **Description:** Workspace de production pour les APIs partenaires
- **Instance APIM:** apim-premium-prod-1161

#### APIs déployées
- **Partner Integration API** (partner-api)
  - Path: `/partners`
  - Méthodes: POST (webhook), GET (orders)
  - Backend: https://api.example.com/partners (exemple)

#### Produit associé
- **partners-prod:** Partner Integration
  - Souscription requise: ✅
  - Limite: 50 souscriptions

### 6.4 Workspace Team B (Production)

#### Configuration
- **ID:** workspace-team-b-prod
- **Nom d'affichage:** Team B Production Workspace
- **Description:** Workspace de production pour l'équipe B
- **Instance APIM:** apim-premium-prod-1161

#### APIs déployées
- **Analytics API** (analytics-api)
  - Path: `/analytics`
  - Méthodes: GET (reports, metrics)
  - Backend: https://api.example.com/analytics (exemple)

#### Produit associé
- **team-b-prod:** Team B Analytics
  - Souscription requise: ✅
  - Limite: 100 souscriptions

### 6.5 Avantages des workspaces

#### Isolation
- ✅ Les APIs dans un workspace sont logiquement séparées
- ✅ Politiques peuvent être différentes par workspace
- ✅ Gestion des accès par workspace

#### Collaboration
- ✅ Équipes peuvent travailler indépendamment
- ✅ Pas de risque de conflit entre équipes
- ✅ Onboarding facilité pour nouvelles équipes

#### Gouvernance
- ✅ Propriété claire des APIs
- ✅ Audit trail par workspace
- ✅ Métriques séparées par équipe

---

## 7. APIS DÉPLOYÉES

### 7.1 Customer Management API

#### Spécification OpenAPI 3.0

```yaml
openapi: 3.0.0
info:
  title: Customer Management API
  description: API pour la gestion des clients
  version: 1.0.0
servers:
  - url: https://api.example.com/customers
paths:
  /customers:
    get:
      summary: Liste tous les clients
      responses:
        '200':
          description: Liste des clients
    post:
      summary: Créer un nouveau client
      responses:
        '201':
          description: Client créé
  /customers/{customerId}:
    get:
      summary: Détails d'un client
      parameters:
        - name: customerId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Détails du client
```

#### Configuration APIM
- **API ID:** customer-api
- **Display Name:** Customer Management API
- **Path:** /customers
- **Protocols:** HTTPS uniquement
- **Subscription required:** ✅ Oui
- **Workspace:** workspace-team-a-prod
- **Product:** team-a-prod

#### Exemples d'appels

**Liste des clients:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/customers/customers" \
  -H "Ocp-Apim-Subscription-Key: 7594a5149d5b4e4c9bd1944050990aa6"
```

**Détails d'un client:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/customers/customers/123" \
  -H "Ocp-Apim-Subscription-Key: 7594a5149d5b4e4c9bd1944050990aa6"
```

**Créer un client:**
```bash
curl -X POST "https://apim-premium-prod-1161.azure-api.net/customers/customers" \
  -H "Ocp-Apim-Subscription-Key: 7594a5149d5b4e4c9bd1944050990aa6" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Client", "email": "test@example.com"}'
```

### 7.2 Partner Integration API

#### Spécification OpenAPI 3.0

```yaml
openapi: 3.0.0
info:
  title: Partner Integration API
  description: API pour l'intégration partenaires
  version: 1.0.0
servers:
  - url: https://api.example.com/partners
paths:
  /webhook:
    post:
      summary: Webhook pour notifications partenaires
      responses:
        '200':
          description: Webhook reçu
  /orders:
    get:
      summary: Liste des commandes partenaires
      responses:
        '200':
          description: Liste des commandes
```

#### Configuration APIM
- **API ID:** partner-api
- **Display Name:** Partner Integration API
- **Path:** /partners
- **Protocols:** HTTPS uniquement
- **Subscription required:** ✅ Oui
- **Workspace:** workspace-partners-prod
- **Product:** partners-prod

#### Exemples d'appels

**Webhook:**
```bash
curl -X POST "https://apim-premium-prod-1161.azure-api.net/partners/webhook" \
  -H "Ocp-Apim-Subscription-Key: 9298c21db7de4dd8833e4ee2ed4aaac0" \
  -H "Content-Type: application/json" \
  -d '{"event": "order.created", "orderId": "12345"}'
```

**Liste des commandes:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/partners/orders" \
  -H "Ocp-Apim-Subscription-Key: 9298c21db7de4dd8833e4ee2ed4aaac0"
```

### 7.3 Analytics API

#### Spécification OpenAPI 3.0

```yaml
openapi: 3.0.0
info:
  title: Analytics API
  description: API pour les analytics et rapports
  version: 1.0.0
servers:
  - url: https://api.example.com/analytics
paths:
  /reports:
    get:
      summary: Rapports analytics
      responses:
        '200':
          description: Rapports disponibles
  /metrics:
    get:
      summary: Métriques
      responses:
        '200':
          description: Métriques disponibles
```

#### Configuration APIM
- **API ID:** analytics-api
- **Display Name:** Analytics API
- **Path:** /analytics
- **Protocols:** HTTPS uniquement
- **Subscription required:** ✅ Oui
- **Workspace:** workspace-team-b-prod
- **Product:** team-b-prod

#### Exemples d'appels

**Rapports:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/analytics/reports" \
  -H "Ocp-Apim-Subscription-Key: e15acf3a9c5f47c88b8fad4cc15c188a"
```

**Métriques:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/analytics/metrics" \
  -H "Ocp-Apim-Subscription-Key: e15acf3a9c5f47c88b8fad4cc15c188a"
```

---

## 8. MONITORING ET OBSERVABILITÉ

### 8.1 Application Insights

#### Configuration
- **Nom:** appi-api-portal-dev-1161
- **Type:** web
- **Workspace:** law-api-portal-dev-1161
- **Instrumentation Key:** [SENSIBLE - dans outputs Terraform]
- **Connection String:** [SENSIBLE - dans le portail Azure]

#### Données collectées
- **Requêtes HTTP:** 100% des appels API
- **Dépendances:** Appels vers backends
- **Exceptions:** Toutes les erreurs capturées
- **Traces personnalisées:** Logs APIM
- **Métriques:** Performance, disponibilité, utilisation

#### Configuration du sampling
```hcl
sampling_percentage = 100.0  # 100% des requêtes loggées
```

**Note:** En production, réduire à 10-20% pour optimiser les coûts.

### 8.2 Log Analytics Workspace

#### Configuration
- **Nom:** law-api-portal-dev-1161
- **SKU:** PerGB2018 (pay-as-you-go)
- **Rétention:** 30 jours
- **Région:** France Central

#### Tables de données
- **requests:** Requêtes HTTP
- **dependencies:** Appels externes
- **exceptions:** Erreurs et exceptions
- **traces:** Logs applicatifs
- **customMetrics:** Métriques personnalisées

### 8.3 Alertes configurées

#### Alerte 1: Taux d'erreur élevé (Premium)
```json
{
  "name": "APIM Premium - High Error Rate",
  "description": "Alerte quand le taux d'erreur dépasse 5%",
  "severity": 2,
  "evaluationFrequency": "PT1M",
  "windowSize": "PT5M",
  "criteria": {
    "metricName": "Requests",
    "operator": "GreaterThan",
    "threshold": 5.0,
    "aggregation": "Average"
  }
}
```

#### Alerte 2: Temps de réponse élevé (Premium)
```json
{
  "name": "APIM Premium - High Latency",
  "description": "Alerte quand la latence dépasse 2 secondes",
  "severity": 3,
  "evaluationFrequency": "PT1M",
  "windowSize": "PT5M",
  "criteria": {
    "metricName": "Duration",
    "operator": "GreaterThan",
    "threshold": 2000.0,
    "aggregation": "Average"
  }
}
```

#### Alerte 3: Capacité élevée (Premium)
```json
{
  "name": "APIM Premium - High Capacity",
  "description": "Alerte quand la capacité dépasse 75%",
  "severity": 2,
  "evaluationFrequency": "PT1M",
  "windowSize": "PT5M",
  "criteria": {
    "metricName": "Capacity",
    "operator": "GreaterThan",
    "threshold": 75.0,
    "aggregation": "Average"
  }
}
```

#### Alerte 4: Taux d'erreur élevé (Developer)
```json
{
  "name": "APIM Developer - High Error Rate",
  "description": "Alerte quand le taux d'erreur dépasse 10%",
  "severity": 3,
  "evaluationFrequency": "PT1M",
  "windowSize": "PT5M",
  "criteria": {
    "metricName": "Requests",
    "operator": "GreaterThan",
    "threshold": 10.0,
    "aggregation": "Average"
  }
}
```

### 8.4 Requêtes KQL pour dashboards

#### Requête 1: Vue d'ensemble des requêtes
```kusto
requests
| where cloud_RoleName startswith "apim"
| summarize 
    TotalRequests = count(),
    SuccessRate = countif(success == true) * 100.0 / count(),
    AvgDuration = avg(duration)
    by bin(timestamp, 5m)
| render timechart
```

#### Requête 2: Taux d'erreur par API
```kusto
requests
| where cloud_RoleName startswith "apim"
| summarize 
    Total = count(),
    Errors = countif(success == false),
    ErrorRate = countif(success == false) * 100.0 / count()
    by operation_Name
| order by ErrorRate desc
```

#### Requête 3: Performance par opération
```kusto
requests
| where cloud_RoleName startswith "apim"
| summarize 
    p50 = percentile(duration, 50),
    p95 = percentile(duration, 95),
    p99 = percentile(duration, 99)
    by operation_Name
| order by p95 desc
```

#### Requête 4: Analyse des dépendances
```kusto
dependencies
| where cloud_RoleName startswith "apim"
| summarize 
    Count = count(),
    AvgDuration = avg(duration),
    SuccessRate = countif(success == true) * 100.0 / count()
    by target, type
| order by Count desc
```

#### Requête 5: Distribution des temps de réponse
```kusto
requests
| where cloud_RoleName startswith "apim"
| summarize count() by bin(duration, 100)
| render barchart
```

#### Requête 6: Top 10 des erreurs
```kusto
exceptions
| where cloud_RoleName startswith "apim"
| summarize Count = count() by type, outerMessage
| top 10 by Count desc
```

#### Requête 7: Utilisation par workspace
```kusto
requests
| where cloud_RoleName startswith "apim"
| extend workspace = extract(@"/(workspace-[^/]+)/", 1, url)
| summarize RequestCount = count() by workspace
| render piechart
```

#### Requête 8: Tendances de latence
```kusto
requests
| where cloud_RoleName startswith "apim"
| summarize 
    AvgDuration = avg(duration),
    MaxDuration = max(duration)
    by bin(timestamp, 1h)
| render timechart
```

#### Requête 9: Alertes et anomalies
```kusto
requests
| where cloud_RoleName startswith "apim"
| make-series RequestCount=count() on timestamp step 5m
| extend (anomalies, score, baseline) = series_decompose_anomalies(RequestCount, 1.5)
| mv-expand timestamp, RequestCount, anomalies, score, baseline
| where anomalies != 0
```

#### Requête 10: Analyse de la capacité
```kusto
metrics
| where name == "Capacity"
| summarize AvgCapacity = avg(value), MaxCapacity = max(value) by bin(timestamp, 5m)
| render timechart
```

### 8.5 Script de health check

**Fichier:** `scripts/health-check.ps1`

Ce script vérifie automatiquement:
- État des instances APIM
- Taux d'erreur des dernières 5 minutes
- Latence moyenne
- Capacité utilisée
- État des alertes

**Exécution:**
```powershell
.\health-check.ps1
```

---

## 9. SÉCURITÉ ET GOUVERNANCE

### 9.1 Authentication et autorisation

#### Clés de souscription (Subscription Keys)
- **Niveau:** Produit (team-a-prod, partners-prod, team-b-prod)
- **Format:** GUID 32 caractères
- **Transmission:** Header `Ocp-Apim-Subscription-Key`
- **Rotation:** Manuelle via Azure Portal ou API

#### OAuth 2.0 / OpenID Connect (Non implémenté)
**Recommandé pour production:**
```xml
<validate-jwt header-name="Authorization">
    <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
    <audiences>
        <audience>api://apim-premium-prod-1161</audience>
    </audiences>
    <required-claims>
        <claim name="roles" match="any">
            <value>API.Read</value>
            <value>API.Write</value>
        </claim>
    </required-claims>
</validate-jwt>
```

### 9.2 Secrets Management

#### Actuellement
- ⚠️ Clés de souscription stockées dans le script PowerShell
- ⚠️ Instrumentation keys dans Terraform state
- ⚠️ Pas de rotation automatique

#### Recommandations production
```hcl
# Utiliser Azure Key Vault
resource "azurerm_key_vault_secret" "apim_subscription_key" {
  name         = "apim-subscription-key-team-a"
  value        = azurerm_api_management_subscription.sub_team_a.primary_key
  key_vault_id = azurerm_key_vault.kv_apim.id
}

# Intégrer avec APIM Named Values
resource "azurerm_api_management_named_value" "backend_url" {
  name                = "backend-url"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_premium.name
  display_name        = "Backend URL"
  secret              = true
  value_from_key_vault {
    secret_id = azurerm_key_vault_secret.backend_url.id
  }
}
```

### 9.3 RBAC (Role-Based Access Control)

#### Rôles Azure recommandés

| Rôle | Scope | Permissions | Assigné à |
|------|-------|-------------|-----------|
| API Management Service Contributor | APIM Premium | Gestion complète APIM | DevOps Team |
| API Management Service Reader | APIM Premium | Lecture seule | Équipes dev |
| API Management Developer Portal Content Editor | APIM Premium | Édition portail | Marketing |
| Contributor | Resource Group | Gestion ressources | Administrateurs infra |

### 9.4 Network Security

#### Configuration actuelle (Public)
- **Virtual Network:** None
- **Public Access:** Enabled
- **IP Filtering:** Non configuré

#### Configuration recommandée (Production)

```hcl
resource "azurerm_api_management" "apim_premium" {
  # ...
  virtual_network_type = "Internal"
  
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }
  
  # IP Filtering
  ip_restriction {
    action  = "Allow"
    ip_address = "203.0.113.0/24"
  }
}
```

### 9.5 Audit et compliance

#### Logs d'audit Azure
- **Activité:** Tous les changements sur les ressources
- **Rétention:** 90 jours par défaut
- **Export:** Vers Log Analytics, Storage Account, Event Hub

#### Rapports de compliance
```kusto
AzureActivity
| where ResourceProvider == "Microsoft.ApiManagement"
| where OperationNameValue contains "write"
| project TimeGenerated, Caller, OperationNameValue, Resource
| order by TimeGenerated desc
```

---

## 10. PORTAILS DÉVELOPPEUR

### 10.1 Portail Premium (Production)

#### URL et accès
- **URL:** https://apim-premium-prod-1161.developer.azure-api.net
- **Authentification:** Email + Password (Managed Identity ou Azure AD)
- **Inscription:** Ouverte avec confirmation email

#### Personnalisation (Défaut)
- **Branding:** Logo par défaut Azure
- **Thème:** Thème par défaut
- **Pages:** Accueil, APIs, Produits, Applications

#### Fonctionnalités disponibles
- ✅ Découverte des APIs
- ✅ Test interactif des APIs (Try it console)
- ✅ Gestion des souscriptions
- ✅ Téléchargement des specs OpenAPI
- ✅ Documentation générée automatiquement

### 10.2 Portail Developer (Développement)

#### URL et accès
- **URL:** https://apim-developer-dev-1161.developer.azure-api.net
- **Configuration:** Identique au portail Premium

### 10.3 Personnalisation recommandée

#### Branding
- Logo de l'organisation
- Couleurs corporate
- Favicon personnalisé

#### Pages personnalisées
- Page d'accueil avec tutoriels
- FAQ
- Guides de démarrage rapide
- Changelog

#### Widgets
- Statistiques d'utilisation
- Status page
- Notifications

---

## 11. SCRIPTS D'AUTOMATISATION

### 11.1 setup-demo-apis.ps1

**Objectif:** Créer les 3 APIs de démonstration dans les workspaces APIM

**Fonctionnalités:**
- Génération de spécifications OpenAPI 3.0
- Création des APIs via Azure REST API dans les workspaces
- Enregistrement dans API Center
- Affichage des URLs de test

**Exécution:**
```powershell
cd scripts
.\setup-demo-apis.ps1
```

**Lignes de code:** ~290 lignes  
**Temps d'exécution:** ~2 minutes

### 11.2 setup-portal-simple.ps1

**Objectif:** Configurer les portails développeur avec produits et utilisateurs

**Fonctionnalités:**
- Création de 3 produits (team-a-prod, partners-prod, team-b-prod)
- Création de 3 utilisateurs de démonstration
- Création de 3 souscriptions avec clés
- Génération du guide de démarrage

**Exécution:**
```powershell
cd scripts
.\setup-portal-simple.ps1
```

**Lignes de code:** ~280 lignes  
**Temps d'exécution:** ~1 minute

### 11.3 setup-monitoring.ps1

**Objectif:** Configurer les alertes de monitoring et générer les requêtes KQL

**Fonctionnalités:**
- Création de 4 alertes de métriques Azure Monitor
- Génération du fichier `dashboard-queries.kql` avec 10 requêtes
- Création du script `health-check.ps1`

**Exécution:**
```powershell
cd scripts
.\setup-monitoring.ps1
```

**Lignes de code:** ~300 lignes  
**Temps d'exécution:** ~30 secondes

### 11.4 get-subscription-keys.ps1

**Objectif:** Récupérer les clés de souscription des workspaces

**Fonctionnalités:**
- Liste toutes les souscriptions dans les workspaces
- Récupère les clés primaires et secondaires
- Exporte dans `subscription-keys.md`

**Exécution:**
```powershell
cd scripts
.\get-subscription-keys.ps1
```

### 11.5 health-check.ps1

**Objectif:** Vérifier l'état de santé de la plateforme

**Fonctionnalités:**
- Statut des instances APIM
- Taux d'erreur (dernières 5 minutes)
- Latence moyenne
- Capacité utilisée
- État des alertes

**Exécution automatique:**
```powershell
# Toutes les 5 minutes
while ($true) {
    .\health-check.ps1
    Start-Sleep -Seconds 300
}
```

### 11.6 setup-azure-backend.ps1

**Objectif:** Configurer le backend Azure pour Terraform state

**Fonctionnalités:**
- Création du Resource Group pour Terraform state
- Création du Storage Account
- Création du container blob
- Configuration des permissions

**Exécution:**
```powershell
cd scripts
.\setup-azure-backend.ps1
```

**Note:** Exécuté une seule fois lors de l'initialisation du projet

---

## 12. GUIDE D'UTILISATION

### 12.1 Déploiement initial

#### Prérequis
- Azure CLI installé et configuré (`az login`)
- Terraform >= 1.6.0
- PowerShell 7.0+
- Droits Contributor sur la souscription Azure

#### Étapes de déploiement

**1. Cloner le repository**
```bash
git clone https://github.com/Ch0wseth/ApiPortal.git
cd ApiPortal
```

**2. Configuration Terraform**
```bash
cd infra
# Éditer terraform.dev.tfvars si nécessaire
terraform init
terraform plan -var-file="terraform.dev.tfvars"
```

**3. Déploiement de l'infrastructure**
```bash
terraform apply -var-file="terraform.dev.tfvars" -auto-approve
# ⏱️ Attention: Déploiement ~60-90 minutes
```

**4. Configuration des APIs**
```bash
cd ../scripts
.\setup-demo-apis.ps1
```

**5. Configuration des portails**
```bash
.\setup-portal-simple.ps1
```

**6. Configuration du monitoring**
```bash
.\setup-monitoring.ps1
```

#### TroubleshootingDéploiement

**Problème: Timeout Terraform**
```bash
# Si le déploiement est interrompu, importer les ressources existantes
terraform import azurerm_api_management.apim_premium <resource-id>
terraform import azurerm_api_management.apim_developer <resource-id>
```

**Problème: Workspaces non créés**
```bash
# Vérifier que l'APIM Premium est complètement provisionné
az apim show --name apim-premium-prod-1161 --resource-group rg-api-portal-dev --query provisioningState
# Attendre "Succeeded" avant de créer les workspaces
```

### 12.2 Utilisation quotidienne

#### Appeler une API

**Avec curl:**
```bash
curl -X GET "https://apim-premium-prod-1161.azure-api.net/customers/customers" \
  -H "Ocp-Apim-Subscription-Key: 7594a5149d5b4e4c9bd1944050990aa6"
```

**Avec PowerShell:**
```powershell
$headers = @{
    "Ocp-Apim-Subscription-Key" = "7594a5149d5b4e4c9bd1944050990aa6"
}
Invoke-RestMethod -Uri "https://apim-premium-prod-1161.azure-api.net/customers/customers" `
    -Headers $headers
```

**Avec Python:**
```python
import requests

headers = {
    "Ocp-Apim-Subscription-Key": "7594a5149d5b4e4c9bd1944050990aa6"
}
response = requests.get(
    "https://apim-premium-prod-1161.azure-api.net/customers/customers",
    headers=headers
)
print(response.json())
```

#### Vérifier le monitoring

**Via Application Insights:**
1. Ouvrir le portail Azure
2. Naviguer vers `appi-api-portal-dev-1161`
3. Cliquer sur **Logs**
4. Copier/coller une requête KQL depuis `dashboard-queries.kql`

**Via le script health check:**
```powershell
cd scripts
.\health-check.ps1
```

### 12.3 Ajout d'une nouvelle API

#### Étape 1: Créer l'API dans APIM

**Via Azure Portal:**
1. APIM → Workspaces → Sélectionner workspace
2. APIs → Add API → OpenAPI
3. Uploader la spec OpenAPI ou saisir l'URL
4. Configurer le path, subscription, etc.

**Via Azure CLI:**
```bash
az rest --method put \
  --url "/subscriptions/{subscription-id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiManagement/service/apim-premium-prod-1161/workspaces/workspace-team-a-prod/apis/new-api?api-version=2023-05-01-preview" \
  --body '{
    "properties": {
      "path": "new-api",
      "displayName": "New API",
      "protocols": ["https"],
      "subscriptionRequired": true,
      "format": "openapi+json",
      "value": "{...openapi spec...}"
    }
  }'
```

#### Étape 2: Enregistrer dans API Center

```bash
az rest --method put \
  --url "/subscriptions/{subscription-id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiCenter/services/apic-portal-dev-1161/workspaces/default/apis/new-api?api-version=2024-03-01" \
  --body '{
    "properties": {
      "title": "New API",
      "kind": "rest",
      "summary": "Description de la nouvelle API"
    }
  }'
```

#### Étape 3: Associer à un produit

**Via Azure Portal:**
1. APIM → Products → Sélectionner produit
2. APIs → Add → Sélectionner l'API

**Via Azure CLI:**
```bash
az apim product api add \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161 \
  --product-id team-a-prod \
  --api-id new-api
```

### 12.4 Rotation des clés de souscription

#### Via Azure Portal
1. APIM → Subscriptions
2. Sélectionner la souscription
3. Cliquer sur "Regenerate primary key" ou "Regenerate secondary key"

#### Via Azure CLI
```bash
# Régénérer la clé primaire
az rest --method post \
  --url "/subscriptions/{subscription-id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiManagement/service/apim-premium-prod-1161/subscriptions/{subscription-id}/regeneratePrimaryKey?api-version=2022-08-01"

# Récupérer les nouvelles clés
az rest --method post \
  --url "/subscriptions/{subscription-id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiManagement/service/apim-premium-prod-1161/subscriptions/{subscription-id}/listSecrets?api-version=2022-08-01"
```

#### Best practice pour la rotation
1. Régénérer la clé secondaire
2. Mettre à jour les applications avec la nouvelle clé secondaire
3. Vérifier que les applications fonctionnent
4. Régénérer la clé primaire
5. Mettre à jour les applications avec la nouvelle clé primaire

---

## 13. TROUBLESHOOTING

### 13.1 Problèmes courants de déploiement

#### Erreur: "Resource already exists"

**Symptôme:**
```
Error: A resource with the ID "/subscriptions/.../apim-premium-prod-1161" already exists
```

**Cause:** Ressource créée manuellement ou déploiement précédent interrompu

**Solution:**
```bash
# Importer la ressource dans Terraform
terraform import azurerm_api_management.apim_premium <resource-id>
```

#### Erreur: "MethodNotAllowedInPricingTier"

**Symptôme:**
```
Error: Workspaces are not supported in Developer SKU
```

**Cause:** Tentative de créer des workspaces sur APIM Developer

**Solution:** Les workspaces sont uniquement disponibles sur Premium SKU. Supprimer la configuration des workspaces pour l'instance Developer.

#### Erreur: "Deployment timeout"

**Symptôme:** Terraform attend >60 minutes

**Cause:** Déploiement APIM Premium très long (45-60 minutes)

**Solution:**
```bash
# Augmenter le timeout Terraform
export TF_CLI_ARGS_apply="-timeout=120m"
```

### 13.2 Problèmes d'API

#### API retourne 401 Unauthorized

**Causes possibles:**
1. Clé de souscription manquante
2. Clé de souscription invalide
3. Produit non subscribed

**Vérifications:**
```bash
# Vérifier que la clé est valide
curl -X GET "https://apim-premium-prod-1161.azure-api.net/customers/customers" \
  -H "Ocp-Apim-Subscription-Key: VOTRE_CLE" \
  -v  # Mode verbose pour voir les headers

# Lister les souscriptions
az rest --method get \
  --url "/subscriptions/{subscription-id}/resourceGroups/rg-api-portal-dev/providers/Microsoft.ApiManagement/service/apim-premium-prod-1161/subscriptions?api-version=2022-08-01"
```

#### API retourne 404 Not Found

**Causes possibles:**
1. Path incorrect
2. API non publiée
3. API dans mauvais workspace

**Vérifications:**
```bash
# Lister toutes les APIs
az apim api list \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161

# Vérifier le path de l'API
az apim api show \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161 \
  --api-id customer-api
```

#### API retourne 500 Internal Server Error

**Causes possibles:**
1. Backend indisponible
2. Politique APIM incorrecte
3. Transformation invalide

**Vérifications:**
```bash
# Consulter les logs dans Application Insights
az monitor app-insights query \
  --app appi-api-portal-dev-1161 \
  --analytics-query "exceptions | where timestamp > ago(1h) | order by timestamp desc"

# Vérifier les traces
az monitor app-insights query \
  --app appi-api-portal-dev-1161 \
  --analytics-query "traces | where message contains 'error' | where timestamp > ago(1h)"
```

### 13.3 Problèmes de monitoring

#### Pas de données dans Application Insights

**Causes possibles:**
1. Logger APIM non configuré
2. Diagnostic settings désactivé
3. Délai de propagation

**Vérifications:**
```bash
# Vérifier le logger
az apim logger list \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161

# Vérifier les diagnostic settings
az apim diagnostic list \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161

# Attendre 5-10 minutes pour la propagation des données
```

#### Alertes ne se déclenchent pas

**Causes possibles:**
1. Seuil trop élevé
2. Fenêtre d'évaluation trop courte
3. Métrique incorrecte

**Vérifications:**
```bash
# Lister les alertes
az monitor metrics alert list \
  --resource-group rg-api-portal-dev

# Vérifier l'historique d'une alerte
az monitor metrics alert show \
  --name "APIM Premium - High Error Rate" \
  --resource-group rg-api-portal-dev
```

### 13.4 Problèmes de performance

#### Latence élevée sur les APIs

**Diagnostic:**
```kusto
// Application Insights - Analyse des lenteurs
requests
| where cloud_RoleName startswith "apim"
| where duration > 1000  // >1 seconde
| summarize 
    Count = count(),
    AvgDuration = avg(duration),
    P95 = percentile(duration, 95)
    by operation_Name
| order by P95 desc
```

**Solutions possibles:**
1. Activer le cache APIM
2. Optimiser les backends
3. Ajouter des unités de capacité Premium

#### Capacité APIM saturée

**Symptôme:** Métrique Capacity >80%

**Solutions:**
1. **Scale out:** Ajouter des unités Premium
```bash
az apim update \
  --name apim-premium-prod-1161 \
  --resource-group rg-api-portal-dev \
  --sku-capacity 2  # Augmenter de 1 à 2 unités
```

2. **Optimiser les politiques:**
- Activer le cache
- Réduire la verbosité des logs
- Optimiser les transformations

3. **Multi-région:**
```hcl
resource "azurerm_api_management" "apim_premium" {
  # ...
  additional_location {
    location = "westeurope"
    capacity = 1
  }
}
```

---

## 14. BONNES PRATIQUES

### 14.1 Gestion des APIs

#### Versioning des APIs
```
# Utiliser le path pour les versions
/v1/customers
/v2/customers

# Ou header
api-version: 2024-01-01
```

#### Documentation
- Maintenir les specs OpenAPI à jour
- Ajouter des exemples dans la documentation
- Documenter les codes d'erreur

#### Testing
```bash
# Tests automatisés avec Newman (Postman CLI)
newman run api-tests.json --environment prod.json
```

### 14.2 Sécurité

#### Clés API
- ✅ Rotation régulière (tous les 90 jours)
- ✅ Utiliser Azure Key Vault
- ✅ Ne jamais commiter dans Git
- ✅ Logging des accès

#### Authentification
- ✅ OAuth 2.0 pour production
- ✅ JWT validation
- ✅ Mutual TLS pour partenaires sensibles

#### Rate limiting
```xml
<!-- Rate limiting par souscription -->
<rate-limit-by-key calls="1000" renewal-period="3600" 
    counter-key="@(context.Subscription.Id)" />

<!-- Rate limiting par IP -->
<rate-limit-by-key calls="100" renewal-period="60" 
    counter-key="@(context.Request.IpAddress)" />
```

### 14.3 Performance

#### Cache
```xml
<!-- Cache les réponses GET pendant 1 heure -->
<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
<cache-store duration="3600" />
```

#### Compression
```xml
<set-header name="Accept-Encoding" exists-action="override">
    <value>gzip, deflate</value>
</set-header>
```

#### Connection pooling
- Réutiliser les connexions backend
- Configurer keep-alive

### 14.4 Monitoring

#### Métriques clés à surveiller
1. **Availability:** >99.9%
2. **Latency P95:** <500ms
3. **Error rate:** <1%
4. **Capacity:** <75%

#### Alerting strategy
- **Severity 1 (Critical):** Error rate >10%, Page immédiat
- **Severity 2 (High):** Error rate >5%, Email + SMS
- **Severity 3 (Medium):** Latency >2s, Email
- **Severity 4 (Low):** Capacity >75%, Email

### 14.5 Disaster Recovery

#### Backup
```bash
# Sauvegarder la configuration APIM
az apim backup create \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161 \
  --storage-account-name backupstorage \
  --storage-account-container backups \
  --access-key STORAGE_ACCOUNT_KEY
```

#### Restore
```bash
# Restaurer depuis une sauvegarde
az apim restore \
  --resource-group rg-api-portal-dev \
  --service-name apim-premium-prod-1161 \
  --storage-account-name backupstorage \
  --storage-account-container backups \
  --access-key STORAGE_ACCOUNT_KEY
```

#### Multi-région (Haute disponibilité)
```hcl
resource "azurerm_api_management" "apim_premium" {
  # ...
  additional_location {
    location = "westeurope"
    capacity = 1
  }
  
  additional_location {
    location = "northeurope"
    capacity = 1
  }
}
```

---

## 15. ROADMAP ET ÉVOLUTIONS

### 15.1 Phase 2 - Sécurité avancée (Q2 2026)

#### OAuth 2.0 / OpenID Connect
- [ ] Intégration Azure AD
- [ ] JWT validation sur toutes les APIs
- [ ] Scopes par produit
- [ ] Refresh token handling

#### Azure Key Vault
- [ ] Migration des secrets vers Key Vault
- [ ] Managed Identity pour APIM
- [ ] Rotation automatique des secrets

#### Network Security
- [ ] VNet injection pour APIM Premium
- [ ] Private endpoints
- [ ] WAF (Web Application Firewall)
- [ ] DDoS Protection

### 15.2 Phase 3 - Scalabilité (Q3 2026)

#### Multi-région
- [ ] Réplication dans West Europe
- [ ] Traffic Manager pour load balancing
- [ ] Geo-replication pour API Center

#### Auto-scaling
- [ ] Scaling basé sur les métriques
- [ ] Scale out automatique (2-10 unités)
- [ ] Optimisation des coûts

### 15.3 Phase 4 - DevOps (Q4 2026)

#### CI/CD
- [ ] Pipeline Azure DevOps pour déploiement APIs
- [ ] Tests automatisés (Postman/Newman)
- [ ] Validation OpenAPI dans pipeline
- [ ] Promotion auto Dev → Staging → Prod

#### GitOps
- [ ] Configuration APIM as Code (ARM/Bicep)
- [ ] Versionning des politiques
- [ ] Review process pour changements

#### Observabilité avancée
- [ ] Distributed tracing avec Azure Monitor
- [ ] Business metrics dashboards
- [ ] Anomaly detection ML
- [ ] Predictive scaling

### 15.4 Phase 5 - Gouvernance (2027)

#### API Lifecycle Management
- [ ] Processus d'approbation pour nouvelles APIs
- [ ] Gestion des dépréciations
- [ ] Breaking changes detection
- [ ] API health scoring

#### Compliance
- [ ] GDPR compliance checking
- [ ] PII data detection
- [ ] Audit trails enrichis
- [ ] Compliance reports automatiques

---

## 16. RÉFÉRENCES ET DOCUMENTATION

### 16.1 Documentation Microsoft

#### Azure API Management
- [Documentation officielle](https://learn.microsoft.com/en-us/azure/api-management/)
- [Workspaces (Preview)](https://learn.microsoft.com/en-us/azure/api-management/workspaces-overview)
- [Best practices](https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-deploy-multi-region)
- [Policies reference](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)

#### Azure API Center
- [Documentation officielle](https://learn.microsoft.com/en-us/azure/api-center/)
- [API Inventory](https://learn.microsoft.com/en-us/azure/api-center/set-up-api-center)
- [Governance](https://learn.microsoft.com/en-us/azure/api-center/govern-apis)

#### Application Insights
- [Documentation officielle](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Kusto Query Language (KQL)](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)

### 16.2 Terraform

- [Provider AzureRM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Resource: azurerm_api_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management)
- [Best practices Terraform](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

### 16.3 Outils

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [PowerShell for Azure](https://learn.microsoft.com/en-us/powershell/azure/)
- [Postman](https://www.postman.com/)
- [OpenAPI Specification](https://swagger.io/specification/)

### 16.4 Communauté

- [Azure API Management - GitHub](https://github.com/Azure/api-management-samples)
- [Tech Community](https://techcommunity.microsoft.com/t5/azure-api-management/bd-p/AzureAPIManagement)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/azure-api-management)

---

## 📊 ANNEXES

### A. Architecture Decision Records (ADR)

#### ADR-001: Choix du SKU Premium pour APIM Production
**Date:** 2026-01-15  
**Status:** Accepté  
**Contexte:** Besoin de workspaces pour isolation des équipes  
**Décision:** Utiliser Premium SKU malgré le coût  
**Conséquences:** Coût mensuel ~2000€, mais fonctionnalités essentielles (workspaces, multi-région, SLA 99.95%)

#### ADR-002: Backend Terraform local vs Azure Storage
**Date:** 2026-01-20  
**Status:** Temporaire  
**Contexte:** Problèmes d'authentification sur Storage Account  
**Décision:** Utiliser backend local temporairement  
**Conséquences:** Risque de perte state, pas de collaboration, à migrer vers Azure Storage

#### ADR-003: ARM Templates pour workspaces
**Date:** 2026-01-22  
**Status:** Accepté  
**Contexte:** Provider Terraform ne supporte pas les workspaces APIM  
**Décision:** Utiliser ARM Templates via azurerm_resource_group_template_deployment  
**Conséquences:** Syntaxe JSON imbriquée, mais support des APIs Preview

### B. Coûts estimés

| Ressource | SKU | Quantité | Coût mensuel (EUR) | Coût annuel (EUR) |
|-----------|-----|----------|-------------------|-------------------|
| APIM Premium | Premium_1 | 1 unité | 2,000 | 24,000 |
| APIM Developer | Developer_1 | 1 unité | 0 (non-prod) | 0 |
| API Center | Free | 1 | 0 | 0 |
| Application Insights | Pay-as-you-go | ~10GB/mois | 20 | 240 |
| Log Analytics | PerGB2018 | ~5GB/mois | 10 | 120 |
| Storage (Terraform state) | Standard_LRS | 1GB | 0.02 | 0.24 |
| **TOTAL** | | | **~2,030 EUR/mois** | **~24,360 EUR/an** |

**Note:** Prix indicatifs France Central, hors taxes, pouvant varier.

### C. Glossaire

| Terme | Définition |
|-------|------------|
| **APIM** | Azure API Management |
| **API Center** | Service Azure pour cataloguer et gouverner les APIs |
| **Workspace** | Isolation logique des APIs dans APIM Premium |
| **SKU** | Stock Keeping Unit - niveau de service (Premium, Developer, etc.) |
| **Gateway** | Point d'entrée pour les appels API |
| **Backend** | Service réel exposé via APIM |
| **Policy** | Règle de transformation/sécurité appliquée aux APIs |
| **Subscription** | Clé d'accès pour consommer un produit API |
| **Product** | Regroupement logique d'APIs |
| **Sampling** | Pourcentage de requêtes enregistrées dans Application Insights |
| **KQL** | Kusto Query Language - langage de requête pour Log Analytics |

---

## 📅 CHANGELOG

### Version 1.0.1 - 2026-02-02
- ✅ Renommage du document: ETAT-DE-LART.md → SOLUTION.md
- ✅ Nettoyage du repository (suppression de 7 fichiers redondants)
- ✅ Consolidation de la documentation

### Version 1.0.0 - 2026-02-02
- ✅ Déploiement initial de l'infrastructure Terraform
- ✅ Configuration APIM Premium avec 3 workspaces
- ✅ Déploiement APIM Developer
- ✅ Configuration Azure API Center
- ✅ Intégration Application Insights et Log Analytics
- ✅ Création de 3 APIs de démonstration
- ✅ Configuration des portails développeur
- ✅ Mise en place de 4 alertes de monitoring
- ✅ Création de scripts d'automatisation PowerShell
- ✅ Documentation complète

---

**Document maintenu par:** Équipe Infrastructure  
**Dernière mise à jour:** 2 février 2026  
**Prochaine révision:** Mai 2026  
**Contact:** dev@votredomaine.com
