output "resource_group_name" {
  description = "Nom du groupe de ressources créé"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "ID du groupe de ressources"
  value       = azurerm_resource_group.rg.id
}

output "apim_premium_name" {
  description = "Nom de l'instance API Management Premium (Production)"
  value       = azurerm_api_management.apim_premium.name
}

output "apim_premium_gateway_url" {
  description = "URL de la gateway APIM Premium (Production)"
  value       = azurerm_api_management.apim_premium.gateway_url
}

output "apim_premium_portal_url" {
  description = "URL du portail développeur APIM Premium (Production)"
  value       = azurerm_api_management.apim_premium.developer_portal_url
}

output "apim_premium_id" {
  description = "ID de l'instance APIM Premium (Production)"
  value       = azurerm_api_management.apim_premium.id
}

output "apim_developer_name" {
  description = "Nom de l'instance API Management Developer (Development)"
  value       = azurerm_api_management.apim_developer.name
}

output "apim_developer_gateway_url" {
  description = "URL de la gateway APIM Developer (Development)"
  value       = azurerm_api_management.apim_developer.gateway_url
}

output "apim_developer_portal_url" {
  description = "URL du portail développeur APIM Developer (Development)"
  value       = azurerm_api_management.apim_developer.developer_portal_url
}

output "apim_developer_id" {
  description = "ID de l'instance APIM Developer (Development)"
  value       = azurerm_api_management.apim_developer.id
}

# Workspaces Production
output "workspace_prod_team_a" {
  description = "Nom du workspace Team A Production"
  value       = var.workspace1_name
}

output "workspace_prod_team_b" {
  description = "Nom du workspace Team B Production"
  value       = var.workspace2_name
}

output "workspace_prod_partners" {
  description = "Nom du workspace Partners Production"
  value       = var.workspace3_name
}

# Note: No workspaces for Developer SKU (not supported)
# Workspaces are Premium-only feature

output "api_center_id" {
  description = "ID de l'instance API Center"
  value       = azurerm_resource_group_template_deployment.api_center.output_content
}

output "api_center_name" {
  description = "Nom de l'instance API Center"
  value       = var.api_center_name
}

# Monitoring
output "application_insights_name" {
  description = "Nom de l'instance Application Insights"
  value       = azurerm_application_insights.appi.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation Key pour Application Insights"
  value       = azurerm_application_insights.appi.instrumentation_key
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application ID pour Application Insights"
  value       = azurerm_application_insights.appi.app_id
}

output "log_analytics_workspace_id" {
  description = "ID du Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "log_analytics_workspace_name" {
  description = "Nom du Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.name
}
