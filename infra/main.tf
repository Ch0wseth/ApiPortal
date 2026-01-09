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

# API Management Instance Premium avec Workspaces
resource "azurerm_api_management" "apim_premium" {
  name                = var.apim_premium_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Premium_1"

  tags = var.tags
}

# Workspace 1
resource "azurerm_api_management_gateway_api" "workspace1" {
  api_management_id = azurerm_api_management.apim_premium.id
  name              = var.workspace1_name
  display_name      = var.workspace1_display_name
  description       = var.workspace1_description
}

# Workspace 2
resource "azurerm_api_management_gateway_api" "workspace2" {
  api_management_id = azurerm_api_management.apim_premium.id
  name              = var.workspace2_name
  display_name      = var.workspace2_display_name
  description       = var.workspace2_description
}

# API Center
resource "azurerm_api_center_service" "api_center" {
  name                = var.api_center_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}
