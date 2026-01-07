# Azure Deployment Quick Start

This project includes Bicep Infrastructure as Code (IaC) files to deploy Spring PetClinic to Azure.

## Quick Start

1. **Prerequisites**
   - Azure CLI installed and logged in: `az login`
   - Docker installed for building container images

2. **Deploy to Azure**
   ```bash
   # Set your PostgreSQL password
   export POSTGRES_PASSWORD="YourSecurePassword123!"
   
   # Deploy infrastructure
   cd spring-petclinic
   az deployment sub create \
     --name petclinic-deployment \
     --location eastus \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam \
     --parameters postgresAdminPassword="$POSTGRES_PASSWORD"
   ```

3. **Build and push container image**
   ```bash
   # Get ACR name
   ACR_NAME=$(az deployment sub show --name petclinic-deployment --query properties.outputs.containerRegistryName.value -o tsv)
   
   # Login and build
   az acr login --name $ACR_NAME
   az acr build --registry $ACR_NAME --image petclinic:latest .
   ```

4. **Access your application**
   ```bash
   # Get application URL
   APP_URL=$(az deployment sub show --name petclinic-deployment --query properties.outputs.containerAppUrl.value -o tsv)
   echo "Application URL: https://$APP_URL"
   ```

## Architecture

The deployment creates:
- **Azure Container Registry**: For storing Docker images
- **Azure Container Apps**: For hosting the application
- **Azure Database for PostgreSQL**: For data persistence
- **Log Analytics**: For monitoring and logs

## Documentation

For detailed deployment instructions, see [infra/README.md](infra/README.md)

## What's Included

- `Dockerfile`: Multi-stage Docker build for Spring Boot application
- `.dockerignore`: Optimized Docker build context
- `infra/main.bicep`: Main infrastructure template
- `infra/main.bicepparam`: Default parameters
- `infra/modules/`: Modular Bicep files for each Azure resource
- `infra/README.md`: Comprehensive deployment guide

## Cleanup

To remove all Azure resources:
```bash
az group delete --name rg-petclinic-dev --yes --no-wait
```
