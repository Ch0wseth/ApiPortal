# Configuration pour l'environnement de développement
resource_group_name   = "rg-api-portal-dev"
location              = "francecentral"
apim_premium_name     = "apim-premium-dev"
api_center_name       = "apic-portal-dev"
publisher_name        = "Organisation Dev"
publisher_email       = "dev@votredomaine.com"

# Workspaces
workspace1_name         = "workspace-dev-team-a"
workspace1_display_name = "Dev Team A"
workspace1_description  = "Workspace de développement pour l'équipe A"

workspace2_name         = "workspace-dev-team-b"
workspace2_display_name = "Dev Team B"
workspace2_description  = "Workspace de développement pour l'équipe B"

tags = {
  Environment = "Development"
  Project     = "API Portal"
  ManagedBy   = "Terraform"
  CostCenter  = "DEV"
}
