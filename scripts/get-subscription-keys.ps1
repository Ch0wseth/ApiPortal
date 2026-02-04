#Requires -Version 7.0

<#
.SYNOPSIS
    Récupère les clés de souscription des workspaces
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-api-portal-dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimPremiumName = "apim-premium-prod-1161"
)

$ErrorActionPreference = "Stop"

Write-Host "`n🔑 Récupération des clés de souscription...`n" -ForegroundColor Cyan

# Obtenir le subscription ID
$subscriptionId = (az account show --query id -o tsv)

# Liste des souscriptions dans chaque workspace
$workspaces = @(
    @{Name = "workspace-team-a-prod"; SubscriptionId = "team-a-subscription"; DisplayName = "Team A"}
    @{Name = "workspace-partners-prod"; SubscriptionId = "partners-subscription"; DisplayName = "Partners"}
    @{Name = "workspace-team-b-prod"; SubscriptionId = "team-b-subscription"; DisplayName = "Team B"}
)

$results = @()

foreach ($ws in $workspaces) {
    Write-Host "📦 Workspace: $($ws.DisplayName)" -ForegroundColor Yellow
    
    # Lister les souscriptions dans le workspace
    $subsUrl = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimPremiumName/workspaces/$($ws.Name)/subscriptions?api-version=2023-05-01-preview"
    
    $subs = az rest --method get --url $subsUrl | ConvertFrom-Json
    
    if ($subs.value -and $subs.value.Count -gt 0) {
        foreach ($sub in $subs.value) {
            $subName = $sub.name
            Write-Host "  • Souscription: $subName" -ForegroundColor Gray
            
            # Récupérer les secrets
            $secretsUrl = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimPremiumName/workspaces/$($ws.Name)/subscriptions/$subName/listSecrets?api-version=2023-05-01-preview"
            
            try {
                $secrets = az rest --method post --url $secretsUrl | ConvertFrom-Json
                
                $results += [PSCustomObject]@{
                    Workspace = $ws.DisplayName
                    Souscription = $subName
                    PrimaryKey = $secrets.primaryKey
                    SecondaryKey = $secrets.secondaryKey
                }
                
                Write-Host "    ✅ Clés récupérées" -ForegroundColor Green
            }
            catch {
                Write-Host "    ❌ Erreur lors de la récupération des clés" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "  ⚠️  Aucune souscription trouvée" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Afficher les résultats
Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Clés de Souscription               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

foreach ($result in $results) {
    Write-Host "📦 $($result.Workspace) - $($result.Souscription)" -ForegroundColor Yellow
    Write-Host "   Primary Key:   $($result.PrimaryKey)" -ForegroundColor White
    Write-Host "   Secondary Key: $($result.SecondaryKey)" -ForegroundColor Gray
    Write-Host ""
}

# Sauvegarder dans un fichier
$output = @"
# 🔑 CLÉS DE SOUSCRIPTION API MANAGEMENT

## Workspaces et Souscriptions

"@

foreach ($result in $results) {
    $output += @"

### $($result.Workspace)
**Souscription:** $($result.Souscription)

``````
Primary Key:   $($result.PrimaryKey)
Secondary Key: $($result.SecondaryKey)
``````

**Exemple d'utilisation:**
``````bash
curl -X GET "https://$ApimPremiumName.azure-api.net/..." \
  -H "Ocp-Apim-Subscription-Key: $($result.PrimaryKey)"
``````

"@
}

$output | Out-File -FilePath "subscription-keys.md" -Encoding UTF8
Write-Host "✅ Clés sauvegardées dans subscription-keys.md`n" -ForegroundColor Green
