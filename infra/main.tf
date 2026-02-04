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

# Log Analytics Workspace pour Application Insights
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Application Insights pour le monitoring
resource "azurerm_application_insights" "appi" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"

  tags = var.tags
}

# API Management Instance Premium (Production)
resource "azurerm_api_management" "apim_premium" {
  name                = var.apim_premium_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Premium_1"

  tags = merge(var.tags, {
    Environment = "Production"
    Tier        = "Premium"
  })
}

# API Management Instance Developer (Development)
resource "azurerm_api_management" "apim_developer" {
  name                = var.apim_developer_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"

  tags = merge(var.tags, {
    Environment = "Development"
    Tier        = "Developer"
  })
}

# Déploiement des Workspaces APIM Production via ARM template
resource "azurerm_resource_group_template_deployment" "apim_workspaces_prod" {
  name                = "apim-workspaces-prod-deployment"
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
      },
      {
        "type" : "Microsoft.ApiManagement/service/workspaces",
        "apiVersion" : "2023-05-01-preview",
        "name" : "${azurerm_api_management.apim_premium.name}/${var.workspace3_name}",
        "properties" : {
          "displayName" : var.workspace3_display_name,
          "description" : var.workspace3_description
        }
      }
    ]
  })

  depends_on = [azurerm_api_management.apim_premium]
}

# Note: Workspaces are ONLY supported in Premium SKU
# Developer SKU does not support workspaces feature
# Therefore, no workspaces are created for APIM Developer instance

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
        "sku" : {
          "name" : "Free"
        },
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

# Application Insights Logger pour APIM Premium
resource "azurerm_api_management_logger" "appi_logger_premium" {
  name                = "appinsights-logger-premium"
  api_management_name = azurerm_api_management.apim_premium.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appi.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appi.instrumentation_key
  }
}

# Application Insights Logger pour APIM Developer
resource "azurerm_api_management_logger" "appi_logger_developer" {
  name                = "appinsights-logger-developer"
  api_management_name = azurerm_api_management.apim_developer.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appi.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appi.instrumentation_key
  }
}

# Diagnostics settings pour APIM Premium
resource "azurerm_api_management_diagnostic" "apim_premium_diag" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azurerm_api_management.apim_premium.name
  api_management_logger_id = azurerm_api_management_logger.appi_logger_premium.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
    ]
  }

  backend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
    ]
  }

  backend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
    ]
  }
}

# Diagnostics settings pour APIM Developer
resource "azurerm_api_management_diagnostic" "apim_developer_diag" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azurerm_api_management.apim_developer.name
  api_management_logger_id = azurerm_api_management_logger.appi_logger_developer.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
    ]
  }

  backend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
    ]
  }

  backend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
    ]
  }
}
