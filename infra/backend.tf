# Backend temporairement en local pour le déploiement initial
# Pour utiliser Azure backend, décommenter ci-dessous et fournir les configs
/*
terraform {
  backend "azurerm" {
    # Configuration fournie via -backend-config dans GitHub Actions
    # Les valeurs sont injectées depuis les secrets GitHub
    use_azuread_auth = true
  }
}
*/
