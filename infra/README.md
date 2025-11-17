# Infrastructure as Code - API Portal POC

Ce dossier contient les fichiers Bicep et les workflows GitHub Actions pour déployer l'infrastructure Azure du POC API Portal.

## Structure des fichiers

```
infra/
├── main.bicep                 # Template Bicep principal
├── main.bicepparam           # Paramètres pour le POC
└── README.md                 # Cette documentation
```

## Ressources déployées

Le template Bicep déploie les ressources Azure suivantes pour le POC :

- **App Service Plan** : Plan gratuit (F1) pour les tests
- **App Service** : Application web .NET avec identité managée
- **SQL Server** : Serveur de base de données Azure SQL
- **SQL Database** : Base de données Basic pour le POC
- **Application Insights** : Monitoring et télémétrie de l'application
- **Log Analytics Workspace** : Stockage des logs et métriques
- **Key Vault** : Stockage sécurisé des secrets et configurations
- **Règles de pare-feu SQL** : Autorisation d'accès pour les services Azure

## Configuration requise

### GitHub Secrets

Vous devez configurer les secrets suivants dans votre repository GitHub :

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AZURE_CLIENT_ID` | ID du service principal Azure | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | ID du tenant Azure AD | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | ID de l'abonnement Azure | `abcdefab-1234-5678-9012-abcdefabcdef` |
| `SQL_ADMIN_PASSWORD` | Mot de passe admin SQL Server | `PocPassword123!` |

### Service Principal Azure

Créez un service principal avec les permissions nécessaires :

```bash
# Créer le service principal
az ad sp create-for-rbac --name "sp-apiportal-poc" --role "Contributor" --scopes "/subscriptions/{subscription-id}"

# Ajouter les rôles nécessaires
az role assignment create --assignee {service-principal-id} --role "Key Vault Administrator" --scope "/subscriptions/{subscription-id}"
az role assignment create --assignee {service-principal-id} --role "SQL DB Contributor" --scope "/subscriptions/{subscription-id}"
```

## Déploiement

### Déploiement automatique

Le déploiement se fait automatiquement via GitHub Actions :

1. **Push sur main** : Déploie automatiquement le POC
2. **Déploiement manuel** : Utilisez le workflow dispatch

### Déploiement manuel local

Pour déployer manuellement depuis votre machine locale :

```bash
# Se connecter à Azure
az login

# Créer le groupe de ressources
az group create --name rg-apiportal-poc --location "France Central"

# Déployer l'infrastructure
az deployment group create \
  --resource-group rg-apiportal-poc \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters sqlAdministratorPassword="PocPassword123!"
```

## Configuration POC

- **Groupe de ressources** : `rg-apiportal-poc`
- **App Service Plan** : F1 (Gratuit - idéal pour POC)
- **SQL Database** : Basic (5 DTU)
- **Environnement** : poc
- **Déploiement** : Automatique sur push vers main

## Paramètres du POC

Les paramètres sont configurés dans `main.bicepparam` :

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `environment` | poc | Identifiant de l'environnement |
| `location` | France Central | Région Azure |
| `resourceNamePrefix` | apiportal | Préfixe des noms de ressources |
| `appServicePlanSku` | F1 | Plan gratuit pour POC |
| `sqlAdministratorLogin` | sqladmin | Login admin SQL |

## Sécurité

- Toutes les ressources utilisent HTTPS uniquement
- SQL Server utilise TLS 1.2 minimum
- Key Vault avec RBAC activé
- Application Insights avec accès public contrôlé
- Identité managée pour l'App Service
- Configuration optimisée pour POC (pas de production)

## Monitoring

Les ressources de monitoring déployées permettent de suivre :

- **Application Insights** : Performance de l'application, erreurs, requêtes
- **Log Analytics** : Logs centralisés de toutes les ressources
- Rétention des logs : 30 jours (Log Analytics) et 90 jours (App Insights)

## Maintenance

### Mise à jour de l'infrastructure

1. Modifiez le fichier `main.bicep` ou les paramètres dans `main.bicepparam`
2. Committez et poussez vers la branche main
3. Le déploiement se fait automatiquement

### Nettoyage du POC

Pour supprimer complètement l'infrastructure du POC :

```bash
# Supprimer le groupe de ressources (supprime toutes les ressources)
az group delete --name rg-apiportal-poc --yes --no-wait
```

## Troubleshooting

### Erreurs communes

1. **Erreur de permissions** : Vérifiez que le service principal a les bonnes permissions
2. **Nom de ressource déjà pris** : Les noms incluent un suffixe unique, mais certains services ont des contraintes globales
3. **Quota dépassé** : Vérifiez les quotas de votre abonnement Azure (le plan F1 est gratuit)

### Logs

Consultez les logs dans GitHub Actions ou via Azure CLI :

```bash
# Voir les déploiements du groupe de ressources
az deployment group list --resource-group rg-apiportal-poc

# Voir les détails d'un déploiement
az deployment group show --resource-group rg-apiportal-poc --name {deployment-name}
```

## Notes POC

- Le plan App Service F1 (gratuit) a des limitations : pas de custom domain, SSL limité
- Pensez à nettoyer les ressources après vos tests pour éviter des coûts
- La base de données Basic est suffisante pour des tests de charge limitée