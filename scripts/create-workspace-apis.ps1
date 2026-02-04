#Requires -Version 7.0

<#
.SYNOPSIS
    Créer des APIs de démonstration dans les workspaces APIM
#>

$ErrorActionPreference = "Stop"

Write-Host "`n=== Création des APIs de démonstration ===" -ForegroundColor Cyan

# Configuration
$rgName = "rg-api-portal-dev"
$apimName = "apim-premium-prod-1161"
$apiCenterName = "apic-portal-dev-1161"

# Vérifier la connexion Azure
Write-Host "`n📋 Vérification de la connexion Azure..." -ForegroundColor Yellow
try {
    $subId = az account show --query id -o tsv
    if (-not $subId) {
        Write-Host "❌ Non connecté à Azure. Exécutez 'az login'" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Connecté - Subscription: $subId" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de connexion Azure" -ForegroundColor Red
    exit 1
}

# API 1: Customer Management API (Team A)
Write-Host "`n📱 API 1: Customer Management (Team A)" -ForegroundColor Yellow

$api1Body = @"
{
  "properties": {
    "path": "customers",
    "displayName": "Customer Management API",
    "description": "API pour la gestion des clients",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "serviceUrl": "https://api.example.com/customers"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-a-prod/apis/customer-api?api-version=2023-05-01-preview" `
    --body $api1Body `
    -o none 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Customer Management API créée" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Erreur lors de la création" -ForegroundColor Yellow
}

# Ajouter une opération GET /customers
$op1Body = @"
{
  "properties": {
    "displayName": "List Customers",
    "method": "GET",
    "urlTemplate": "/",
    "description": "Récupérer la liste des clients"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-a-prod/apis/customer-api/operations/get-customers?api-version=2023-05-01-preview" `
    --body $op1Body `
    -o none 2>&1 | Out-Null

Write-Host "  ✅ Opération GET /customers ajoutée" -ForegroundColor Green

# API 2: Partner Integration API (Partners)
Write-Host "`n📱 API 2: Partner Integration (Partners)" -ForegroundColor Yellow

$api2Body = @"
{
  "properties": {
    "path": "partners",
    "displayName": "Partner Integration API",
    "description": "API pour l'intégration avec les partenaires",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "serviceUrl": "https://api.example.com/partners"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-partners-prod/apis/partner-api?api-version=2023-05-01-preview" `
    --body $api2Body `
    -o none 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Partner Integration API créée" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Erreur lors de la création" -ForegroundColor Yellow
}

# Ajouter une opération POST /webhook
$op2Body = @"
{
  "properties": {
    "displayName": "Partner Webhook",
    "method": "POST",
    "urlTemplate": "/webhook",
    "description": "Recevoir des notifications des partenaires"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-partners-prod/apis/partner-api/operations/post-webhook?api-version=2023-05-01-preview" `
    --body $op2Body `
    -o none 2>&1 | Out-Null

Write-Host "  ✅ Opération POST /webhook ajoutée" -ForegroundColor Green

# API 3: Analytics API (Team B)
Write-Host "`n📱 API 3: Analytics API (Team B)" -ForegroundColor Yellow
 
$api3Body = @"
{
  "properties": {
    "path": "analytics",
    "displayName": "Analytics API",
    "description": "API pour les analytics et reporting",
    "protocols": ["https"],
    "subscriptionRequired": true,
    "serviceUrl": "https://api.example.com/analytics"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-b-prod/apis/analytics-api?api-version=2023-05-01-preview" `
    --body $api3Body `
    -o none 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Analytics API créée" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Erreur lors de la création" -ForegroundColor Yellow
}

# Ajouter une opération GET /reports
$op3Body = @"
{
  "properties": {
    "displayName": "Get Reports",
    "method": "GET",
    "urlTemplate": "/reports",
    "description": "Récupérer les rapports analytiques"
  }
}
"@

az rest --method PUT `
    --url "/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-b-prod/apis/analytics-api/operations/get-reports?api-version=2023-05-01-preview" `
    --body $op3Body `
    -o none 2>&1 | Out-Null

Write-Host "  ✅ Opération GET /reports ajoutée" -ForegroundColor Green

# Enregistrer dans API Center
Write-Host "`n📊 Enregistrement dans API Center..." -ForegroundColor Yellow

# Customer API
Write-Host "  Enregistrement de Customer Management API..." -ForegroundColor Gray
az apic api create `
    --resource-group $rgName `
    --service-name $apiCenterName `
    --api-id customer-api `
    --title "Customer Management API" `
    --kind rest `
    --description "API pour la gestion des clients - Workspace Team A" `
    -o none 2>&1 | Out-Null

# Partner API
Write-Host "  Enregistrement de Partner Integration API..." -ForegroundColor Gray
az apic api create `
    --resource-group $rgName `
    --service-name $apiCenterName `
    --api-id partner-api `
    --title "Partner Integration API" `
    --kind rest `
    --description "API pour l'intégration partenaires - Workspace Partners" `
    -o none 2>&1 | Out-Null

# Analytics API
Write-Host "  Enregistrement de Analytics API..." -ForegroundColor Gray
az apic api create `
    --resource-group $rgName `
    --service-name $apiCenterName `
    --api-id analytics-api `
    --title "Analytics API" `
    --kind rest `
    --description "API pour analytics et reporting - Workspace Team B" `
    -o none 2>&1 | Out-Null

Write-Host "`n✅ APIs enregistrées dans API Center" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         Configuration terminée !           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📋 APIs créées:" -ForegroundColor Cyan
Write-Host "  1. Customer Management API" -ForegroundColor White
Write-Host "     Workspace: workspace-team-a-prod" -ForegroundColor Gray
Write-Host "     Path: /customers" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Partner Integration API" -ForegroundColor White
Write-Host "     Workspace: workspace-partners-prod" -ForegroundColor Gray  
Write-Host "     Path: /partners" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Analytics API" -ForegroundColor White
Write-Host "     Workspace: workspace-team-b-prod" -ForegroundColor Gray
Write-Host "     Path: /analytics" -ForegroundColor Gray

Write-Host "`n🌐 Portail développeur:" -ForegroundColor Cyan
Write-Host "  https://$apimName.developer.azure-api.net" -ForegroundColor White

Write-Host "`n📊 API Center:" -ForegroundColor Cyan
Write-Host "  https://portal.azure.com/#@/resource/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiCenter/services/$apiCenterName" -ForegroundColor White

Write-Host ""
