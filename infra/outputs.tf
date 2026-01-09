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
  value       = var.workspace1_name
}

output "workspace2_name" {
  description = "Nom du deuxième workspace"
  value       = var.workspace2_name
}

output "api_center_id" {
  description = "ID de l'instance API Center"
  value       = azurerm_resource_group_template_deployment.api_center.output_content
}

output "api_center_name" {
  description = "Nom de l'instance API Center"
  value       = var.api_center_name
}
