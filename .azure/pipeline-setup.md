# Pipeline Setup Guide for Spring Petclinic Azure Deployment

## Prerequisites

- Azure CLI installed (`az --version`)
- GitHub CLI installed (`gh --version`)
- An Azure subscription with permissions to create resources
- Owner or admin access to the GitHub repository

## 1. Azure Authentication Configuration

The CI/CD pipeline uses **User-Assigned Managed Identity with OIDC** (OpenID Connect) for secure, passwordless authentication to Azure.

### Step 1: Create a Managed Identity for CI/CD

Run the setup script to automate the creation:

```bash
chmod +x .azure/setup-azure-auth-for-pipeline.sh
./.azure/setup-azure-auth-for-pipeline.sh
```

Or follow the manual steps below.

### Manual Steps

#### a. Create a Resource Group for CI/CD identity

```bash
az group create --name rg-petclinic-cicd --location eastus2
```

#### b. Create User-Assigned Managed Identity

```bash
az identity create \
  --name id-petclinic-pipeline \
  --resource-group rg-petclinic-cicd \
  --location eastus2
```

#### c. Get the identity details

```bash
IDENTITY_CLIENT_ID=$(az identity show --name id-petclinic-pipeline --resource-group rg-petclinic-cicd --query clientId -o tsv)
IDENTITY_PRINCIPAL_ID=$(az identity show --name id-petclinic-pipeline --resource-group rg-petclinic-cicd --query principalId -o tsv)
IDENTITY_RESOURCE_ID=$(az identity show --name id-petclinic-pipeline --resource-group rg-petclinic-cicd --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

#### d. Create Federated Credentials for each environment

```bash
# For dev environment
az identity federated-credential create \
  --name fc-petclinic-dev \
  --identity-name id-petclinic-pipeline \
  --resource-group rg-petclinic-cicd \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<GITHUB_ORG>/<GITHUB_REPO>:environment:dev \
  --audiences api://AzureADTokenExchange

# For staging environment
az identity federated-credential create \
  --name fc-petclinic-staging \
  --identity-name id-petclinic-pipeline \
  --resource-group rg-petclinic-cicd \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<GITHUB_ORG>/<GITHUB_REPO>:environment:staging \
  --audiences api://AzureADTokenExchange

# For production environment
az identity federated-credential create \
  --name fc-petclinic-prod \
  --identity-name id-petclinic-pipeline \
  --resource-group rg-petclinic-cicd \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:<GITHUB_ORG>/<GITHUB_REPO>:environment:production \
  --audiences api://AzureADTokenExchange
```

#### e. Assign RBAC Roles

Assign **Contributor** role to each application resource group and **AcrPush** role to the container registry:

```bash
# Contributor to dev resource group
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<DEV_RESOURCE_GROUP>

# Contributor to staging resource group
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<STAGING_RESOURCE_GROUP>

# Contributor to production resource group
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<PRODUCTION_RESOURCE_GROUP>

# AcrPush to the container registry (after infra is deployed)
az role assignment create \
  --assignee $IDENTITY_PRINCIPAL_ID \
  --role AcrPush \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

## 2. GitHub Environment Setup

### Create GitHub Environments

Create the three deployment environments with required approval checks:

1. Go to your repository → **Settings** → **Environments**
2. Create three environments: `dev`, `staging`, `production`
3. For `staging` and `production`, add **required reviewers** as approval checks

### Configure Environment Variables

For **each environment** (`dev`, `staging`, `production`), set the following GitHub Actions variables:

| Variable Name | Description | Example |
|---|---|---|
| `AZURE_CLIENT_ID` | Managed Identity Client ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_RESOURCE_GROUP` | Resource Group name | `rg-petclinic-dev` |
| `ACR_NAME` | Container Registry name | `azacrxxxxxxxx` |
| `CONTAINER_APP_NAME` | Container App name | `azcaxxxxxxxx` |

> **Note:** `ACR_NAME` and `CONTAINER_APP_NAME` values are outputs from the infrastructure deployment. Run the `infra-deploy.yml` workflow first, then set these values.

## 3. Deployment Workflow

### First-time Setup

1. **Deploy Infrastructure**: Run the `Infra - Deploy Azure Resources` workflow for each environment (dev → staging → production)
2. **Get Outputs**: Note the ACR name and Container App name from the deployment outputs
3. **Configure Variables**: Set the GitHub environment variables with the infrastructure output values
4. **Assign AcrPush**: Assign the AcrPush role to the pipeline managed identity for each ACR

### Ongoing Deployment

After initial setup, pushes to `main` will automatically:
1. Build the Java application
2. Deploy to `dev` → `staging` → `production` (with approvals)
