# Script de vérification de santé des APIs
# Exécutez ce script régulièrement pour vérifier l'état des APIs

Write-Host"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏥 Health Check - API Portal" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Cyan

# Vérifier APIM Premium
$apimPremiumStatus = az apim show --name apim-premium-prod-1161 --resource-group rg-api-portal-dev --query provisioningState -o tsv
Write-Host "APIM Premium: $apimPremiumStatus" -ForegroundColor ($apimPremiumStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier APIM Developer
$apimDevStatus = az apim show --name apim-developer-dev-1161 --resource-group rg-api-portal-dev --query provisioningState -o tsv
Write-Host "APIM Developer: $apimDevStatus" -ForegroundColor ($apimDevStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier Application Insights
$appInsightsStatus = az monitor app-insights component show --app appi-api-portal-dev-1161 --resource-group rg-api-portal-dev --query provisioningState -o tsv
Write-Host "Application Insights: $appInsightsStatus" -ForegroundColor ($appInsightsStatus -eq 'Succeeded' ? 'Green' : 'Red')

# Vérifier les APIs
Write-Host "
📱 APIs enregistrées:" -ForegroundColor Yellow
az apim api list --resource-group rg-api-portal-dev --service-name apim-premium-prod-1161 --query "[].{Name:displayName, Path:path, Id:name}" --output table

Write-Host "
✅ Health check terminé
" -ForegroundColor Green
