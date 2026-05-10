output "resource_group_name" {
  description = "Name of the Assignment 3 resource group."
  value       = azurerm_resource_group.rg.name
}

output "webapp_url" {
  description = "Public HTTPS URL of the Container App web UI."
  value       = "https://${azurerm_container_app.webapp.ingress[0].fqdn}"
}

output "acr_login_server" {
  description = "Login server of the ACR. Used to construct Docker image tags in CI."
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Short name of the ACR resource. Used by 'az acr login' in CI."
  value       = azurerm_container_registry.acr.name
}

output "container_app_name" {
  description = "Name of the Container App. Used by the app deployment workflow."
  value       = azurerm_container_app.webapp.name
}

output "function_app_name" {
  description = "Name of the Function Container App. Used by the app deployment workflow."
  value       = azurerm_container_app.func.name
}

output "servicebus_fqdn" {
  description = "Fully qualified domain name of the Service Bus namespace."
  value       = "${azurerm_servicebus_namespace.servicebus.name}.servicebus.windows.net"
}

output "storage_account_name" {
  description = "Name of the storage account used by the Function App for output table storage."
  value       = azurerm_storage_account.func_storage.name
}
