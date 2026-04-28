# Azure Service Principal Setup for GitHub Actions

This guide explains how to configure Azure authentication for GitHub Actions using a service principal.

## Table of Contents
- [Method 1: OIDC Authentication (Recommended)](#method-1-oidc-authentication-recommended)
- [Method 2: Client ID and Client Secret](#method-2-client-id-and-client-secret)
- [Method 3: JSON Credentials (Legacy)](#method-3-json-credentials-legacy)
- [Using the Workflow](#using-the-workflow)

---

## Method 1: OIDC Authentication (Recommended)

OIDC (OpenID Connect) is the modern, more secure approach as it uses short-lived tokens instead of storing long-lived secrets.

### Prerequisites
- Azure CLI installed
- Contributor access to your Azure subscription
- Admin access to your GitHub repository

### Step 1: Create a Service Principal

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create the service principal
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

**Save the output!** You'll need the `appId` (client ID), `tenant`, and `subscriptionId`.

### Step 2: Configure OIDC Federation

```bash
# Get your GitHub repository details
# Format: organization/repository (e.g., "IntelliTect/EWU-CSCD396-2026-Spring")

# Create federated credential for main branch
az ad app federated-credential create \
  --id <APP_ID_FROM_STEP_1> \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Optional: Create federated credential for pull requests
az ad app federated-credential create \
  --id <APP_ID_FROM_STEP_1> \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 3: Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these three secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | The `appId` from Step 1 |
| `AZURE_TENANT_ID` | The `tenant` from Step 1 |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

### Step 4: Update Workflow Permissions

The workflow file already includes the required permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

---

## Method 2: Client ID and Client Secret

This method uses a client ID and client secret as separate parameters. The secret is long-lived but easier to rotate than the JSON credentials method.

### Step 1: Create Service Principal with Secret

```bash
# Login to Azure
az login

# Create service principal with secret
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

**Save the output!** You'll need:
- `appId` (client ID)
- `password` (client secret)
- `tenant` (tenant ID)

### Step 2: Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**

Add these four secrets:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | The `appId` from Step 1 |
| `AZURE_CLIENT_SECRET` | The `password` from Step 1 |
| `AZURE_TENANT_ID` | The `tenant` from Step 1 |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

### Step 3: Use in Workflow

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## Method 3: JSON Credentials (Legacy)

This is the older method that uses a single JSON secret containing all credentials.

### Step 1: Create Service Principal with SDK Auth

```bash
# Login to Azure
az login

# Create service principal with JSON output
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

### Step 2: Configure GitHub Secret

The command above outputs JSON. Copy the **entire JSON output**.

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**

Create one secret:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | The complete JSON output from Step 1 |

### Step 3: Use in Workflow

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

---

## Comparison of Authentication Methods

| Feature | OIDC | Client ID + Secret | JSON Credentials |
|---------|------|-------------------|------------------|
| **Security** | ⭐⭐⭐⭐⭐ Best | ⭐⭐⭐ Good | ⭐⭐ Fair |
| **Token Lifetime** | Short-lived (hours) | Long-lived (years) | Long-lived (years) |
| **Setup Complexity** | Medium | Easy | Easy |
| **Secret Rotation** | Not needed | Manual | Manual |
| **Recommended For** | Production | Development/Testing | Legacy systems |
| **GitHub Requirements** | id-token: write permission | None | None |

**Recommendation:** Use **OIDC** (Method 1) for production workloads. Use **Client ID + Secret** (Method 2) for simpler setups or when OIDC is not feasible.

---

## Using the Workflow

### Manual Trigger

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Azure Login - Service Principal** workflow
4. Click **Run workflow** dropdown
5. Select branch and click **Run workflow**

### Automatic Trigger

The workflow automatically runs when:
- Code is pushed to the `main` branch
- The workflow file itself is modified

### Viewing Results

After the workflow runs:
1. Click on the workflow run
2. Select a job (e.g., `login-with-oidc`)
3. Expand steps to see output

---

## Troubleshooting

### Error: "AADSTS70021: No matching federated identity record found"

**Solution:** Double-check your federated credential configuration:
- Verify the `subject` matches your repository format exactly
- Ensure you're running the workflow from the correct branch
- Wait a few minutes for Azure AD to propagate changes

```bash
# List existing federated credentials
az ad app federated-credential list --id <APP_ID>
```

### Error: "Insufficient privileges to complete the operation"

**Solution:** The service principal needs appropriate permissions:

```bash
# Grant Contributor role at subscription level
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/YOUR_SUBSCRIPTION_ID

# Or for specific resource group
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RG_NAME
```

### Error: "Client secret has expired"

**Solution:** If using client secret methods (Method 2 or 3), rotate the secret:

```bash
# Create new credential (returns new password)
az ad sp credential reset --id <APP_ID>

# Update GitHub secrets:
# - For Method 2: Update AZURE_CLIENT_SECRET with the new password
# - For Method 3: Update AZURE_CREDENTIALS with new JSON (use --sdk-auth flag)
```

### Rotating Client Secrets Proactively

```bash
# List existing credentials and their expiration dates
az ad sp credential list --id <APP_ID>

# Create a new secret with custom expiration (default is 1 year)
az ad sp credential reset --id <APP_ID> --years 2

# Or specify exact end date
az ad sp credential reset --id <APP_ID> --end-date "2027-12-31"
```

---

## Security Best Practices

1. **Use OIDC when possible** - No long-lived secrets to manage, most secure option
2. **Prefer Client ID + Secret over JSON Credentials** - Easier to rotate individual secrets
3. **Principle of least privilege** - Grant only necessary permissions to service principals
4. **Use GitHub Environments** - Add protection rules and approvals for production deployments
5. **Rotate secrets regularly** - Set calendar reminders if using Methods 2 or 3
6. **Monitor service principal usage** - Check Azure Activity Logs for unexpected activity
7. **Use separate service principals** - Create different ones per environment (dev, staging, prod)
8. **Set secret expiration** - Use shorter expiration periods (e.g., 90 days) for high-security environments
9. **Never commit secrets** - Always use GitHub Secrets, never hardcode in workflow files
10. **Audit permissions regularly** - Review and remove unnecessary role assignments

---

## Additional Resources

- [Azure Login Action Documentation](https://github.com/Azure/login)
- [Configure OpenID Connect in Azure](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Azure Service Principals](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)

---

## Quick Reference Commands

```bash
# List service principals
az ad sp list --display-name "github-actions-sp"

# Show service principal details
az ad sp show --id <APP_ID>

# List role assignments
az role assignment list --assignee <APP_ID> --all

# List credentials and expiration dates
az ad sp credential list --id <APP_ID>

# Reset/rotate client secret
az ad sp credential reset --id <APP_ID>

# Delete service principal
az ad sp delete --id <APP_ID>

# Test Azure CLI login with OIDC (not directly possible - OIDC is GitHub-specific)

# Test Azure CLI login with client secret
az login --service-principal \
  --username <APP_ID> \
  --password <CLIENT_SECRET> \
  --tenant <TENANT_ID>

# Verify current login
az account show

# List all subscriptions
az account list --output table
```
