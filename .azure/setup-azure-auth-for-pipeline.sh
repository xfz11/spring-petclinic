#!/bin/bash
set -euo pipefail

# =============================================================================
# Setup Azure Authentication for GitHub Actions Pipeline
# This script creates a User-Assigned Managed Identity with federated credentials
# for OIDC authentication from GitHub Actions to Azure.
# =============================================================================

echo "=== Azure Authentication Setup for CI/CD Pipeline ==="
echo ""

# Prompt for required inputs
read -p "Enter your GitHub org/username: " GITHUB_ORG
read -p "Enter your GitHub repository name: " GITHUB_REPO
read -p "Enter Azure location (default: eastus2): " AZURE_LOCATION
AZURE_LOCATION=${AZURE_LOCATION:-eastus2}

CICD_RG="rg-petclinic-cicd"
IDENTITY_NAME="id-petclinic-pipeline"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "Configuration:"
echo "  GitHub Repo:   ${GITHUB_ORG}/${GITHUB_REPO}"
echo "  Location:      ${AZURE_LOCATION}"
echo "  Subscription:  ${SUBSCRIPTION_ID}"
echo "  Tenant:        ${TENANT_ID}"
echo ""

# Step 1: Create resource group for CI/CD identity
echo "Step 1: Creating resource group for CI/CD identity..."
az group create --name "$CICD_RG" --location "$AZURE_LOCATION" --output none
echo "  ✅ Resource group '$CICD_RG' created"

# Step 2: Create User-Assigned Managed Identity
echo "Step 2: Creating User-Assigned Managed Identity..."
az identity create \
  --name "$IDENTITY_NAME" \
  --resource-group "$CICD_RG" \
  --location "$AZURE_LOCATION" \
  --output none

IDENTITY_CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$CICD_RG" --query clientId -o tsv)
IDENTITY_PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$CICD_RG" --query principalId -o tsv)
echo "  ✅ Managed Identity created (Client ID: ${IDENTITY_CLIENT_ID})"

# Step 3: Create Federated Credentials for each environment
echo "Step 3: Creating Federated Credentials..."

ENVIRONMENTS=("dev" "staging" "production")
for ENV in "${ENVIRONMENTS[@]}"; do
  echo "  Creating federated credential for '${ENV}' environment..."
  az identity federated-credential create \
    --name "fc-petclinic-${ENV}" \
    --identity-name "$IDENTITY_NAME" \
    --resource-group "$CICD_RG" \
    --issuer "https://token.actions.githubusercontent.com" \
    --subject "repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${ENV}" \
    --audiences "api://AzureADTokenExchange" \
    --output none
  echo "  ✅ Federated credential for '${ENV}' created"
done

# Step 4: Print summary
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Create GitHub environments (dev, staging, production) in your repository settings"
echo "2. Set the following variables in EACH GitHub environment:"
echo ""
echo "   AZURE_CLIENT_ID:       ${IDENTITY_CLIENT_ID}"
echo "   AZURE_TENANT_ID:       ${TENANT_ID}"
echo "   AZURE_SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}"
echo ""
echo "3. Run the 'Infra - Deploy Azure Resources' workflow for each environment"
echo "4. After infra deployment, set these additional variables per environment:"
echo "   - AZURE_RESOURCE_GROUP (from infra deployment)"
echo "   - ACR_NAME (from infra deployment output)"
echo "   - CONTAINER_APP_NAME (from infra deployment output)"
echo ""
echo "5. Assign Contributor role to the managed identity for each resource group:"
echo "   az role assignment create --assignee ${IDENTITY_PRINCIPAL_ID} --role Contributor --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/<RESOURCE_GROUP>"
echo ""
echo "6. After ACR is created, assign AcrPush role:"
echo "   az role assignment create --assignee ${IDENTITY_PRINCIPAL_ID} --role AcrPush --scope <ACR_RESOURCE_ID>"
echo ""
