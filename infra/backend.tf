terraform {
  backend "azurerm" {
    # Configuration fournie via -backend-config dans GitHub Actions
    # Les valeurs sont injectées depuis les secrets GitHub
    use_azuread_auth = true
  }
}
