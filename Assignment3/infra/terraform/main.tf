locals {
  suffix = var.naming_suffix
}

# ── Resource Group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ── Container Registry ────────────────────────────────────────────────────────

resource "azurerm_container_registry" "acr" {
  name                = "a3registry${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # Managed Identity is used for pulls; no admin credentials needed.
}

# ── Observability ─────────────────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "a3-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights" {
  name                = "a3-appinsights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
}

# ── Container App Environment ─────────────────────────────────────────────────

resource "azurerm_container_app_environment" "env" {
  name                       = "a3-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

# ── Service Bus ───────────────────────────────────────────────────────────────

resource "azurerm_servicebus_namespace" "servicebus" {
  name                = "a3-servicebus-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard" # Standard is required for queues with dead-lettering.
}

resource "azurerm_servicebus_queue" "messages" {
  name         = "messages"
  namespace_id = azurerm_servicebus_namespace.servicebus.id

  # Reasonable defaults for an assignment; tune for production.
  max_delivery_count = 5
}

# ── Storage Account ───────────────────────────────────────────────────────────
# Used for:
#   1. Azure Functions WebJobs runtime (blobs, queues, tables for coordination)
#   2. Application output — received Service Bus messages stored as table entities

resource "azurerm_storage_account" "func_storage" {
  name                     = "a3funcst${local.suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Pre-create the output table so it is available as soon as the Function App
# first triggers. The function also calls CreateIfNotExistsAsync() as a
# belt-and-suspenders guard, but Terraform ownership makes the table visible
# immediately after apply.
resource "azurerm_storage_table" "messages" {
  name                 = "messages"
  storage_account_name = azurerm_storage_account.func_storage.name
}

# ── Function App (Container App) ──────────────────────────────────────────────
# Azure for Students subscriptions have zero quota for ALL App Service Plan
# VM tiers (Consumption Y1, Basic B1, Standard S1, etc.). To work around this,
# the function runs inside the same Container Apps environment as the web UI.
# The Azure Functions runtime is bundled into the Docker image; the Service Bus
# trigger is handled by the Functions host inside the container.

resource "azurerm_container_app" "func" {
  name                         = "a3-func-${local.suffix}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "a3func"
      image  = var.func_container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AzureWebJobsStorage__accountName"
        value = azurerm_storage_account.func_storage.name
      }

      env {
        name  = "AzureWebJobsStorage__credential"
        value = "managedidentity"
      }

      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "dotnet-isolated"
      }

      env {
        name  = "ServiceBusConnection__fullyQualifiedNamespace"
        value = "${azurerm_servicebus_namespace.servicebus.name}.servicebus.windows.net"
      }

      env {
        name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.insights.connection_string
      }

      env {
        name  = "OutputStorageAccountName"
        value = azurerm_storage_account.func_storage.name
      }

      env {
        name  = "OutputTableName"
        value = "messages"
      }
    }
  }

  # No ingress — the function is Service Bus-triggered, not HTTP-accessible.
  # No registry block — ACR managed identity pull is configured post-apply
  # via 'az containerapp registry set' in the infra workflow (same pattern as webapp).
}

# ── Container App (Web UI) ────────────────────────────────────────────────────

resource "azurerm_container_app" "webapp" {
  name                         = "a3-webapp"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name = "a3webapp"

      # Placeholder image on initial apply. The app deployment workflow
      # (Assignment3-app.yml) overwrites this with the real ACR image via
      # 'az containerapp update' immediately after infra deployment completes.
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ServiceBus__Namespace"
        value = "${azurerm_servicebus_namespace.servicebus.name}.servicebus.windows.net"
      }

      env {
        name  = "ServiceBus__QueueName"
        value = azurerm_servicebus_queue.messages.name
      }

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }
    }
  }

  # Note: the registry block is intentionally absent here.
  # Configuring managed identity registry access in the same Terraform apply
  # that creates the Container App causes a deadlock: Azure validates ACR access
  # at creation time, but the AcrPull role assignment can't exist until after the
  # Container App (and its principal_id) is created.
  # Instead, the infra workflow runs 'az containerapp registry set' after apply,
  # by which point the AcrPull role assignment already exists in state.

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# ── RBAC Assignments ──────────────────────────────────────────────────────────
# Azure RBAC propagation can take up to 2 minutes after 'terraform apply'.
# If the Function App or Container App starts before their roles have
# propagated, restart the app or wait for the next polling interval.

# Container App → Service Bus (send messages from the web UI)
resource "azurerm_role_assignment" "webapp_sb_sender" {
  scope                            = azurerm_servicebus_namespace.servicebus.id
  role_definition_name             = "Azure Service Bus Data Sender"
  principal_id                     = azurerm_container_app.webapp.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Function Container App → Service Bus (receive messages from the queue)
resource "azurerm_role_assignment" "func_sb_receiver" {
  scope                            = azurerm_servicebus_namespace.servicebus.id
  role_definition_name             = "Azure Service Bus Data Receiver"
  principal_id                     = azurerm_container_app.func.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Function Container App → Storage: blobs (WebJobs runtime lease coordination)
resource "azurerm_role_assignment" "func_storage_blob_owner" {
  scope                            = azurerm_storage_account.func_storage.id
  role_definition_name             = "Storage Blob Data Owner"
  principal_id                     = azurerm_container_app.func.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Function Container App → Storage: queues (WebJobs runtime poison-message handling)
resource "azurerm_role_assignment" "func_storage_queue_contributor" {
  scope                            = azurerm_storage_account.func_storage.id
  role_definition_name             = "Storage Queue Data Contributor"
  principal_id                     = azurerm_container_app.func.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Function Container App → Storage: tables (function writes received messages here)
resource "azurerm_role_assignment" "func_storage_table_contributor" {
  scope                            = azurerm_storage_account.func_storage.id
  role_definition_name             = "Storage Table Data Contributor"
  principal_id                     = azurerm_container_app.func.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Web App Container → ACR (pull the webapp Docker image)
resource "azurerm_role_assignment" "webapp_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_container_app.webapp.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Function Container App → ACR (pull the function Docker image)
resource "azurerm_role_assignment" "func_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_container_app.func.identity[0].principal_id
  skip_service_principal_aad_check = true
}
