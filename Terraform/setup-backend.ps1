# Script to create Azure Storage Account for Terraform state

# Variables
$RESOURCE_GROUP = "rg-vmtest1"
$STORAGE_ACCOUNT = "ewu2026test"
$CONTAINER_NAME = "tfstate"
$LOCATION = "eastus"



# Get storage account key
$ACCOUNT_KEY = (az storage account keys list `
  --resource-group $RESOURCE_GROUP `
  --account-name $STORAGE_ACCOUNT `
  --query '[0].value' -o tsv)

# Create blob container
Write-Host "Creating blob container..." -ForegroundColor Green
az storage container create `
  --name $CONTAINER_NAME `
  --account-name $STORAGE_ACCOUNT `
  --account-key $ACCOUNT_KEY

Write-Host "`nBackend storage created successfully!" -ForegroundColor Green
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Storage Account: $STORAGE_ACCOUNT"
Write-Host "Container: $CONTAINER_NAME"
