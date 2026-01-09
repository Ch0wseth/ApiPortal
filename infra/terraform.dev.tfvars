# Configuration pour l'environnement de développement
resource_group_name = "rg-api-portal-dev"
location            = "francecentral"
apim_premium_name   = "apim-premium-dev"
api_center_name     = "apic-portal-dev"
publisher_name      = "Organisation Dev"
publisher_email     = "dev@votredomaine.com"

# Workspaces APIM
workspace1_name         = "workspace-team-a"
workspace1_display_name = "Team A Workspace"
workspace1_description  = "Workspace pour l'équipe A"

workspace2_name         = "workspace-team-b"
workspace2_display_name = "Team B Workspace"
workspace2_description  = "Workspace pour l'équipe B"

tags = {
  Environment = "Development"
  Project     = "API Portal"
  ManagedBy   = "Terraform"
  CostCenter  = "DEV"
}
