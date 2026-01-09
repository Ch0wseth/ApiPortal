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

variable "apim_premium_name" {
  description = "Nom de l'instance API Management Premium"
  type        = string
  default     = "apim-premium-portal"
}

variable "workspace1_name" {
  description = "Nom du premier workspace APIM"
  type        = string
  default     = "workspace-team-a"
}

variable "workspace1_display_name" {
  description = "Nom d'affichage du premier workspace"
  type        = string
  default     = "Team A Workspace"
}

variable "workspace1_description" {
  description = "Description du premier workspace"
  type        = string
  default     = "Workspace dédié à l'équipe A"
}

variable "workspace2_name" {
  description = "Nom du deuxième workspace APIM"
  type        = string
  default     = "workspace-team-b"
}

variable "workspace2_display_name" {
  description = "Nom d'affichage du deuxième workspace"
  type        = string
  default     = "Team B Workspace"
}

variable "workspace2_description" {
  description = "Description du deuxième workspace"
  type        = string
  default     = "Workspace dédié à l'équipe B"
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
