#Requires -Version 7.0

<#
.SYNOPSIS
    Configure le monitoring et les alertes pour les APIs
.DESCRIPTION
    Ce script configure Application Insights dashboards et alertes de monitoring
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-api-portal-dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimPremiumName = "apim-premium-prod-1161",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimDeveloperName = "apim-developer-dev-1161",
    
    [Parameter(Mandatory = $false)]
    [string]$AppInsightsName = "appi-api-portal-dev-1161"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Configuration du Monitoring et Alertes     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Récupérer les IDs des ressources
Write-Host "📊 Récupération des informations des ressources..." -ForegroundColor Yellow

$apimPremiumId = az apim show --name $ApimPremiumName --resource-group $ResourceGroupName --query id -o tsv
$apimDevId = az apim show --name $ApimDeveloperName --resource-group $ResourceGroupName --query id -o tsv
$appInsightsId = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName --query id -o tsv

Write-Host "✅ Ressources identifiées" -ForegroundColor Green

# 1. Créer des alertes pour APIM Premium
Write-Host "`n🔔 Création des alertes pour APIM Premium..." -ForegroundColor Yellow

# Alerte: Taux d'erreur élevé (>5%)
Write-Host "  • Alerte: Taux d'erreur élevé" -ForegroundColor Gray
az monitor metrics alert create `
    --name "APIM Premium - High Error Rate" `
    --resource-group $ResourceGroupName `
    --scopes $apimPremiumId `
    --condition "avg UnsuccessfulRequests > 5" `
    --window-size 5m `
    --evaluation-frequency 1m `
    --description "Alerte quand le taux d'erreur dépasse 5%" `
    --severity 2 2>$null

# Alerte: Temps de réponse élevé (>2s)
Write-Host "  • Alerte: Temps de réponse élevé" -ForegroundColor Gray
az monitor metrics alert create `
    --name "APIM Premium - High Latency" `
    --resource-group $ResourceGroupName `
    --scopes $apimPremiumId `
    --condition "avg Duration > 2000" `
    --window-size 5m `
    --evaluation-frequency 1m `
    --description "Alerte quand la latence dépasse 2 secondes" `
    --severity 3 2>$null

# Alerte: Capacité élevée (>75%)
Write-Host "  • Alerte: Capacité élevée" -ForegroundColor Gray
az monitor metrics alert create `
    --name "APIM Premium - High Capacity" `
    --resource-group $ResourceGroupName `
    --scopes $apimPremiumId `
    --condition "avg Capacity > 75" `
    --window-size 5m `
    --evaluation-frequency 1m `
    --description "Alerte quand la capacité dépasse 75%" `
    --severity 2 2>$null

Write-Host "✅ Alertes APIM Premium créées" -ForegroundColor Green

# 2. Créer des alertes pour APIM Developer
Write-Host "`n🔔 Création des alertes pour APIM Developer..." -ForegroundColor Yellow

az monitor metrics alert create `
    --name "APIM Developer - High Error Rate" `
    --resource-group $ResourceGroupName `
    --scopes $apimDevId `
    --condition "avg UnsuccessfulRequests > 10" `
    --window-size 5m `
    --evaluation-frequency 1m `
    --description "Alerte quand le taux d'erreur dépasse 10%" `
    --severity 3 2>$null

Write-Host "✅ Alertes APIM Developer créées" -ForegroundColor Green

# 3. Créer une requête KQL pour dashboard personnalisé
Write-Host "`n📊 Création des requêtes pour dashboards..." -ForegroundColor Yellow

$dashboardQueries = @"
# REQUÊTES KQL POUR APPLICATION INSIGHTS DASHBOARDS

## 1. Top 10 APIs par nombre de requêtes (dernières 24h)
requests
| where timestamp > ago(24h)
| summarize RequestCount = count() by operation_Name
| top 10 by RequestCount desc
| render barchart

## 2. Temps de réponse moyen par API (dernière heure)
requests
| where timestamp > ago(1h)
| summarize AvgDuration = avg(duration) by operation_Name
| render timechart

## 3. Taux d'erreur par API (dernières 24h)
requests
| where timestamp > ago(24h)
| summarize 
    TotalRequests = count(),
    FailedRequests = countif(success == false)
by operation_Name
| extend ErrorRate = (FailedRequests * 100.0) / TotalRequests
| project operation_Name, ErrorRate, TotalRequests, FailedRequests
| order by ErrorRate desc

## 4. Distribution géographique des requêtes
requests
| where timestamp > ago(24h)
| summarize RequestCount = count() by client_CountryOrRegion
| render piechart

## 5. Performance sur les dernières 24h
requests
| where timestamp > ago(24h)
| summarize 
    P50 = percentile(duration, 50),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99)
by bin(timestamp, 1h)
| render timechart

## 6. Tendance du volume de requêtes
requests
| where timestamp > ago(7d)
| summarize RequestCount = count() by bin(timestamp, 1h)
| render timechart

## 7. Top erreurs 4xx et 5xx
requests
| where timestamp > ago(24h) and success == false
| summarize ErrorCount = count() by resultCode, operation_Name
| order by ErrorCount desc
| take 20

## 8. Dépendances externes - Performance
dependencies
| where timestamp > ago(24h)
| summarize 
    CallCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95)
by target, name
| order by CallCount desc

## 9. Anomalies de trafic (détection automatique)
requests
| where timestamp > ago(7d)
| make-series RequestCount = count() on timestamp step 1h
| extend anomalies = series_decompose_anomalies(RequestCount, 1.5)
| mv-expand timestamp, RequestCount, anomalies
| where anomalies != 0

## 10. Dashboard de santé globale
let period = 1h;
requests
| where timestamp > ago(period)
| summarize 
    TotalRequests = count(),
    SuccessfulRequests = countif(success == true),
    FailedRequests = countif(success == false),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95)
| extend 
    SuccessRate = (SuccessfulRequests * 100.0) / TotalRequests,
    AvgDurationSeconds = AvgDuration / 1000,
    P95DurationSeconds = P95Duration / 1000
| project 
    ["Total Requests"] = TotalRequests,
    ["Success Rate %"] = round(SuccessRate, 2),
    ["Avg Response Time (s)"] = round(AvgDurationSeconds, 3),
    ["P95 Response Time (s)"] = round(P95DurationSeconds, 3)
"@

$dashboardQueries | Out-File -FilePath "dashboard-queries.kql" -Encoding UTF8
Write-Host "✅ Requêtes KQL sauvegardées dans dashboard-queries.kql" -ForegroundColor Green

# 4. Créer un script de vérification de santé
$healthCheckScript = @"
# Script de vérification de santé des APIs
# Exécutez ce script régulièrement pour vérifier l'état des APIs

Write-Host"`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏥 Health Check - API Portal" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Vérifier APIM Premium
`$apimPremiumStatus = az apim show --name $ApimPremiumName --resource-group $ResourceGroupName --query provisioningState -o tsv
Write-Host "APIM Premium: `$apimPremiumStatus" -ForegroundColor (`$apimPremiumStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier APIM Developer
`$apimDevStatus = az apim show --name $ApimDeveloperName --resource-group $ResourceGroupName --query provisioningState -o tsv
Write-Host "APIM Developer: `$apimDevStatus" -ForegroundColor (`$apimDevStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier Application Insights
`$appInsightsStatus = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName --query provisioningState -o tsv
Write-Host "Application Insights: `$appInsightsStatus" -ForegroundColor (`$appInsightsStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier les APIs
Write-Host "`n📱 APIs enregistrées:" -ForegroundColor Yellow
az apim api list --resource-group $ResourceGroupName --service-name $ApimPremiumName --query "[].{Name:displayName, Path:path, Id:name}" --output table

Write-Host "`n✅ Health check terminé`n" -ForegroundColor Green
"@

$healthCheckScript | Out-File -FilePath "health-check.ps1" -Encoding UTF8
Write-Host "✅ Script de health check sauvegardé dans health-check.ps1" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ Monitoring configuré avec succès !     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 Alertes créées:" -ForegroundColor Cyan
Write-Host "  • APIM Premium - High Error Rate (>5%)" -ForegroundColor White
Write-Host "  • APIM Premium - High Latency (>2s)" -ForegroundColor White
Write-Host "  • APIM Premium - High Capacity (>75%)" -ForegroundColor White
Write-Host "  • APIM Developer - High Error Rate (>10%)" -ForegroundColor White

Write-Host "`n📊 Fichiers créés:" -ForegroundColor Cyan
Write-Host "  • dashboard-queries.kql - Requêtes pour dashboards" -ForegroundColor White
Write-Host "  • health-check.ps1 - Script de vérification" -ForegroundColor White

Write-Host "`n🔗 Accès Application Insights:" -ForegroundColor Cyan
Write-Host "  https://portal.azure.com → $AppInsightsName → Logs`n" -ForegroundColor White
