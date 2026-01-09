#Requires -Version 7.0

<#
.SYNOPSIS
    Configure l'infrastructure Azure nécessaire pour le backend Terraform et GitHub Actions
.DESCRIPTION
    Ce script crée :
    - Un Resource Group pour le state Terraform
    - Un Storage Account pour stocker le state
    - Un Container pour les fichiers .tfstate
    - Un Service Principal pour GitHub Actions
    - Affiche les secrets à configurer dans GitHub
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "francecentral",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-terraform-state",
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountPrefix = "sttfstate",
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "tfstate",
    
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalName = "sp-terraform-github-actions"
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Couleurs pour l'affichage
function Write-Step { 
    param([string]$Message)
    Write-Host "`n🔹 $Message" -ForegroundColor Cyan 
}

function Write-Success { 
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green 
}

function Write-Info { 
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow 
}

function Write-ErrorMsg { 
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red 
}

# Bannière
Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🚀 Configuration Azure pour Terraform & GitHub Actions ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Vérification de la connexion Azure
Write-Step "Vérification de la connexion Azure"
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($null -eq $account) {
        Write-Info "Connexion à Azure requise..."
        az login
        $account = az account show | ConvertFrom-Json
    }
    Write-Success "Connecté à Azure"
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
    Write-Host "   Tenant: $($account.tenantId)" -ForegroundColor Gray
} catch {
    Write-ErrorMsg "Impossible de se connecter à Azure"
    exit 1
}

$subscriptionId = $account.id

# Génération d'un nom unique pour le Storage Account
$random = Get-Random -Minimum 1000 -Maximum 9999
$storageAccountName = "$StorageAccountPrefix$random"

# Création du Resource Group
Write-Step "Création du Resource Group: $ResourceGroupName"
try {
    $rgExists = az group exists --name $ResourceGroupName
    if ($rgExists -eq "true") {
        Write-Info "Resource Group existe déjà"
    } else {
        az group create `
            --name $ResourceGroupName `
            --location $Location `
            --output none
        Write-Success "Resource Group créé"
    }
} catch {
    Write-ErrorMsg "Erreur lors de la création du Resource Group: $_"
    exit 1
}

# Création du Storage Account
Write-Step "Création du Storage Account: $storageAccountName"
try {
    az storage account create `
        --name $storageAccountName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard_LRS `
        --encryption-services blob `
        --https-only true `
        --min-tls-version TLS1_2 `
        --allow-blob-public-access false `
        --output none
    Write-Success "Storage Account créé"
} catch {
    Write-ErrorMsg "Erreur lors de la création du Storage Account: $_"
    exit 1
}

# Récupération de la clé du Storage Account
Write-Step "Récupération de la clé du Storage Account"
$accountKey = az storage account keys list `
    --resource-group $ResourceGroupName `
    --account-name $storageAccountName `
    --query '[0].value' `
    --output tsv

# Création du conteneur blob
Write-Step "Création du conteneur: $ContainerName"
try {
    az storage container create `
        --name $ContainerName `
        --account-name $storageAccountName `
        --account-key $accountKey `
        --output none
    Write-Success "Conteneur créé"
} catch {
    Write-ErrorMsg "Erreur lors de la création du conteneur: $_"
    exit 1
}

# Création du Service Principal
Write-Step "Création du Service Principal: $ServicePrincipalName"
try {
    # Vérifier si le SP existe déjà
    $existingSp = az ad sp list --display-name $ServicePrincipalName --query "[0].appId" --output tsv 2>$null
    
    if ($existingSp) {
        Write-Info "Service Principal existe déjà, suppression de l'ancien..."
        az ad sp delete --id $existingSp
        Start-Sleep -Seconds 5
    }
    
    # Créer le nouveau Service Principal
    $spCredentials = az ad sp create-for-rbac `
        --name $ServicePrincipalName `
        --role Contributor `
        --scopes "/subscriptions/$subscriptionId" `
        --sdk-auth
    
    Write-Success "Service Principal créé"
    
    # Pause pour la propagation Azure AD
    Write-Info "Attente de la propagation Azure AD (30s)..."
    Start-Sleep -Seconds 30
    
} catch {
    Write-ErrorMsg "Erreur lors de la création du Service Principal: $_"
    exit 1
}

# Affichage du résumé
Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                    ✅ Configuration terminée              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host @"

📋 SECRETS GITHUB À CONFIGURER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Allez dans votre repository GitHub :
Settings > Secrets and variables > Actions > New repository secret

"@ -ForegroundColor Yellow

# Affichage des secrets
Write-Host "1️⃣  TF_STATE_RG" -ForegroundColor Cyan
Write-Host "   $ResourceGroupName" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  TF_STATE_SA" -ForegroundColor Cyan
Write-Host "   $storageAccountName" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣  TF_STATE_CONTAINER" -ForegroundColor Cyan
Write-Host "   $ContainerName" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣  AZURE_CREDENTIALS (JSON complet ci-dessous)" -ForegroundColor Cyan
Write-Host $spCredentials -ForegroundColor White
Write-Host ""

# Sauvegarde dans un fichier (exclu du git)
$outputFile = "azure-secrets.txt"
$secretsContent = @"
GitHub Secrets Configuration
============================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

TF_STATE_RG:
$ResourceGroupName

TF_STATE_SA:
$storageAccountName

TF_STATE_CONTAINER:
$ContainerName

AZURE_CREDENTIALS:
$spCredentials

============================
⚠️  IMPORTANT: Ce fichier contient des informations sensibles.
Ne le commitez JAMAIS dans Git. Il est déjà dans .gitignore.
Supprimez-le après avoir configuré les secrets GitHub.
============================
"@

$secretsContent | Out-File -FilePath $outputFile -Encoding UTF8
Write-Success "Secrets sauvegardés dans: $outputFile"
Write-Host "   ⚠️  Supprimez ce fichier après configuration des secrets GitHub" -ForegroundColor Yellow

Write-Host @"

📚 PROCHAINES ÉTAPES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Configurez les 4 secrets dans GitHub (voir ci-dessus)
2. Le fichier backend.tf a déjà été créé
3. Committez et poussez sur la branche 'develop'
4. Le workflow GitHub Actions se déclenchera automatiquement

"@ -ForegroundColor Cyan

Write-Host "`n✨ Script terminé avec succès !`n" -ForegroundColor Green
