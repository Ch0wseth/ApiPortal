#Requires -Version 7.0

<#
.SYNOPSIS
    Configure des APIs d'exemple et enregistre dans API Center
.DESCRIPTION
    Ce script crée des APIs d'exemple dans les workspaces APIM et les enregistre dans API Center
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-api-portal-dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimPremiumName = "apim-premium-prod-1161",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiCenterName = "apic-portal-dev-1161"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Configuration des APIs de démonstration    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Récupérer la subscription ID
$subscriptionId = az account show --query id -o tsv
Write-Host "📋 Subscription ID: $subscriptionId" -ForegroundColor Gray

# Définir les workspaces
$workspaceTeamA = "workspace-team-a-prod"
$workspaceTeamB = "workspace-team-b-prod"
$workspacePartners = "workspace-partners-prod"

# 1. Créer une API d'exemple dans le workspace Team A
Write-Host "`n📱 Création de l'API Customer Management (Workspace Team A)..." -ForegroundColor Yellow

$apiCustomers = @"
{
  "openapi": "3.0.1",
  "info": {
    "title": "Customer Management API",
    "description": "API pour gérer les clients",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "https://api.example.com/customers"
    }
  ],
  "paths": {
    "/customers": {
      "get": {
        "summary": "Liste tous les clients",
        "responses": {
          "200": {
            "description": "Liste des clients"
          }
        }
      },
      "post": {
        "summary": "Créer un nouveau client",
        "responses": {
          "201": {
            "description": "Client créé"
          }
        }
      }
    },
    "/customers/{id}": {
      "get": {
        "summary": "Obtenir un client par ID",
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Détails du client"
          }
        }
      }
    }
  }
}
"@

$apiCustomers | Out-File -FilePath "customer-api.json" -Encoding UTF8

# Créer l'API dans le workspace Team A via API REST
Write-Host "Création de l'API Customer Management dans le workspace Team A..." -ForegroundColor Gray

$apiUrl = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimPremiumName/workspaces/$workspaceTeamA/apis/customer-api?api-version=2023-05-01-preview"

$apiBody = @"
{
  "properties": {
    "path": "customers",
    "displayName": "Customer Management API",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "format": "openapi+json",
    "value": $(Get-Content "customer-api.json" -Raw | ConvertTo-Json)
  }
}
"@

az rest --method put --url $apiUrl --body $apiBody --headers "Content-Type=application/json" 2>$null

Write-Host "✅ API Customer Management créée dans workspace-team-a-prod" -ForegroundColor Green

# 2. Créer une API Partners
Write-Host "`n📱 Création de l'API Partner Integration (Workspace Partners)..." -ForegroundColor Yellow

$apiPartners = @"
{
  "openapi": "3.0.1",
  "info": {
    "title": "Partner Integration API",
    "description": "API pour les intégrations partenaires",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "https://api.example.com/partners"
    }
  ],
  "paths": {
    "/webhook": {
      "post": {
        "summary": "Webhook pour notifications partenaires",
        "responses": {
          "200": {
            "description": "Webhook reçu"
          }
        }
      }
    },
    "/orders": {
      "get": {
        "summary": "Liste des commandes partenaires",
        "responses": {
          "200": {
            "description": "Liste des commandes"
          }
        }
      }
    }
  }
}
"@

$apiPartners | Out-File -FilePath "partner-api.json" -Encoding UTF8

# Créer l'API dans le workspace Partners via API REST
Write-Host "Création de l'API Partner Integration dans le workspace Partners..." -ForegroundColor Gray

$apiUrlPartners = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimPremiumName/workspaces/$workspacePartners/apis/partner-api?api-version=2023-05-01-preview"

$apiBodyPartners = @"
{
  "properties": {
    "path": "partners",
    "displayName": "Partner Integration API",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "format": "openapi+json",
    "value": $(Get-Content "partner-api.json" -Raw | ConvertTo-Json)
  }
}
"@

az rest --method put --url $apiUrlPartners --body $apiBodyPartners --headers "Content-Type=application/json" 2>$null

Write-Host "✅ API Partner Integration créée dans workspace-partners-prod" -ForegroundColor Green

# 3. Créer une API Analytics pour Team B
Write-Host "`n📱 Création de l'API Analytics (Workspace Team B)..." -ForegroundColor Yellow

$apiAnalytics = @"
{
  "openapi": "3.0.1",
  "info": {
    "title": "Analytics API",
    "description": "API pour les analytics et rapports",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "https://api.example.com/analytics"
    }
  ],
  "paths": {
    "/reports": {
      "get": {
        "summary": "Obtenir les rapports",
        "responses": {
          "200": {
            "description": "Liste des rapports"
          }
        }
      }
    },
    "/metrics": {
      "get": {
        "summary": "Obtenir les métriques",
        "responses": {
          "200": {
            "description": "Métriques en temps réel"
          }
        }
      }
    }
  }
}
"@

$apiAnalytics | Out-File -FilePath "analytics-api.json" -Encoding UTF8

# Créer l'API dans le workspace Team B via API REST
Write-Host "Création de l'API Analytics dans le workspace Team B..." -ForegroundColor Gray

$apiUrlAnalytics = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimPremiumName/workspaces/$workspaceTeamB/apis/analytics-api?api-version=2023-05-01-preview"

$apiBodyAnalytics = @"
{
  "properties": {
    "path": "analytics",
    "displayName": "Analytics API",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "format": "openapi+json",
    "value": $(Get-Content "analytics-api.json" -Raw | ConvertTo-Json)
  }
}
"@

az rest --method put --url $apiUrlAnalytics --body $apiBodyAnalytics --headers "Content-Type=application/json" 2>$null

Write-Host "✅ API Analytics créée dans workspace-team-b-prod" -ForegroundColor Green

# 4. Enregistrer les APIs dans API Center via API REST
Write-Host "`n📊 Enregistrement des APIs dans API Center..." -ForegroundColor Yellow

# Customer API
Write-Host "  Enregistrement de Customer Management API..." -ForegroundColor Gray
$apiCenterUrl1 = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiCenter/services/$ApiCenterName/workspaces/default/apis/customer-api?api-version=2024-03-01"
$apiCenterBody1 = @"
{
  "properties": {
    "title": "Customer Management API",
    "kind": "rest",
    "summary": "API pour la gestion des clients",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://$ApimPremiumName.azure-api.net/customers"
      }
    ]
  }
}
"@
az rest --method put --url $apiCenterUrl1 --body $apiCenterBody1 --headers "Content-Type=application/json" 2>$null

# Partner API
Write-Host "  Enregistrement de Partner Integration API..." -ForegroundColor Gray
$apiCenterUrl2 = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiCenter/services/$ApiCenterName/workspaces/default/apis/partner-api?api-version=2024-03-01"
$apiCenterBody2 = @"
{
  "properties": {
    "title": "Partner Integration API",
    "kind": "rest",
    "summary": "API pour l'intégration partenaires",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://$ApimPremiumName.azure-api.net/partners"
      }
    ]
  }
}
"@
az rest --method put --url $apiCenterUrl2 --body $apiCenterBody2 --headers "Content-Type=application/json" 2>$null

# Analytics API
Write-Host "  Enregistrement de Analytics API..." -ForegroundColor Gray
$apiCenterUrl3 = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiCenter/services/$ApiCenterName/workspaces/default/apis/analytics-api?api-version=2024-03-01"
$apiCenterBody3 = @"
{
  "properties": {
    "title": "Analytics API",
    "kind": "rest",
    "summary": "API pour les analytics et rapports",
    "externalDocumentation": [
      {
        "title": "Documentation",
        "url": "https://$ApimPremiumName.azure-api.net/analytics"
      }
    ]
  }
}
"@
az rest --method put --url $apiCenterUrl3 --body $apiCenterBody3 --headers "Content-Type=application/json" 2>$null

Write-Host "✅ APIs enregistrées dans API Center" -ForegroundColor Green

# Nettoyage
Remove-Item "customer-api.json" -Force -ErrorAction SilentlyContinue
Remove-Item "partner-api.json" -Force -ErrorAction SilentlyContinue
Remove-Item "analytics-api.json" -Force -ErrorAction SilentlyContinue

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        ✅ Configuration terminée !            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 APIs créées:" -ForegroundColor Cyan
Write-Host "  • Customer Management API (workspace-team-a-prod)" -ForegroundColor White
Write-Host "  • Partner Integration API (workspace-partners-prod)" -ForegroundColor White
Write-Host "  • Analytics API (workspace-team-b-prod)" -ForegroundColor White
Write-Host "`n🌐 Testez les APIs sur:" -ForegroundColor Cyan
Write-Host "  https://$ApimPremiumName.developer.azure-api.net`n" -ForegroundColor White
