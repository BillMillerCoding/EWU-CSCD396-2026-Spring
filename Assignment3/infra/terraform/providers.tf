terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Partial backend configuration — only the state key is declared here.
  # The remaining backend settings (resource_group_name, storage_account_name,
  # container_name) are supplied via -backend-config flags in CI, or via a
  # local backend.conf file (see backend.conf.example).
  backend "azurerm" {
    key = "assignment3.tfstate"
  }
}

provider "azurerm" {
  features {}

  # Authentication is handled through ARM_* environment variables in CI:
  #   ARM_USE_OIDC=true
  #   ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  # For local development, 'az login' is sufficient.
}
