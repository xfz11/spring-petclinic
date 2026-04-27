# Azure Pipeline Setup Guide

This document outlines the steps needed to configure Azure authentication and GitHub environments for the CI/CD pipeline.

## Prerequisites

- Azure CLI installed (`az --version`)
- GitHub CLI installed (`gh --version`)
- An Azure subscription
- Owner or Contributor access to the Azure subscription

## Step 1: Create a User-Assigned Managed Identity for CI/CD

> **Important**: This Managed Identity is for the CI/CD pipeline only. It is separate from the application's Managed Identity created by Bicep.

```bash
# Set variables
SUBSCRIPTION_ID="<your-subscription-id>"
LOCATION="eastus"
RG_CICD="rg-cicd-identity"
IDENTITY_NAME="id-petclinic-cicd"

# Create resource group for CI/CD identity
az group create --name $RG_CICD --location $LOCATION

# Create the managed identity
az identity create \
  --name $IDENTITY_NAME \
  --resource-group $RG_CICD \
  --location $LOCATION

# Get identity details
CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG_CICD --query clientId -o tsv)
PRINCIPAL_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG_CICD --query principalId -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "CLIENT_ID: $CLIENT_ID"
echo "PRINCIPAL_ID: $PRINCIPAL_ID"
echo "TENANT_ID: $TENANT_ID"
```

## Step 2: Assign RBAC Roles

```bash
# Contributor role on subscription (for provisioning)
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# AcrPush role on ACR (for pushing images) - assign after ACR is created
# az role assignment create \
#   --assignee-object-id $PRINCIPAL_ID \
#   --assignee-principal-type ServicePrincipal \
#   --role "AcrPush" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>"
```

## Step 3: Create Federated Credentials

Create federated credentials for each environment:

```bash
REPO_OWNER="<your-github-org-or-user>"
REPO_NAME="spring-petclinic"

# For dev environment
az identity federated-credential create \
  --name "fc-github-dev" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RG_CICD \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${REPO_OWNER}/${REPO_NAME}:environment:dev" \
  --audiences "api://AzureADTokenExchange"

# For staging environment
az identity federated-credential create \
  --name "fc-github-staging" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RG_CICD \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${REPO_OWNER}/${REPO_NAME}:environment:staging" \
  --audiences "api://AzureADTokenExchange"

# For production environment
az identity federated-credential create \
  --name "fc-github-production" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RG_CICD \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${REPO_OWNER}/${REPO_NAME}:environment:production" \
  --audiences "api://AzureADTokenExchange"
```

## Step 4: Create GitHub Environments and Variables

Create environments with approval checks and configure required variables:

```bash
REPO="${REPO_OWNER}/${REPO_NAME}"

# Create environments
for ENV in dev staging production; do
  gh api --method PUT "repos/${REPO}/environments/${ENV}"
done

# Set variables for each environment
for ENV in dev staging production; do
  gh variable set AZURE_CLIENT_ID --env $ENV --body "$CLIENT_ID" --repo $REPO
  gh variable set AZURE_TENANT_ID --env $ENV --body "$TENANT_ID" --repo $REPO
  gh variable set AZURE_SUBSCRIPTION_ID --env $ENV --body "$SUBSCRIPTION_ID" --repo $REPO
  gh variable set AZURE_LOCATION --env $ENV --body "$LOCATION" --repo $REPO
  gh variable set RESOURCE_GROUP_NAME --env $ENV --body "rg-${ENV}-petclinic" --repo $REPO
  gh variable set ACR_NAME --env $ENV --body "<acr-name-from-bicep-output>" --repo $REPO
  gh variable set CONTAINER_APP_NAME --env $ENV --body "<container-app-name-from-bicep-output>" --repo $REPO
done
```

> **Note**: After running the Bicep deployment, update `ACR_NAME` and `CONTAINER_APP_NAME` with the actual values from deployment outputs.

## Step 5: Configure Environment Protection Rules

Go to **Settings > Environments** in your GitHub repository and add protection rules:

- **dev**: No required reviewers (auto-deploy)
- **staging**: Add required reviewers
- **production**: Add required reviewers + deployment branch restriction (main only)

## Deployment Workflow

1. **Provision infrastructure**: Run the `infra-deploy.yml` workflow manually for each environment
2. **Update variables**: Set `ACR_NAME` and `CONTAINER_APP_NAME` from deployment outputs
3. **Deploy application**: Push to `main` branch triggers the `deploy.yml` workflow automatically

The pipeline follows this flow:
```
Push to main → Build & Test → Deploy Dev → Deploy Staging → Deploy Production
```

Each environment stage requires approval (except dev) before proceeding.
