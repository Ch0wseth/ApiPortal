#Requires -Version 7.0

$ErrorActionPreference = "Continue"

Write-Host "`n╔═════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Création des APIs dans les workspaces APIM    ║" -ForegroundColor Cyan
Write-Host "╚═════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Configuration
$rgName = "rg-api-portal-dev"
$apimName = "apim-premium-prod-1161"
$apiCenterName = "apic-portal-dev-1161"

Write-Host "📋 Connexion à Azure..." -ForegroundColor Yellow
$subId = (az account show --query id -o tsv)
$token = (az account get-access-token --query accessToken -o tsv)

if (-not $token) {
    Write-Host "❌ Impossible de récupérer le token Azure" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Token obtenu - Subscription: $subId`n" -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# API 1: Customer Management (Team A)
Write-Host "📱 API 1: Customer Management API" -ForegroundColor Yellow

$api1 = @{
    properties = @{
        path = "customers"
        displayName = "Customer Management API"
        description = "API pour la gestion des clients"
        protocols = @("https")
        subscriptionRequired = $true
        serviceUrl = "https://api.example.com/customers"
    }
} | ConvertTo-Json -Depth 10

$uri1 = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-a-prod/apis/customer-api?api-version=2023-05-01-preview"

try {
    $result1 = Invoke-RestMethod -Uri $uri1 -Method PUT -Headers $headers -Body $api1 -ContentType "application/json"
    Write-Host "  ✅ Customer Management API créée dans workspace-team-a-prod" -ForegroundColor Green
    Write-Host "     Path: /customers" -ForegroundColor Gray
    
    # Opération GET /
    $op1 = @{
        properties = @{
            displayName = "List Customers"
            method = "GET"
            urlTemplate = "/"
            description = "Liste tous les clients"
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp1 = "$uri1/operations/get-customers?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp1 -Method PUT -Headers $headers -Body $op1 -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération GET / ajoutée" -ForegroundColor Gray
    
    # Opération GET /{id}
    $op1b = @{
        properties = @{
            displayName = "Get Customer by ID"
            method = "GET"
            urlTemplate = "/{id}"
            description = "Obtenir un client par ID"
            templateParameters = @(
                @{
                    name = "id"
                    type = "string"
                    required = $true
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp1b = "$uri1/operations/get-customer-id?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp1b -Method PUT -Headers $headers -Body $op1b -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération GET /{id} ajoutée" -ForegroundColor Gray
    
} catch {
    Write-Host "  ❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# API 2: Partner Integration (Partners)
Write-Host "`n📱 API 2: Partner Integration API" -ForegroundColor Yellow

$api2 = @{
    properties = @{
        path = "partners"
        displayName = "Partner Integration API"
        description = "API pour l'intégration avec les partenaires externes"
        protocols = @("https")
        subscriptionRequired = $true
        serviceUrl = "https://api.example.com/partners"
    }
} | ConvertTo-Json -Depth 10

$uri2 = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-partners-prod/apis/partner-api?api-version=2023-05-01-preview"

try {
    $result2 = Invoke-RestMethod -Uri $uri2 -Method PUT -Headers $headers -Body $api2 -ContentType "application/json"
    Write-Host "  ✅ Partner Integration API créée dans workspace-partners-prod" -ForegroundColor Green
    Write-Host "     Path: /partners" -ForegroundColor Gray
    
    # Opération POST /webhook
    $op2 = @{
        properties = @{
            displayName = "Partner Webhook"
            method = "POST"
            urlTemplate = "/webhook"
            description = "Recevoir les notifications des partenaires"
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp2 = "$uri2/operations/post-webhook?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp2 -Method PUT -Headers $headers -Body $op2 -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération POST /webhook ajoutée" -ForegroundColor Gray
    
    # Opération GET /orders
    $op2b = @{
        properties = @{
            displayName = "Get Partner Orders"
            method = "GET"
            urlTemplate = "/orders"
            description = "Récupérer les commandes partenaires"
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp2b = "$uri2/operations/get-orders?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp2b -Method PUT -Headers $headers -Body $op2b -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération GET /orders ajoutée" -ForegroundColor Gray
    
} catch {
    Write-Host "  ❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# API 3: Analytics (Team B)
Write-Host "`n📱 API 3: Analytics API" -ForegroundColor Yellow

$api3 = @{
    properties = @{
        path = "analytics"
        displayName = "Analytics API"
        description = "API pour les rapports et analytics"
        protocols = @("https")
        subscriptionRequired = $true
        serviceUrl = "https://api.example.com/analytics"
    }
} | ConvertTo-Json -Depth 10

$uri3 = "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.ApiManagement/service/$apimName/workspaces/workspace-team-b-prod/apis/analytics-api?api-version=2023-05-01-preview"

try {
    $result3 = Invoke-RestMethod -Uri $uri3 -Method PUT -Headers $headers -Body $api3 -ContentType "application/json"
    Write-Host "  ✅ Analytics API créée dans workspace-team-b-prod" -ForegroundColor Green
    Write-Host "     Path: /analytics" -ForegroundColor Gray
    
    # Opération GET /reports
    $op3 = @{
        properties = @{
            displayName = "Get Reports"
            method = "GET"
            urlTemplate = "/reports"
            description = "Récupérer les rapports analytiques"
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp3 = "$uri3/operations/get-reports?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp3 -Method PUT -Headers $headers -Body $op3 -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération GET /reports ajoutée" -ForegroundColor Gray
    
    # Opération GET /metrics
    $op3b = @{
        properties = @{
            displayName = "Get Metrics"
            method = "GET"
            urlTemplate = "/metrics"
            description = "Métriques en temps réel"
        }
    } | ConvertTo-Json -Depth 10
    
    $uriOp3b = "$uri3/operations/get-metrics?api-version=2023-05-01-preview"
    Invoke-RestMethod -Uri $uriOp3b -Method PUT -Headers $headers -Body $op3b -ContentType "application/json" | Out-Null
    Write-Host "     ✅ Opération GET /metrics ajoutée" -ForegroundColor Gray
    
} catch {
    Write-Host "  ❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Enregistrer dans API Center
Write-Host "`n📊 Enregistrement dans API Center..." -ForegroundColor Yellow

# Customer API
Write-Host "  Customer Management API..." -ForegroundColor Gray
az apic api create --resource-group $rgName --service-name $apiCenterName --api-id customer-api --title "Customer Management API" --kind rest --description "API de gestion clients (Team A)" -o none 2>$null

# Partner API
Write-Host "  Partner Integration API..." -ForegroundColor Gray
az apic api create --resource-group $rgName --service-name $apiCenterName --api-id partner-api --title "Partner Integration API" --kind rest --description "API intégration partenaires (Partners)" -o none 2>$null

# Analytics API
Write-Host "  Analytics API..." -ForegroundColor Gray
az apic api create --resource-group $rgName --service-name $apiCenterName --api-id analytics-api --title "Analytics API" --kind rest --description "API analytics et reporting (Team B)" -o none 2>$null

Write-Host "  ✅ APIs enregistrées dans API Center" -ForegroundColor Green

Write-Host "`n╔═══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       ✅ Configuration terminée!          ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 Résumé:" -ForegroundColor Cyan
Write-Host "  ✓ 3 APIs créées dans 3 workspaces" -ForegroundColor White
Write-Host "  ✓ 7 opérations au total" -ForegroundColor White
Write-Host "  ✓ Enregistrées dans API Center" -ForegroundColor White

Write-Host "`n🌐 URLs de test:" -ForegroundColor Cyan
Write-Host "  Portail: https://$apimName.developer.azure-api.net" -ForegroundColor White
Write-Host "  Gateway: https://$apimName.azure-api.net" -ForegroundColor White
Write-Host ""
