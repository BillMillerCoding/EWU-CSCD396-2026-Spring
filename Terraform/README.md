# Terraform Azure Infrastructure Deployment

This Terraform configuration deploys a complete Azure infrastructure including:
- Container App with autoscaling
- Function App (Linux, Node.js)
- Logic App (Standard)
- Application Insights for monitoring
- Required networking and storage resources

The deployment is automated via GitHub Actions using OIDC authentication with a service principal.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Resource Group                                       │  │
│  │                                                       │  │
│  │  ├─ Container App (with autoscaling)                 │  │
│  │  ├─ Function App (Node.js on Linux)                  │  │
│  │  ├─ Logic App (Standard)                             │  │
│  │  ├─ Storage Accounts (for Function + Logic Apps)     │  │
│  │  ├─ App Service Plans                                │  │
│  │  ├─ Application Insights                             │  │
│  │  └─ Log Analytics Workspace                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Terraform State Storage                             │  │
│  │  (Separate Resource Group)                           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Local Development
- [Terraform](https://www.terraform.io/downloads) v1.5.0+
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with Contributor access

### GitHub Actions (Recommended)
- Service Principal with OIDC configured
- GitHub repository with appropriate secrets/variables configured

## Quick Start - Local Deployment

### 1. Set up Terraform State Backend

First, create the Azure Storage Account to store Terraform state:

**Using Bash:**
```bash
cd Terraform
chmod +x setup-backend.sh
./setup-backend.sh
```

**Using PowerShell:**
```powershell
cd Terraform
.\setup-backend.ps1
```

### 2. Configure Backend

Update `backend.conf` with your storage account details (if different from defaults):

```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedemo"
container_name       = "tfstate"
key                  = "prod.terraform.tfstate"
```

### 3. Authenticate to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 4. Initialize Terraform

```bash
cd Terraform
terraform init -backend-config=backend.conf
```

### 5. Plan and Apply

```bash
# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply
```

### 6. Get Deployment Outputs

```bash
terraform output
```

## GitHub Actions Deployment (Recommended)

### Prerequisites

#### 1. Create Service Principal with OIDC

```bash
# Set variables
SUBSCRIPTION_ID="<your-subscription-id>"
APP_NAME="github-actions-terraform"

# Create service principal
az ad sp create-for-rbac \
  --name $APP_NAME \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID

# Save the output - you'll need appId, tenant
```

#### 2. Configure OIDC Federated Credential

```bash
# Get your GitHub repository details
# Format: organization/repository (e.g., "IntelliTect/EWU-CSCD396-2026-Spring")

APP_ID="<appId-from-previous-step>"

# Create federated credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Optional: Create for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### 3. Set up Terraform State Storage

Run the setup script to create the backend storage:

```bash
./Terraform/setup-backend.sh
```

#### 4. Configure GitHub Repository Variables

Go to your repository → Settings → Secrets and variables → Actions

**Variables (non-sensitive):**
| Variable Name | Description | Example |
|--------------|-------------|---------|
| `CLIENT_ID` | Service Principal App ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `TENANT_ID` | Azure AD Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `TF_STATE_RESOURCE_GROUP` | Terraform state RG | `rg-terraform-state` |
| `TF_STATE_STORAGE_ACCOUNT` | Terraform state storage | `sttfstatedemo` |
| `TF_STATE_CONTAINER` | Terraform state container | `tfstate` |
| `TF_STATE_KEY` | Terraform state file name | `prod.terraform.tfstate` |
| `AZURE_RESOURCE_GROUP` | Application resource group | `rg-containerapp-demo` |
| `AZURE_LOCATION` | Azure region | `eastus` |
| `FUNCTION_APP_NAME` | Function App name | `func-demo-app-123` |
| `LOGIC_APP_NAME` | Logic App name | `logic-demo-app-123` |
| `STORAGE_ACCOUNT_NAME` | Storage account name | `stfuncdemo123` |

**Note:** Storage account names must be globally unique and 3-24 characters (lowercase letters and numbers only).

### Workflow Usage

The GitHub Actions workflow automatically:

#### On Pull Request:
- Runs `terraform plan`
- Validates configuration
- Posts plan output as comment (configurable)

#### On Push to Main:
- Runs `terraform plan`
- Runs `terraform apply` (requires environment approval)
- Displays deployment URLs in workflow summary

#### Manual Destroy:
- Trigger workflow manually
- Select "terraform-destroy" job
- Requires "destroy" environment approval

### Running the Workflow

1. **Push to feature branch** → Creates PR → Runs plan
2. **Merge to main** → Automatically deploys (with production approval)
3. **Manual trigger** → Go to Actions → Run workflow → (optional) destroy

## Customization

### Change Resource Names

Edit variables in `main.tf` or pass via command line:

```bash
terraform apply \
  -var="resource_group_name=my-custom-rg" \
  -var="location=westus2" \
  -var="function_app_name=my-func-app"
```

### Modify Container Image

Update the `container_image` variable to use your own image:

```hcl
container_image = "myregistry.azurecr.io/myapp:latest"
```

### Adjust Scaling

Edit the `azurerm_container_app` resource in `main.tf`:

```hcl
template {
  min_replicas = 2
  max_replicas = 10
  
  container {
    cpu    = 0.5
    memory = "1.0Gi"
  }
}
```

### Add Environment Variables

For Function App:

```hcl
resource "azurerm_linux_function_app" "main" {
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "MY_CUSTOM_SETTING"        = "my-value"
  }
}
```

## Outputs

After deployment, the following outputs are available:

```bash
# View all outputs
terraform output

# Get specific output
terraform output container_app_url
terraform output function_app_url
terraform output logic_app_url
```

## Managing State

### View State

```bash
terraform state list
terraform state show azurerm_container_app.main
```

### Import Existing Resources

```bash
terraform import azurerm_resource_group.main /subscriptions/{sub-id}/resourceGroups/{rg-name}
```

### Lock State (for team work)

State locking is automatic when using Azure Storage backend.

## Troubleshooting

### Backend Initialization Fails

```bash
# Re-initialize with reconfigure
terraform init -reconfigure -backend-config=backend.conf
```

### Authentication Issues in GitHub Actions

- Verify OIDC federated credential is correctly configured
- Check that `subject` claim matches your repository format
- Ensure service principal has Contributor role on subscription

### Resource Name Conflicts

Storage account names must be globally unique. If you get conflicts:

```bash
terraform apply -var="storage_account_name=stfuncdemo$(date +%s)"
```

### View Detailed Logs

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply
```

### State File Issues

```bash
# Download current state
terraform state pull > terraform.tfstate.backup

# Force unlock (use carefully!)
terraform force-unlock <lock-id>
```

## Clean Up

### Using Terraform

```bash
terraform destroy
```

### Using GitHub Actions

1. Go to Actions tab
2. Select "Terraform Deploy to Azure"
3. Click "Run workflow"
4. The destroy job will run (requires approval)

### Manual Cleanup

If Terraform destroy fails:

```bash
# Delete resource group
az group delete --name rg-containerapp-demo --yes

# Delete terraform state storage (if no longer needed)
az group delete --name rg-terraform-state --yes
```

## Security Best Practices

1. **Use OIDC instead of client secrets** ✅
2. **Store state in Azure Storage** ✅
3. **Enable state locking** ✅ (automatic with Azure backend)
4. **Use environment protection rules** ✅
5. **Review plans before applying** ✅
6. **Use separate service principals per environment**
7. **Rotate credentials regularly**
8. **Limit service principal permissions to specific resource groups**

## Cost Optimization

- Function App uses Consumption (Y1) plan - pay per execution
- Container Apps scale to zero when not in use
- Logic App uses Workflow Standard (WS1) - review pricing
- Delete resources when not needed: `terraform destroy`

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Functions Documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
- [Azure Logic Apps Documentation](https://learn.microsoft.com/en-us/azure/logic-apps/)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
