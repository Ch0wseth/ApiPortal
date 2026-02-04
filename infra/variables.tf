variable "resource_group_name" {
  description = "Nom du groupe de ressources Azure"
  type        = string
  default     = "rg-api-portal"
}

variable "location" {
  description = "Région Azure pour le déploiement des ressources"
  type        = string
  default     = "francecentral"
}

variable "log_analytics_workspace_name" {
  description = "Nom du Log Analytics Workspace pour le monitoring"
  type        = string
  default     = "law-api-portal"
}

variable "application_insights_name" {
  description = "Nom de l'instance Application Insights pour le monitoring"
  type        = string
  default     = "appi-api-portal"
}

variable "apim_premium_name" {
  description = "Nom de l'instance API Management Premium (Production)"
  type        = string
  default     = "apim-premium-portal-prod"
}

variable "apim_developer_name" {
  description = "Nom de l'instance API Management Developer (Development)"
  type        = string
  default     = "apim-dev-portal-dev"
}

# Workspaces APIM Production
variable "workspace1_name" {
  description = "Nom du premier workspace APIM Production"
  type        = string
  default     = "workspace-team-a-prod"
}

variable "workspace1_display_name" {
  description = "Nom d'affichage du premier workspace Production"
  type        = string
  default     = "Team A Production Workspace"
}

variable "workspace1_description" {
  description = "Description du premier workspace Production"
  type        = string
  default     = "Workspace de production pour l'équipe A"
}

variable "workspace2_name" {
  description = "Nom du deuxième workspace APIM Production"
  type        = string
  default     = "workspace-team-b-prod"
}

variable "workspace2_display_name" {
  description = "Nom d'affichage du deuxième workspace Production"
  type        = string
  default     = "Team B Production Workspace"
}

variable "workspace2_description" {
  description = "Description du deuxième workspace Production"
  type        = string
  default     = "Workspace de production pour l'équipe B"
}

variable "workspace3_name" {
  description = "Nom du workspace Partners (Production)"
  type        = string
  default     = "workspace-partners-prod"
}

variable "workspace3_display_name" {
  description = "Nom d'affichage du workspace Partners"
  type        = string
  default     = "Partners Production Workspace"
}

variable "workspace3_description" {
  description = "Description du workspace Partners"
  type        = string
  default     = "Workspace de production pour les APIs partenaires"
}

# Workspaces APIM Development
variable "workspace_dev1_name" {
  description = "Nom du premier workspace APIM Development"
  type        = string
  default     = "workspace-team-a-dev"
}

variable "workspace_dev1_display_name" {
  description = "Nom d'affichage du premier workspace Development"
  type        = string
  default     = "Team A Development Workspace"
}

variable "workspace_dev1_description" {
  description = "Description du premier workspace Development"
  type        = string
  default     = "Workspace de développement pour l'équipe A"
}

variable "workspace_dev2_name" {
  description = "Nom du deuxième workspace APIM Development"
  type        = string
  default     = "workspace-team-b-dev"
}

variable "workspace_dev2_display_name" {
  description = "Nom d'affichage du deuxième workspace Development"
  type        = string
  default     = "Team B Development Workspace"
}

variable "workspace_dev2_description" {
  description = "Description du deuxième workspace Development"
  type        = string
  default     = "Workspace de développement pour l'équipe B"
}

variable "api_center_name" {
  description = "Nom de l'instance Azure API Center"
  type        = string
  default     = "apic-portal"
}

variable "publisher_name" {
  description = "Nom de l'organisation pour API Management"
  type        = string
  default     = "Mon Organisation"
}

variable "publisher_email" {
  description = "Email de contact pour API Management"
  type        = string
  default     = "admin@example.com"
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "API Portal"
    ManagedBy   = "Terraform"
  }
}
