# PostgreSQL Region and SKU Recommendations

This directory contains tools and documentation for getting Azure region and SKU recommendations for PostgreSQL deployment for the Spring PetClinic application.

## Overview

The `appmod-get-available-region-sku` tool helps identify optimal Azure regions and SKUs for deploying PostgreSQL Flexible Server. This ensures you deploy to regions with available capacity and appropriate SKUs for your workload.

## Quick Start

### Option 1: Using Python Script

```bash
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
python infra/get_postgres_recommendations.py
```

### Option 2: Using Bash Script

```bash
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
./infra/get-postgres-recommendations.sh
```

### Option 3: Using GitHub Actions

The recommendation tool is integrated into the `copilot-setup-steps.yml` workflow. Run the workflow to see recommendations:

```bash
gh workflow run copilot-setup-steps.yml
```

Or trigger it manually from the Actions tab in GitHub.

## What's Included

- **Scripts**:
  - `get_postgres_recommendations.py` - Python script showing tool usage
  - `get-postgres-recommendations.sh` - Bash script showing tool usage
  
- **Infrastructure**:
  - `postgres.bicep` - Bicep template for PostgreSQL deployment with recommended SKUs
  
- **Workflows**:
  - `.github/workflows/postgres-recommendations.yml` - Dedicated workflow for recommendations
  - `.github/workflows/copilot-setup-steps.yml` - Integrated setup workflow
  
- **Documentation**:
  - `infra/README.md` - Overview of the tool
  - `infra/DEPLOYMENT_GUIDE.md` - Complete deployment guide

## Tool Parameters

The `appmod-get-available-region-sku` tool requires:

```json
{
  "subscriptionId": "your-azure-subscription-id",
  "resourceTypes": [
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers",
      "quota": 1
    }
  ],
  "preferredRegions": [],
  "workspaceFolder": "/path/to/workspace"
}
```

## Recommended SKUs

### For Development
- **B1ms**: 1 vCore, 2 GiB RAM (~$12/month)
- **B2s**: 2 vCores, 4 GiB RAM (~$24/month)

### For Production
- **D2ds_v4**: 2 vCores, 8 GiB RAM (up to 100 concurrent users)
- **D4ds_v4**: 4 vCores, 16 GiB RAM (up to 500 concurrent users)
- **D8ds_v4**: 8 vCores, 32 GiB RAM (1000+ concurrent users)

## Example Deployment

After getting recommendations:

```bash
# Create resource group
az group create --name petclinic-rg --location eastus

# Deploy PostgreSQL using recommended SKU
az deployment group create \
  --resource-group petclinic-rg \
  --template-file infra/postgres.bicep \
  --parameters \
    location=eastus \
    skuName=B1ms \
    skuTier=Burstable \
    administratorPassword="SecurePassword123!"

# Run PetClinic with PostgreSQL
./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
```

## Learn More

For detailed deployment instructions and troubleshooting, see [infra/DEPLOYMENT_GUIDE.md](infra/DEPLOYMENT_GUIDE.md).
