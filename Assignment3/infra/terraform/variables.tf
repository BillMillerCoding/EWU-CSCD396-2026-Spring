variable "resource_group_name" {
  description = "Name of the Azure resource group for Assignment 3 resources."
  type        = string
  default     = "a3-rg"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westus"
}

variable "naming_suffix" {
  description = "Short personal suffix appended to globally unique resource names (storage accounts, ACR, Service Bus, Function App). Must be lowercase alphanumeric."
  type        = string
  default     = "billm"
}

variable "container_image" {
  description = <<-EOT
    Docker image to deploy to the web app Container App.
    Defaults to a public Microsoft placeholder used on initial Terraform apply
    (before any application CI/CD has run). The app deployment workflow
    (Assignment3-app.yml) overwrites this via 'az containerapp update'.
  EOT
  type    = string
  default = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "func_container_image" {
  description = <<-EOT
    Docker image for the Function Container App.
    Defaults to the public Azure Functions base image used on initial Terraform apply
    (before the function CI/CD has run). The app deployment workflow
    (Assignment3-app.yml) overwrites this via 'az containerapp update'.
  EOT
  type    = string
  default = "mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0"
}
