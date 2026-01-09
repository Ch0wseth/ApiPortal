output "resource_group_name" {
  description = "Nom du groupe de ressources créé"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "ID du groupe de ressources"
  value       = azurerm_resource_group.rg.id
}

output "apim_premium_name" {
  description = "Nom de l'instance API Management Premium"
  value       = azurerm_api_management.apim_premium.name
}

output "apim_premium_gateway_url" {
  description = "URL de la gateway APIM Premium"
  value       = azurerm_api_management.apim_premium.gateway_url
}

output "apim_premium_portal_url" {
  description = "URL du portail développeur APIM Premium"
  value       = azurerm_api_management.apim_premium.developer_portal_url
}

output "apim_premium_id" {
  description = "ID de l'instance APIM Premium"
  value       = azurerm_api_management.apim_premium.id
}

output "workspace1_name" {
  description = "Nom du premier workspace"
  value       = azurerm_api_management_workspace.workspace1.name
}

output "workspace1_id" {
  description = "ID du premier workspace"
  value       = azurerm_api_management_workspace.workspace1.id
}

output "workspace2_name" {
  description = "Nom du deuxième workspace"
  value       = azurerm_api_management_workspace.workspace2.name
}

output "workspace2_id" {
  description = "ID du deuxième workspace"
  value       = azurerm_api_management_workspace.workspace2.id
}

output "api_center_name" {
  description = "Nom de l'instance API Center"
  value       = azurerm_api_center.api_center.name
}

output "api_center_id" {
  description = "ID de l'instance API Center"
  value       = azurerm_api_center.api_center.id
}
