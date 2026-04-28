terraform {
  backend "azurerm" {
    resource_group_name  = "devops-rg-tf"
    storage_account_name = "devopstfstatebillm"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "devops-rg-tf"
  location = "westus"
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "devops-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "devops-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

# Reuse an existing ACR that already contains the image.
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

# Container App (Managed Identity)
resource "azurerm_container_app" "app" {
  name                         = "devops-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "devopsapp"
      image  = var.image_name
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = "System"
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Allow Container App to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity[0].principal_id

  skip_service_principal_aad_check = true
}