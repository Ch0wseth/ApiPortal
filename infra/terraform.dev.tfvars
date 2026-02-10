# Configuration pour l'environnement de développement
resource_group_name          = "rg-api-portal-dev-2026"
location                     = "francecentral"
log_analytics_workspace_name = "law-api-portal-dev-2026"
application_insights_name    = "appi-api-portal-dev-2026"
apim_premium_name            = "apim-premium-prod-2026"
apim_developer_name          = "apim-developer-dev-2026"
api_center_name              = "apic-portal-dev-2026"
publisher_name               = "Organisation Dev"
publisher_email              = "dev@votredomaine.com"

# Workspaces APIM Production
workspace1_name         = "workspace-team-a-prod"
workspace1_display_name = "Team A Production Workspace"
workspace1_description  = "Workspace de production pour l'équipe A"

workspace2_name         = "workspace-team-b-prod"
workspace2_display_name = "Team B Production Workspace"
workspace2_description  = "Workspace de production pour l'équipe B"

workspace3_name         = "workspace-partners-prod"
workspace3_display_name = "Partners Production Workspace"
workspace3_description  = "Workspace de production pour les APIs partenaires"

# Workspaces APIM Development
workspace_dev1_name         = "workspace-team-a-dev"
workspace_dev1_display_name = "Team A Development Workspace"
workspace_dev1_description  = "Workspace de développement pour l'équipe A"

workspace_dev2_name         = "workspace-team-b-dev"
workspace_dev2_display_name = "Team B Development Workspace"
workspace_dev2_description  = "Workspace de développement pour l'équipe B"

tags = {
  Environment = "Development"
  Project     = "API Portal"
  ManagedBy   = "Terraform"
  CostCenter  = "DEV"
}
