terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# API Management Instance Premium
resource "azurerm_api_management" "apim_premium" {
  name                = var.apim_premium_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Premium_1"

  tags = var.tags
}

# Déploiement des Workspaces APIM via ARM template
resource "azurerm_resource_group_template_deployment" "apim_workspaces" {
  name                = "apim-workspaces-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema" : "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion" : "1.0.0.0",
    "parameters" : {},
    "resources" : [
      {
        "type" : "Microsoft.ApiManagement/service/workspaces",
        "apiVersion" : "2023-05-01-preview",
        "name" : "${azurerm_api_management.apim_premium.name}/${var.workspace1_name}",
        "properties" : {
          "displayName" : var.workspace1_display_name,
          "description" : var.workspace1_description
        }
      },
      {
        "type" : "Microsoft.ApiManagement/service/workspaces",
        "apiVersion" : "2023-05-01-preview",
        "name" : "${azurerm_api_management.apim_premium.name}/${var.workspace2_name}",
        "properties" : {
          "displayName" : var.workspace2_display_name,
          "description" : var.workspace2_description
        }
      }
    ]
  })

  depends_on = [azurerm_api_management.apim_premium]
}

# Azure API Center
resource "azurerm_resource_group_template_deployment" "api_center" {
  name                = "api-center-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema" : "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion" : "1.0.0.0",
    "parameters" : {},
    "resources" : [
      {
        "type" : "Microsoft.ApiCenter/services",
        "apiVersion" : "2024-03-01",
        "name" : var.api_center_name,
        "location" : azurerm_resource_group.rg.location,
        "tags" : var.tags,
        "properties" : {}
      }
    ],
    "outputs" : {
      "apiCenterId" : {
        "type" : "string",
        "value" : "[resourceId('Microsoft.ApiCenter/services', '${var.api_center_name}')]"
      }
    }
  })
}
