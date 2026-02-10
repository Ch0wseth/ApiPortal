#Requires -Version 7.0

<#
.SYNOPSIS
    Déploie l'ensemble de la plateforme API Portal (Infrastructure + Configuration)

.DESCRIPTION
    Script tout-en-un qui orchestre :
    - Vérification des prérequis (Azure CLI, Terraform, PowerShell)
    - Configuration du backend Terraform (optionnel)
    - Déploiement de l'infrastructure via Terraform
    - Configuration des APIs de démonstration
    - Configuration des portails développeur
    - Configuration du monitoring et alertes
    - Vérification finale de l'état de la plateforme

.PARAMETER SkipBackendSetup
    Ignore la configuration du backend Terraform (si déjà fait)

.PARAMETER SkipTerraform
    Ignore le déploiement Terraform (si déjà déployé)

.PARAMETER SkipAPIs
    Ignore la configuration des APIs de démo

.PARAMETER SkipPortal
    Ignore la configuration des portails

.PARAMETER SkipMonitoring
    Ignore la configuration du monitoring

.PARAMETER AutoApprove
    Applique automatiquement les changements Terraform sans confirmation

.PARAMETER TerraformVarFile
    Fichier de variables Terraform à utiliser (défaut: terraform.dev.tfvars)

.EXAMPLE
    .\deploy-all.ps1
    Déploie l'ensemble de la plateforme avec confirmations

.EXAMPLE
    .\deploy-all.ps1 -AutoApprove
    Déploie tout automatiquement sans confirmation

.EXAMPLE
    .\deploy-all.ps1 -SkipBackendSetup -AutoApprove
    Déploie en ignorant la configuration du backend Terraform

.EXAMPLE
    .\deploy-all.ps1 -SkipTerraform -SkipAPIs
    Configure uniquement le portail et le monitoring (infra déjà existante)
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipBackendSetup,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTerraform,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAPIs,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPortal,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoApprove,
    
    [Parameter(Mandatory = $false)]
    [string]$TerraformVarFile = "terraform.dev.tfvars"
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Chemins
$ScriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$RootPath = Split-Path -Parent $ScriptPath
$InfraPath = Join-Path $RootPath "infra"
$ScriptsPath = Join-Path $RootPath "scripts"

# Créer le dossier scripts s'il n'existe pas
if (-not (Test-Path $ScriptsPath)) {
    New-Item -ItemType Directory -Path $ScriptsPath -Force | Out-Null
}

# Variables de suivi
$script:DeploymentStartTime = Get-Date
$script:Errors = @()
$script:Warnings = @()
$script:DeploymentLog = Join-Path $ScriptsPath "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Fonctions d'affichage
function Write-Banner {
    param([string]$Message)
    $border = "═" * ($Message.Length + 4)
    Write-Host "`n╔$border╗" -ForegroundColor Magenta
    Write-Host "║  $Message  ║" -ForegroundColor Magenta
    Write-Host "╚$border╝`n" -ForegroundColor Magenta
}

function Write-Step {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = "[$timestamp] 🔹 $Message"
    Write-Host $output -ForegroundColor Cyan
    Add-Content -Path $script:DeploymentLog -Value $output
}

function Write-Success {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = "[$timestamp] ✅ $Message"
    Write-Host $output -ForegroundColor Green
    Add-Content -Path $script:DeploymentLog -Value $output
}

function Write-Warning-Custom {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = "[$timestamp] ⚠️  $Message"
    Write-Host $output -ForegroundColor Yellow
    Add-Content -Path $script:DeploymentLog -Value $output
    $script:Warnings += $Message
}

function Write-Error-Custom {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = "[$timestamp] ❌ $Message"
    Write-Host $output -ForegroundColor Red
    Add-Content -Path $script:DeploymentLog -Value $output
    $script:Errors += $Message
}

function Write-Info {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = "[$timestamp] ℹ️  $Message"
    Write-Host $output -ForegroundColor Gray
    Add-Content -Path $script:DeploymentLog -Value $output
}

function Test-Prerequisites {
    Write-Step "Vérification des prérequis..."
    
    $allGood = $true
    
    # Vérifier PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Error-Custom "PowerShell 7.0+ requis. Version actuelle: $($PSVersionTable.PSVersion)"
        $allGood = $false
    } else {
        Write-Success "PowerShell $($PSVersionTable.PSVersion) ✓"
    }
    
    # Vérifier Azure CLI
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        Write-Success "Azure CLI $($azVersion.'azure-cli') ✓"
    } catch {
        Write-Error-Custom "Azure CLI non installé ou non accessible"
        $allGood = $false
    }
    
    # Vérifier Terraform
    if (-not $SkipTerraform) {
        try {
            $tfVersion = terraform version -json 2>$null | ConvertFrom-Json
            $version = $tfVersion.terraform_version
            Write-Success "Terraform $version ✓"
            
            if ([version]$version -lt [version]"1.6.0") {
                Write-Warning-Custom "Terraform 1.6.0+ recommandé. Version actuelle: $version"
            }
        } catch {
            Write-Error-Custom "Terraform non installé ou non accessible"
            $allGood = $false
        }
    }
    
    # Vérifier la connexion Azure
    Write-Step "Vérification de la connexion Azure..."
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($null -eq $account) {
            Write-Warning-Custom "Non connecté à Azure. Connexion en cours..."
            az login --output none
            $account = az account show | ConvertFrom-Json
        }
        Write-Success "Connecté à Azure - Subscription: $($account.name)"
        Write-Info "  Tenant: $($account.tenantId)"
        Write-Info "  Subscription ID: $($account.id)"
    } catch {
        Write-Error-Custom "Impossible de se connecter à Azure"
        $allGood = $false
    }
    
    if (-not $allGood) {
        throw "Prérequis non satisfaits. Veuillez installer les outils manquants."
    }
}

function Invoke-BackendSetup {
    if ($SkipBackendSetup) {
        Write-Warning-Custom "Configuration du backend Terraform ignorée (--SkipBackendSetup)"
        return
    }
    
    Write-Step "Configuration du backend Terraform..."
    
    $backendScript = Join-Path $ScriptsPath "setup-azure-backend.ps1"
    if (-not (Test-Path $backendScript)) {
        Write-Warning-Custom "Script setup-azure-backend.ps1 non trouvé. Ignoré."
        return
    }
    
    try {
        & $backendScript
        Write-Success "Backend Terraform configuré"
    } catch {
        Write-Error-Custom "Erreur lors de la configuration du backend: $_"
        throw
    }
}

function Invoke-TerraformDeploy {
    if ($SkipTerraform) {
        Write-Warning-Custom "Déploiement Terraform ignoré (--SkipTerraform)"
        return
    }
    
    Write-Banner "DÉPLOIEMENT INFRASTRUCTURE TERRAFORM"
    
    if (-not (Test-Path $InfraPath)) {
        Write-Error-Custom "Dossier infra/ non trouvé à: $InfraPath"
        throw "Dossier infra/ manquant"
    }
    
    Push-Location $InfraPath
    try {
        # Terraform Init
        Write-Step "Initialisation Terraform..."
        $initOutput = terraform init 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform init a échoué"
            Write-Host $initOutput -ForegroundColor Red
            throw "Terraform init failed"
        }
        Write-Success "Terraform initialisé"
        
        # Terraform Validate
        Write-Step "Validation de la configuration Terraform..."
        $validateOutput = terraform validate 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "La configuration Terraform n'est pas valide"
            Write-Host $validateOutput -ForegroundColor Red
            throw "Terraform validation failed"
        }
        Write-Success "Configuration Terraform valide"
        
        # Terraform Plan
        Write-Step "Génération du plan Terraform..."
        $varFileArg = if ($TerraformVarFile) { "-var-file=$TerraformVarFile" } else { "" }
        
        if ($varFileArg -and -not (Test-Path $TerraformVarFile)) {
            Write-Warning-Custom "Fichier $TerraformVarFile non trouvé. Utilisation des valeurs par défaut."
            $varFileArg = ""
        }
        
        $planArgs = @("plan")
        if ($varFileArg) { $planArgs += $varFileArg }
        $planArgs += "-out=tfplan"
        
        & terraform $planArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform plan a échoué"
            throw "Terraform plan failed"
        }
        Write-Success "Plan Terraform généré"
        
        # Terraform Apply
        Write-Warning-Custom "⏱️  Le déploiement de l'infrastructure peut prendre 60-90 minutes..."
        Write-Info "    APIM Premium: ~45-60 min"
        Write-Info "    APIM Developer: ~30-45 min"
        Write-Info "    API Center + Monitoring: ~5-10 min"
        
        if (-not $AutoApprove) {
            Write-Host "`n"
            $confirm = Read-Host "Voulez-vous appliquer ce plan ? (yes/no)"
            if ($confirm -ne "yes") {
                Write-Warning-Custom "Déploiement annulé par l'utilisateur"
                return
            }
        }
        
        Write-Step "Application du plan Terraform..."
        $applyStartTime = Get-Date
        
        $applyArgs = @("apply")
        if ($AutoApprove) { $applyArgs += "-auto-approve" }
        $applyArgs += "tfplan"
        
        & terraform $applyArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform apply a échoué"
            throw "Terraform apply failed"
        }
        
        $applyDuration = (Get-Date) - $applyStartTime
        Write-Success "Infrastructure déployée en $($applyDuration.ToString('hh\:mm\:ss'))"
        
        # Attendre que les ressources soient complètement provisionnées
        Write-Step "Vérification de l'état des ressources APIM..."
        Start-Sleep -Seconds 30
        
    } finally {
        Pop-Location
    }
}

function Invoke-APIsConfiguration {
    if ($SkipAPIs) {
        Write-Warning-Custom "Configuration des APIs ignorée (--SkipAPIs)"
        return
    }
    
    Write-Banner "CONFIGURATION DES APIs"
    
    $apisScript = Join-Path $ScriptsPath "setup-demo-apis.ps1"
    if (-not (Test-Path $apisScript)) {
        Write-Warning-Custom "Script setup-demo-apis.ps1 non trouvé. Ignoré."
        return
    }
    
    Write-Step "Déploiement des APIs de démonstration..."
    try {
        Push-Location $ScriptsPath
        & $apisScript
        if ($LASTEXITCODE -ne 0) {
            Write-Warning-Custom "La configuration des APIs a rencontré des erreurs"
        } else {
            Write-Success "APIs de démonstration configurées"
        }
    } catch {
        Write-Error-Custom "Erreur lors de la configuration des APIs: $_"
        Write-Warning-Custom "Continuons avec les autres étapes..."
    } finally {
        Pop-Location
    }
}

function Invoke-PortalConfiguration {
    if ($SkipPortal) {
        Write-Warning-Custom "Configuration du portail ignorée (--SkipPortal)"
        return
    }
    
    Write-Banner "CONFIGURATION DU PORTAIL DÉVELOPPEUR"
    
    $portalScript = Join-Path $ScriptsPath "setup-portal-simple.ps1"
    if (-not (Test-Path $portalScript)) {
        Write-Warning-Custom "Script setup-portal-simple.ps1 non trouvé. Ignoré."
        return
    }
    
    Write-Step "Configuration du portail développeur..."
    try {
        Push-Location $ScriptsPath
        & $portalScript
        if ($LASTEXITCODE -ne 0) {
            Write-Warning-Custom "La configuration du portail a rencontré des erreurs"
        } else {
            Write-Success "Portail développeur configuré"
        }
    } catch {
        Write-Error-Custom "Erreur lors de la configuration du portail: $_"
        Write-Warning-Custom "Continuons avec les autres étapes..."
    } finally {
        Pop-Location
    }
}

function Invoke-MonitoringConfiguration {
    if ($SkipMonitoring) {
        Write-Warning-Custom "Configuration du monitoring ignorée (--SkipMonitoring)"
        return
    }
    
    Write-Banner "CONFIGURATION DU MONITORING"
    
    $monitoringScript = Join-Path $ScriptsPath "setup-monitoring.ps1"
    if (-not (Test-Path $monitoringScript)) {
        Write-Warning-Custom "Script setup-monitoring.ps1 non trouvé. Ignoré."
        return
    }
    
    Write-Step "Configuration du monitoring et des alertes..."
    try {
        Push-Location $ScriptsPath
        & $monitoringScript
        if ($LASTEXITCODE -ne 0) {
            Write-Warning-Custom "La configuration du monitoring a rencontré des erreurs"
        } else {
            Write-Success "Monitoring et alertes configurés"
        }
    } catch {
        Write-Error-Custom "Erreur lors de la configuration du monitoring: $_"
        Write-Warning-Custom "Continuons avec les autres étapes..."
    } finally {
        Pop-Location
    }
}

function Invoke-HealthCheck {
    Write-Banner "VÉRIFICATION DE LA PLATEFORME"
    
    $healthScript = Join-Path $ScriptsPath "health-check.ps1"
    if (-not (Test-Path $healthScript)) {
        Write-Warning-Custom "Script health-check.ps1 non trouvé. Vérification ignorée."
        return
    }
    
    Write-Step "Exécution du health check..."
    try {
        Push-Location $ScriptsPath
        & $healthScript
        Write-Success "Health check terminé"
    } catch {
        Write-Warning-Custom "Erreur lors du health check: $_"
    } finally {
        Pop-Location
    }
}

function Show-DeploymentSummary {
    $duration = (Get-Date) - $script:DeploymentStartTime
    
    Write-Banner "RÉSUMÉ DU DÉPLOIEMENT"
    
    Write-Host "⏱️  Durée totale: " -NoNewline
    Write-Host $duration.ToString('hh\:mm\:ss') -ForegroundColor Cyan
    
    Write-Host "`n📊 Statistiques:" -ForegroundColor White
    Write-Host "   Erreurs: " -NoNewline
    if ($script:Errors.Count -eq 0) {
        Write-Host "0 ✓" -ForegroundColor Green
    } else {
        Write-Host $script:Errors.Count -ForegroundColor Red
        foreach ($error in $script:Errors) {
            Write-Host "      - $error" -ForegroundColor Red
        }
    }
    
    Write-Host "   Avertissements: " -NoNewline
    if ($script:Warnings.Count -eq 0) {
        Write-Host "0 ✓" -ForegroundColor Green
    } else {
        Write-Host $script:Warnings.Count -ForegroundColor Yellow
        foreach ($warning in $script:Warnings) {
            Write-Host "      - $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n📁 Log de déploiement: " -NoNewline
    Write-Host $script:DeploymentLog -ForegroundColor Cyan
    
    Write-Host "`n🎯 Prochaines étapes:" -ForegroundColor White
    Write-Host "   1. Vérifier les ressources dans le portail Azure" -ForegroundColor Gray
    Write-Host "   2. Tester les APIs avec les clés de souscription" -ForegroundColor Gray
    Write-Host "   3. Consulter les dashboards Application Insights" -ForegroundColor Gray
    Write-Host "   4. Accéder au portail développeur APIM" -ForegroundColor Gray
    
    if ($script:Errors.Count -eq 0) {
        Write-Host "`n✅ " -NoNewline -ForegroundColor Green
        Write-Host "DÉPLOIEMENT RÉUSSI!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  " -NoNewline -ForegroundColor Yellow
        Write-Host "DÉPLOIEMENT TERMINÉ AVEC DES ERREURS" -ForegroundColor Yellow
    }
}

# ============================================================================
# SCRIPT PRINCIPAL
# ============================================================================

try {
    # Bannière de démarrage
    Clear-Host
    Write-Banner "🚀 DÉPLOIEMENT API PORTAL - PLATEFORME COMPLÈTE"
    
    Write-Info "Démarrage: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Info "Log: $script:DeploymentLog"
    Write-Info "Dossier racine: $RootPath"
    
    # Afficher la configuration
    Write-Host "`n📋 Configuration du déploiement:" -ForegroundColor White
    Write-Host "   Backend Terraform: " -NoNewline
    Write-Host $(if ($SkipBackendSetup) { "Ignoré ⏭️" } else { "Inclus ✓" }) -ForegroundColor $(if ($SkipBackendSetup) { "Yellow" } else { "Green" })
    
    Write-Host "   Infrastructure (Terraform): " -NoNewline
    Write-Host $(if ($SkipTerraform) { "Ignoré ⏭️" } else { "Inclus ✓" }) -ForegroundColor $(if ($SkipTerraform) { "Yellow" } else { "Green" })
    
    Write-Host "   APIs de démo: " -NoNewline
    Write-Host $(if ($SkipAPIs) { "Ignoré ⏭️" } else { "Inclus ✓" }) -ForegroundColor $(if ($SkipAPIs) { "Yellow" } else { "Green" })
    
    Write-Host "   Portail développeur: " -NoNewline
    Write-Host $(if ($SkipPortal) { "Ignoré ⏭️" } else { "Inclus ✓" }) -ForegroundColor $(if ($SkipPortal) { "Yellow" } else { "Green" })
    
    Write-Host "   Monitoring: " -NoNewline
    Write-Host $(if ($SkipMonitoring) { "Ignoré ⏭️" } else { "Inclus ✓" }) -ForegroundColor $(if ($SkipMonitoring) { "Yellow" } else { "Green" })
    
    Write-Host "   Auto-approbation: " -NoNewline
    Write-Host $(if ($AutoApprove) { "Activée ⚡" } else { "Désactivée 🛡️" }) -ForegroundColor $(if ($AutoApprove) { "Yellow" } else { "Green" })
    
    Write-Host ""
    
    # Étape 1: Vérification des prérequis
    Test-Prerequisites
    
    # Étape 2: Configuration du backend Terraform
    Write-Host ""
    Invoke-BackendSetup
    
    # Étape 3: Déploiement de l'infrastructure
    Write-Host ""
    Invoke-TerraformDeploy
    
    # Étape 4: Configuration des APIs
    Write-Host ""
    Invoke-APIsConfiguration
    
    # Étape 5: Configuration du portail
    Write-Host ""
    Invoke-PortalConfiguration
    
    # Étape 6: Configuration du monitoring
    Write-Host ""
    Invoke-MonitoringConfiguration
    
    # Étape 7: Vérification finale
    Write-Host ""
    Invoke-HealthCheck
    
    # Résumé
    Write-Host ""
    Show-DeploymentSummary
    
} catch {
    Write-Error-Custom "Erreur fatale: $_"
    Write-Host "`n❌ DÉPLOIEMENT ÉCHOUÉ" -ForegroundColor Red
    Write-Host "Consultez le log: $script:DeploymentLog" -ForegroundColor Yellow
    exit 1
}
