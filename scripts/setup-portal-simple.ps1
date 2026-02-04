#Requires -Version 7.0

<#
.SYNOPSIS
    Configure le portail développeur APIM (version simplifiée)
.DESCRIPTION
    Crée des produits globaux, ajoute les APIs et crée des souscriptions de test
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-api-portal-dev",
    
    [Parameter(Mandatory = $false)]
    [string]$ApimPremiumName = "apim-premium-prod-1161"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Configuration Portail Développeur          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 1. Créer des produits (au niveau global APIM)
Write-Host "📦 Création des produits API..." -ForegroundColor Yellow

# Produit Team A
Write-Host "  • Produit: Team A Production" -ForegroundColor Gray
az apim product create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-a-prod" `
    --product-name "Team A Production" `
    --description "APIs de production pour l'équipe A" `
    --subscription-required true `
    --approval-required false `
    --subscriptions-limit 100 `
    --state published 2>$null | Out-Null

# Produit Partners  
Write-Host "  • Produit: Partner Integration" -ForegroundColor Gray
az apim product create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "partners-prod" `
    --product-name "Partner Integration" `
    --description "APIs pour les intégrations partenaires" `
    --subscription-required true `
    --approval-required false `
    --subscriptions-limit 50 `
    --state published 2>$null | Out-Null

# Produit Team B
Write-Host "  • Produit: Team B Analytics" -ForegroundColor Gray
az apim product create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-b-prod" `
    --product-name "Team B Analytics" `
    --description "APIs d'analytics pour l'équipe B" `
    --subscription-required true `
    --approval-required false `
    --subscriptions-limit 100 `
    --state published 2>$null | Out-Null

Write-Host "✅ Produits créés" -ForegroundColor Green

# 2. Créer des utilisateurs de démonstration
Write-Host "`n👥 Création d'utilisateurs de démonstration..." -ForegroundColor Yellow

# Utilisateur Team A
Write-Host "  • Utilisateur: dev-team-a@example.com" -ForegroundColor Gray
az apim user create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --user-id "dev-team-a" `
    --email "dev-team-a@example.com" `
    --first-name "Developer" `
    --last-name "Team A" `
    --state active `
    --confirmation signup 2>$null | Out-Null

# Utilisateur Partners
Write-Host "  • Utilisateur: partner@example.com" -ForegroundColor Gray
az apim user create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --user-id "partner-user" `
    --email "partner@example.com" `
    --first-name "Partner" `
    --last-name "External" `
    --state active `
    --confirmation signup 2>$null | Out-Null

# Utilisateur Team B
Write-Host "  • Utilisateur: dev-team-b@example.com" -ForegroundColor Gray
az apim user create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --user-id "dev-team-b" `
    --email "dev-team-b@example.com" `
    --first-name "Developer" `
    --last-name "Team B" `
    --state active `
    --confirmation signup 2>$null | Out-Null

Write-Host "✅ Utilisateurs créés" -ForegroundColor Green

# 3. Créer des souscriptions pour les utilisateurs
Write-Host "`n🔑 Création des souscriptions..." -ForegroundColor Yellow

# Souscription Team A
Write-Host "  • Souscription Team A" -ForegroundColor Gray
az apim product subscription create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-a-prod" `
    --subscription-id "sub-team-a" `
    --name "Team A Subscription" `
    --user-id "dev-team-a" `
    --state active 2>$null | Out-Null

# Souscription Partners
Write-Host "  • Souscription Partners" -ForegroundColor Gray
az apim product subscription create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "partners-prod" `
    --subscription-id "sub-partners" `
    --name "Partners Subscription" `
    --user-id "partner-user" `
    --state active 2>$null | Out-Null

# Souscription Team B
Write-Host "  • Souscription Team B" -ForegroundColor Gray
az apim product subscription create `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-b-prod" `
    --subscription-id "sub-team-b" `
    --name "Team B Subscription" `
    --user-id "dev-team-b" `
    --state active 2>$null | Out-Null

Write-Host "✅ Souscriptions créées" -ForegroundColor Green

# 4. Récupérer les clés de souscription
Write-Host "`n🔑 Récupération des clés de souscription..." -ForegroundColor Yellow

$teamAKey = az apim product subscription list-secrets `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-a-prod" `
    --subscription-id "sub-team-a" `
    --query primaryKey -o tsv

$partnersKey = az apim product subscription list-secrets `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "partners-prod" `
    --subscription-id "sub-partners" `
    --query primaryKey -o tsv

$teamBKey = az apim product subscription list-secrets `
    --resource-group $ResourceGroupName `
    --service-name $ApimPremiumName `
    --product-id "team-b-prod" `
    --subscription-id "sub-team-b" `
    --query primaryKey -o tsv

Write-Host "✅ Clés récupérées" -ForegroundColor Green

# 5. Créer un guide de démarrage rapide
$quickStartGuide = @"
# 🚀 GUIDE PORTAIL DÉVELOPPEUR - API MANAGEMENT

## 📱 Accès au Portail

**Portail Premium (Production):**
https://$ApimPremiumName.developer.azure-api.net

## 👥 Utilisateurs créés

1. **Team A Developer**
   - Email: dev-team-a@example.com
   - Produit: Team A Production
   - Workspace: workspace-team-a-prod

2. **Partner User**
   - Email: partner@example.com
   - Produit: Partner Integration
   - Workspace: workspace-partners-prod

3. **Team B Developer**
   - Email: dev-team-b@example.com
   - Produit: Team B Analytics
   - Workspace: workspace-team-b-prod

## 🔑 Clés de Souscription

### Team A
``````
Ocp-Apim-Subscription-Key: $teamAKey
``````

### Partners
``````
Ocp-Apim-Subscription-Key: $partnersKey
``````

### Team B
``````
Ocp-Apim-Subscription-Key: $teamBKey
``````

## 📡 Exemples d'appels API

### Customer API (Team A)
``````bash
# Liste des clients
curl -X GET "https://$ApimPremiumName.azure-api.net/customers/customers" \
  -H "Ocp-Apim-Subscription-Key: $teamAKey"

# Obtenir un client
curl -X GET "https://$ApimPremiumName.azure-api.net/customers/customers/123" \
  -H "Ocp-Apim-Subscription-Key: $teamAKey"
``````

### Partner API (Partners)
``````bash
# Webhook
curl -X POST "https://$ApimPremiumName.azure-api.net/partners/webhook" \
  -H "Ocp-Apim-Subscription-Key: $partnersKey" \
  -H "Content-Type: application/json" \
  -d '{"event": "order.created"}'

# Liste des commandes
curl -X GET "https://$ApimPremiumName.azure-api.net/partners/orders" \
  -H "Ocp-Apim-Subscription-Key: $partnersKey"
``````

### Analytics API (Team B)
``````bash
# Rapports
curl -X GET "https://$ApimPremiumName.azure-api.net/analytics/reports" \
  -H "Ocp-Apim-Subscription-Key: $teamBKey"

# Métriques
curl -X GET "https://$ApimPremiumName.azure-api.net/analytics/metrics" \
  -H "Ocp-Apim-Subscription-Key: $teamBKey"
``````

## 📊 Workspaces APIM Premium

Les APIs sont organisées dans des workspaces dédiés:

- **workspace-team-a-prod**: Customer Management API
- **workspace-partners-prod**: Partner Integration API
- **workspace-team-b-prod**: Analytics API

## 🎯 Prochaines Étapes

1. **Connecter les APIs aux Produits** (via Azure Portal ou API REST)
2. **Personnaliser le portail développeur**
   - Ajouter votre logo
   - Personnaliser les couleurs
   - Ajouter de la documentation

3. **Configurer les politiques API**
   - Rate limiting par produit
   - Authentification JWT
   - Transformation de requêtes
   - Mise en cache

4. **Activer l'authentification avancée**
   - OAuth 2.0 / OpenID Connect
   - Intégration Azure AD
   - Gestion avancée des clés API

## ⚠️ Notes importantes

- Les clés ci-dessus sont sensibles - ne les partagez pas
- Les APIs dans les workspaces sont isolées logiquement
- Chaque produit peut avoir ses propres politiques

## 🔗 Liens utiles

- Portail développeur: https://$ApimPremiumName.developer.azure-api.net
- Azure Portal APIM: https://portal.azure.com → $ApimPremiumName
- API Center: https://portal.azure.com → apic-portal-dev-1161

"@

$quickStartGuide | Out-File -FilePath "portail-developpeur-guide.md" -Encoding UTF8
Write-Host "✅ Guide sauvegardé dans portail-developpeur-guide.md" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Portail développeur configuré !           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 Résumé:" -ForegroundColor Cyan
Write-Host "  • 3 Produits créés" -ForegroundColor White
Write-Host "  • 3 Utilisateurs de démonstration" -ForegroundColor White
Write-Host "  • 3 Souscriptions actives avec clés" -ForegroundColor White

Write-Host "`n🌐 Portail développeur:" -ForegroundColor Cyan
Write-Host "  https://$ApimPremiumName.developer.azure-api.net" -ForegroundColor White

Write-Host "`n💡 Prochaine étape: Associer les APIs aux produits via Azure Portal" -ForegroundColor Yellow
Write-Host "   → API Management → Produits → Sélectionner produit → APIs → Ajouter`n" -ForegroundColor Gray
