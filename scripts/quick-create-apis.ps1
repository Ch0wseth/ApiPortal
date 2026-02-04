#Requires -Version 7.0

$ErrorActionPreference = "Stop"

Write-Host "`n=== Création des APIs dans les Workspaces APIM ===" -ForegroundColor Cyan

# Configuration
$rgName = "rg-api-portal-dev"
$apimName = "apim-premium-prod-1161"
$apiCenterName = "apic-portal-dev-1161"
$subId = (az account show --query id -o tsv)

Write-Host "Subscription: $subId`n" -ForegroundColor Gray

# Fonction pour créer une API
function Create-WorkspaceAPI {
    param(
        [string]$WorkspaceName,
        [string]$ApiId,
        [string]$DisplayName,
        [string]$Path,
        [string]$Description
    )
    
    Write-Host "Création de $DisplayName dans $WorkspaceName..." -ForegroundColor Yellow
    
    $body = "{`"properties`":{`"path`":`"$Path`",`"displayName`":`"$DisplayName`",`"description`":`"$Description`",`"protocols`":[`"https`"],`"subscriptionRequired`":true,`"serviceUrl`":`"https://api.example.com/$Path`"}}"
    
    $url = "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/$WorkspaceName/apis/$ApiId`?api-version=2023-05-01-preview"
    
    $result = az rest --method PUT --url $url --body $body --headers "Content-Type=application/json" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $DisplayName créée" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ❌ Erreur: $result" -ForegroundColor Red
        return $false
    }
}

# Fonction pour ajouter une opération
function Add-APIOperation {
    param(
        [string]$WorkspaceName,
        [string]$ApiId,
        [string]$OperationId,
        [string]$DisplayName,
        [string]$Method,
        [string]$UrlTemplate,
        [string]$Description
    )
    
    Write-Host "  Ajout de $Method $UrlTemplate..." -ForegroundColor Gray
    
    $body = "{`"properties`":{`"displayName`":`"$DisplayName`",`"method`":`"$Method`",`"urlTemplate`":`"$UrlTemplate`",`"description`":`"$Description`"}}"
    
    $url = "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/$WorkspaceName/apis/$ApiId/operations/$OperationId`?api-version=2023-05-01-preview"
    
    az rest --method PUT --url $url --body $body --headers "Content-Type=application/json" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✅ Opération ajoutée" -ForegroundColor Green
    }
}

# Fonction pour enregistrer dans API Center
function Register-InAPICenter {
    param(
        [string]$ApiId,
        [string]$Title,
        [string]$Description
    )
    
    Write-Host "Enregistrement de $Title dans API Center..." -ForegroundColor Gray
    
    az apic api create `
        --resource-group $rgName `
        --service-name $apiCenterName `
        --api-id $ApiId `
        --title $Title `
        --kind rest `
        --description $Description `
        -o none 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Enregistré dans API Center" -ForegroundColor Green
    }
}

# API 1: Customer Management (Team A)
Write-Host "`n📱 API 1: Customer Management" -ForegroundColor Cyan
Create-WorkspaceAPI -WorkspaceName "workspace-team-a-prod" -ApiId "customer-api" -DisplayName "Customer Management API" -Path "customers" -Description "API pour la gestion des clients"
Add-APIOperation -WorkspaceName "workspace-team-a-prod" -ApiId "customer-api" -OperationId "get-customers" -DisplayName "List Customers" -Method "GET" -UrlTemplate "/" -Description "Récupérer la liste des clients"
Add-APIOperation -WorkspaceName "workspace-team-a-prod" -ApiId "customer-api" -OperationId "get-customer-by-id" -DisplayName "Get Customer" -Method "GET" -UrlTemplate "/{id}" -Description "Obtenir un client par ID"
Register-InAPICenter -ApiId "customer-api" -Title "Customer Management API" -Description "API pour la gestion des clients - Workspace Team A"

# API 2: Partner Integration (Partners)
Write-Host "`n📱 API 2: Partner Integration" -ForegroundColor Cyan
Create-WorkspaceAPI -WorkspaceName "workspace-partners-prod" -ApiId "partner-api" -DisplayName "Partner Integration API" -Path "partners" -Description "API pour l'intégration avec les partenaires"
Add-APIOperation -WorkspaceName "workspace-partners-prod" -ApiId "partner-api" -OperationId "post-webhook" -DisplayName "Partner Webhook" -Method "POST" -UrlTemplate "/webhook" -Description "Recevoir des notifications"
Add-APIOperation -WorkspaceName "workspace-partners-prod" -ApiId "partner-api" -OperationId "get-orders" -DisplayName "Get Orders" -Method "GET" -UrlTemplate "/orders" -Description "Liste des commandes"
Register-InAPICenter -ApiId "partner-api" -Title "Partner Integration API" -Description "API pour l'intégration partenaires - Workspace Partners"

# API 3: Analytics (Team B)
Write-Host "`n📱 API 3: Analytics API" -ForegroundColor Cyan
Create-WorkspaceAPI -WorkspaceName "workspace-team-b-prod" -ApiId "analytics-api" -DisplayName "Analytics API" -Path "analytics" -Description "API pour les analytics et reporting"
Add-APIOperation -WorkspaceName "workspace-team-b-prod" -ApiId "analytics-api" -OperationId "get-reports" -DisplayName "Get Reports" -Method "GET" -UrlTemplate "/reports" -Description "Rapports analytiques"
Add-APIOperation -WorkspaceName "workspace-team-b-prod" -ApiId "analytics-api" -OperationId "get-metrics" -DisplayName "Get Metrics" -Method "GET" -UrlTemplate "/metrics" -Description "Métriques en temps réel"
Register-InAPICenter -ApiId "analytics-api" -Title "Analytics API" -Description "API pour analytics et reporting - Workspace Team B"

Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║    ✅ Configuration terminée!         ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📊 Résumé des APIs créées:" -ForegroundColor Cyan
Write-Host "  1. Customer Management API -> workspace-team-a-prod" -ForegroundColor White
Write-Host "  2. Partner Integration API -> workspace-partners-prod" -ForegroundColor White
Write-Host "  3. Analytics API -> workspace-team-b-prod" -ForegroundColor White
Write-Host "`n🌐 Testez sur: https://$apimName.developer.azure-api.net`n" -ForegroundColor White
