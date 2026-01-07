# PostgreSQL Deployment Guide for Spring PetClinic

This guide explains how to use the Azure region and SKU recommendation tool to deploy PostgreSQL for the Spring PetClinic application.

## Overview

The `appmod-get-available-region-sku` tool helps you identify the best Azure regions and SKUs for deploying PostgreSQL Flexible Server based on:
- Available regions in your subscription
- Quota availability
- Service capacity
- Your preferred regions

## Step 1: Get Region and SKU Recommendations

### Using the Command Line Script

```bash
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
./infra/get-postgres-recommendations.sh
```

### Using the Python Script

```bash
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
python infra/get_postgres_recommendations.py
```

### Using GitHub Actions

Trigger the workflow manually from the Actions tab or using:

```bash
gh workflow run postgres-recommendations.yml
```

## Step 2: Understand the Tool Output

The tool returns information about:

1. **Available Regions**: Azure regions where PostgreSQL Flexible Server is available
2. **Supported SKUs**: Available SKU options in each region
3. **Quota Status**: Whether you have available quota in each region

## Step 3: Choose Region and SKU

### Region Selection Criteria

Consider these factors when choosing a region:
- **Latency**: Choose a region close to your users
- **Compliance**: Ensure the region meets regulatory requirements
- **Cost**: Pricing may vary slightly by region
- **High Availability**: Consider region pairs for disaster recovery

### SKU Selection Guide

#### Development/Testing
- **B1ms**: 1 vCore, 2 GiB RAM
  - Best for: Local development, CI/CD testing
  - Cost: ~$12/month
- **B2s**: 2 vCores, 4 GiB RAM
  - Best for: Shared development environments
  - Cost: ~$24/month

#### Production
- **D2ds_v4**: 2 vCores, 8 GiB RAM
  - Best for: Small production workloads
  - Spring PetClinic: Handles up to 100 concurrent users
- **D4ds_v4**: 4 vCores, 16 GiB RAM
  - Best for: Medium production workloads
  - Spring PetClinic: Handles up to 500 concurrent users
- **D8ds_v4**: 8 vCores, 32 GiB RAM
  - Best for: Large production workloads
  - Spring PetClinic: Handles 1000+ concurrent users

#### High-Performance
- **E2ds_v4**: 2 vCores, 16 GiB RAM
  - Best for: Memory-intensive workloads
- **E4ds_v4**: 4 vCores, 32 GiB RAM
  - Best for: High-performance applications

## Step 4: Deploy PostgreSQL

### Using Azure CLI

```bash
# Set variables based on recommendations
RESOURCE_GROUP="petclinic-rg"
LOCATION="eastus"  # Use recommended region
SERVER_NAME="petclinic-postgres"
SKU_NAME="B1ms"    # Use recommended SKU
ADMIN_USER="petclinic"
ADMIN_PASSWORD="YourSecurePassword123!"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy PostgreSQL
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $SERVER_NAME \
  --location $LOCATION \
  --admin-user $ADMIN_USER \
  --admin-password $ADMIN_PASSWORD \
  --sku-name $SKU_NAME \
  --tier Burstable \
  --version 16 \
  --storage-size 32

# Create database
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $SERVER_NAME \
  --database-name petclinic
```

### Using Bicep

```bash
# Set parameters based on recommendations
LOCATION="eastus"     # Use recommended region
SKU_NAME="B1ms"       # Use recommended SKU
SKU_TIER="Burstable"

# Deploy using Bicep template
az deployment group create \
  --resource-group petclinic-rg \
  --template-file infra/postgres.bicep \
  --parameters \
    location=$LOCATION \
    skuName=$SKU_NAME \
    skuTier=$SKU_TIER \
    administratorPassword="YourSecurePassword123!"
```

## Step 5: Configure Spring PetClinic

Update your application configuration to use the deployed PostgreSQL server:

```yaml
# application-postgres.properties or application.yml
spring:
  profiles:
    active: postgres
  datasource:
    url: jdbc:postgresql://<server-name>.postgres.database.azure.com:5432/petclinic
    username: petclinic
    password: ${POSTGRES_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: none
```

## Example: Complete Deployment

```bash
# 1. Get recommendations (manual review of output)
export AZURE_SUBSCRIPTION_ID="a4ab3025-1b32-4394-92e0-d07c1ebf3787"
python infra/get_postgres_recommendations.py

# 2. Based on recommendations, deploy to East US with B1ms SKU
az group create --name petclinic-rg --location eastus

az deployment group create \
  --resource-group petclinic-rg \
  --template-file infra/postgres.bicep \
  --parameters \
    location=eastus \
    skuName=B1ms \
    skuTier=Burstable \
    administratorPassword="${POSTGRES_PASSWORD}"

# 3. Get connection details
az postgres flexible-server show \
  --resource-group petclinic-rg \
  --name $(az postgres flexible-server list -g petclinic-rg --query "[0].name" -o tsv) \
  --query "fullyQualifiedDomainName" -o tsv

# 4. Run Spring PetClinic with PostgreSQL
./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
```

## Troubleshooting

### Issue: Subscription ID not valid
**Solution**: Verify you're using the correct subscription ID and that you have access:
```bash
az account show
az account list --output table
```

### Issue: Region not available
**Solution**: Run the recommendation tool to see available regions in your subscription.

### Issue: Quota exceeded
**Solution**: Request quota increase or choose a different region recommended by the tool.

## Additional Resources

- [Azure PostgreSQL Flexible Server Documentation](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [PostgreSQL SKU Pricing](https://azure.microsoft.com/pricing/details/postgresql/flexible-server/)
- [Spring Boot PostgreSQL Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/data.html#data.sql.datasource)
